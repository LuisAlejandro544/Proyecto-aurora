--!strict
--[=[
	Controlador del arma G18 en el cliente (LocalScript en StarterPlayerScripts.Client).
	Lógica:
	- Detecta cuando la pistola G18 está equipada.
	- Dispara en modo automático al mantener clic izquierdo o el botón táctil de disparo.
	- Calcula el punto exacto de la mira en el centro de la pantalla (con dispersión real
	  reducida al apuntar o agacharse) y dibuja un trazador rápido + fogonazo.
	- Envía el disparo al servidor y muestra Hitmarker cuando el servidor confirma impacto.
]=]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WeaponStats = require(Shared:WaitForChild("WeaponStats"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FireWeaponEvent = Remotes:WaitForChild("FireWeaponEvent") :: RemoteEvent
local ReloadWeaponEvent = Remotes:WaitForChild("ReloadWeaponEvent") :: RemoteEvent
local HitConfirmEvent = Remotes:WaitForChild("HitConfirmEvent") :: RemoteEvent

local ClientState = require(script.Parent:WaitForChild("ClientState"))

local localPlayer = Players.LocalPlayer
local stats = WeaponStats.G18
local rng = Random.new()

local lastShotTime = 0
local equippedTool: Tool? = nil

local function getAimWorldPoint(character: Model): Vector3
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.zero
	end

	local spreadDeg = if ClientState.IsAiming then stats.AimSpreadDeg else stats.HipSpreadDeg
	if ClientState.MoveState == "Crouch" or ClientState.MoveState == "Slide" then
		spreadDeg *= stats.CrouchSpreadMultiplier
	end

	local spreadRad = math.rad(spreadDeg)
	local rx = rng:NextNumber(-spreadRad, spreadRad)
	local ry = rng:NextNumber(-spreadRad, spreadRad)
	local rayCF = camera.CFrame * CFrame.Angles(rx, ry, 0)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(rayCF.Position, rayCF.LookVector * stats.MaxRange, rayParams)
	if result then
		return result.Position
	end
	return rayCF.Position + rayCF.LookVector * stats.MaxRange
end

local function spawnTracerAndFlash(muzzlePos: Vector3, endPos: Vector3)
	local dist = (endPos - muzzlePos).Magnitude
	if dist < 0.5 then
		return
	end

	local tracer = Instance.new("Part")
	tracer.Name = "BulletTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 224, 130)
	tracer.Transparency = 0.25
	tracer.Size = Vector3.new(0.08, 0.08, dist)
	tracer.CFrame = CFrame.lookAt(muzzlePos, endPos) * CFrame.new(0, 0, -dist / 2)
	tracer.Parent = workspace
	Debris:AddItem(tracer, 0.055)

	local flashPart = Instance.new("Part")
	flashPart.Name = "MuzzleFlash"
	flashPart.Anchored = true
	flashPart.CanCollide = false
	flashPart.CanQuery = false
	flashPart.Transparency = 1
	flashPart.Size = Vector3.new(0.2, 0.2, 0.2)
	flashPart.CFrame = CFrame.new(muzzlePos)
	flashPart.Parent = workspace

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 195, 90)
	light.Brightness = 3.5
	light.Range = 12
	light.Parent = flashPart

	Debris:AddItem(flashPart, stats.MuzzleFlashDuration)
end

local function triggerReload()
	if not equippedTool or ClientState.IsReloading or ClientState.Ammo >= stats.MagazineSize then
		return
	end
	ClientState.IsReloading = true
	ReloadWeaponEvent:FireServer()
	task.delay(stats.ReloadTime, function()
		if ClientState.IsReloading then
			ClientState.Ammo = stats.MagazineSize
			ClientState.IsReloading = false
		end
	end)
end

ClientState.OnReload = triggerReload

local function tryFire()
	local character = localPlayer.Character
	local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not character or not hum or hum.Health <= 0 then
		return
	end
	if not equippedTool or ClientState.IsReloading then
		return
	end
	if ClientState.MoveState == "Dive" then
		return
	end
	if ClientState.Ammo <= 0 then
		triggerReload()
		return
	end

	local now = os.clock()
	if (now - lastShotTime) < stats.FireRate then
		return
	end
	lastShotTime = now
	ClientState.Ammo -= 1

	local targetPoint = getAimWorldPoint(character)
	FireWeaponEvent:FireServer(targetPoint)

	-- Fogonazo y trazador desde el cañón de la G18
	local muzzle = equippedTool:FindFirstChild("Muzzle")
	local handle = equippedTool:FindFirstChild("Handle")
	local startPos = if muzzle and muzzle:IsA("BasePart")
		then muzzle.Position
		elseif handle and handle:IsA("BasePart") then handle.Position
		else character:GetPivot().Position + Vector3.new(0, 1.5, 0)

	spawnTracerAndFlash(startPos, targetPoint)

	-- Retroceso controlado de cámara
	local yawKick = rng:NextNumber(-stats.RecoilYawDeg, stats.RecoilYawDeg)
	ClientState.AddCameraRecoil(stats.RecoilPitchDeg, yawKick)

	if ClientState.Ammo == 0 then
		triggerReload()
	end
end

-- Controles de ratón / teclado en PC
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		ClientState.IsFiring = true
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		ClientState.IsAiming = true
	elseif input.KeyCode == Enum.KeyCode.R then
		triggerReload()
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		ClientState.IsFiring = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		ClientState.IsAiming = false
	end
end)

HitConfirmEvent.OnClientEvent:Connect(function(info: { IsHeadshot: boolean? })
	if ClientState.OnHitConfirm then
		ClientState.OnHitConfirm(info.IsHeadshot == true)
	end
end)

RunService.RenderStepped:Connect(function()
	if ClientState.IsFiring and ClientState.IsWeaponEquipped then
		tryFire()
	end
end)

local function bindCharacterTools(character: Model)
	equippedTool = nil
	ClientState.IsWeaponEquipped = false
	ClientState.IsReloading = false
	ClientState.Ammo = stats.MagazineSize

	local function refreshTool()
		local tool = character:FindFirstChildOfClass("Tool")
		if tool and tool.Name == Config.DefaultWeaponName then
			equippedTool = tool
			ClientState.IsWeaponEquipped = true
		else
			equippedTool = nil
			ClientState.IsWeaponEquipped = false
			ClientState.IsFiring = false
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			refreshTool()
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			refreshTool()
		end
	end)
	refreshTool()
end

localPlayer.CharacterAdded:Connect(bindCharacterTools)
if localPlayer.Character then
	bindCharacterTools(localPlayer.Character)
end
