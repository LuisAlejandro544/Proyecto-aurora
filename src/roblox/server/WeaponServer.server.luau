--!strict
--[=[
	Servidor autoritativo del arma G18 (Script en ServerScriptService.Server).
	Lógica:
	- Controla munición por jugador (33 balas por cargador) y recarga segura con token.
	- Valida la cadencia y ejecuta el Raycast real en servidor respetando coberturas.
	- Calcula daño diferenciado según parte impactada (cabeza, pecho, brazos, manos,
	  piernas y pies) mediante WeaponStats.ResolveHitDamage.
	- Guarda LastHitDirection para la caída realista (Ragdoll) y replica trazadores.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local WeaponStats = require(Shared:WaitForChild("WeaponStats"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local FireWeaponEvent = Remotes:WaitForChild("FireWeaponEvent") :: RemoteEvent
local ReloadWeaponEvent = Remotes:WaitForChild("ReloadWeaponEvent") :: RemoteEvent
local HitConfirmEvent = Remotes:WaitForChild("HitConfirmEvent") :: RemoteEvent
local WeaponTracerEvent = Remotes:WaitForChild("WeaponTracerEvent") :: RemoteEvent

type PlayerAmmoState = {
	Ammo: number,
	LastFireTime: number,
	IsReloading: boolean,
	ReloadToken: number,
}

local stats = WeaponStats.G18
local playerStates: { [number]: PlayerAmmoState } = {}

local function resetAmmo(userId: number)
	local prev = playerStates[userId]
	local nextToken = if prev then prev.ReloadToken + 1 else 1
	playerStates[userId] = {
		Ammo = stats.MagazineSize,
		LastFireTime = 0,
		IsReloading = false,
		ReloadToken = nextToken,
	}
end

Players.PlayerAdded:Connect(function(player: Player)
	resetAmmo(player.UserId)
	player.CharacterAdded:Connect(function()
		resetAmmo(player.UserId)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerStates[player.UserId] = nil
end)

local function hasEquippedG18(character: Model): Tool?
	local tool = character:FindFirstChildOfClass("Tool")
	if tool and tool.Name == Config.DefaultWeaponName then
		return tool
	end
	return nil
end

ReloadWeaponEvent.OnServerEvent:Connect(function(player: Player)
	if player:GetAttribute("GameMode") == "Menu" then
		return
	end

	local state = playerStates[player.UserId]
	local character = player.Character
	if not state or not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if not hasEquippedG18(character) then
		return
	end
	if state.IsReloading or state.Ammo >= stats.MagazineSize then
		return
	end

	state.IsReloading = true
	state.ReloadToken += 1
	local myToken = state.ReloadToken
	character:SetAttribute("IsReloading", true)

	task.delay(stats.ReloadTime, function()
		local currentState = playerStates[player.UserId]
		if currentState and currentState.IsReloading and currentState.ReloadToken == myToken then
			currentState.Ammo = stats.MagazineSize
			currentState.IsReloading = false
			if character.Parent then
				character:SetAttribute("IsReloading", false)
			end
		end
	end)
end)

FireWeaponEvent.OnServerEvent:Connect(function(player: Player, targetPoint: unknown)
	if typeof(targetPoint) ~= "Vector3" then
		return
	end
	if player:GetAttribute("GameMode") == "Menu" then
		return
	end

	local character = player.Character
	local state = playerStates[player.UserId]
	if not character or not state then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	if not humanoid or humanoid.Health <= 0 or not (head and head:IsA("BasePart")) then
		return
	end

	local equippedTool = hasEquippedG18(character)
	if not equippedTool then
		return
	end

	if state.IsReloading or state.Ammo <= 0 then
		return
	end

	local now = os.clock()
	if (now - state.LastFireTime) < (stats.FireRate * 0.85) then
		return
	end

	state.LastFireTime = now
	state.Ammo -= 1

	local origin = head.Position
	local delta = targetPoint - origin
	if delta.Magnitude < 0.05 then
		return
	end
	local unitDir = delta.Unit
	local direction = unitDir * stats.MaxRange

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, rayParams)
	local endPos = if result then result.Position else (origin + direction)

	-- Replicar trazador visual a los demás clientes
	local muzzle = equippedTool:FindFirstChild("Muzzle")
	local muzzlePos = if muzzle and muzzle:IsA("BasePart") then muzzle.Position else origin
	for _, other in Players:GetPlayers() do
		if other ~= player then
			WeaponTracerEvent:FireClient(other, character, muzzlePos, endPos)
		end
	end

	if not result or not result.Instance then
		return
	end

	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
	if not hitModel then
		return
	end

	local targetHumanoid = hitModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	local damage, hitZone = WeaponStats.ResolveHitDamage(Config.DefaultWeaponName, result.Instance.Name)
	local isHeadshot = hitZone == "Head"

	targetHumanoid:SetAttribute("LastAttackerUserId", player.UserId)
	targetHumanoid:SetAttribute("LastHitDirection", unitDir)
	targetHumanoid:TakeDamage(damage)

	HitConfirmEvent:FireClient(player, {
		IsHeadshot = isHeadshot,
		HitZone = hitZone,
		Damage = damage,
		HitPosition = result.Position,
		RemainingHealth = math.max(0, targetHumanoid.Health),
	})
end)
