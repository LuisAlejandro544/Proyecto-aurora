--!strict
--[=[
	Servidor autoritativo del arma G18 (Script en ServerScriptService.Server).
	Lógica:
	- Controla munición por jugador (33 balas por cargador) y tiempo de recarga.
	- Valida la cadencia de disparo automático y ejecuta el Raycast real en servidor
	  desde la posición de la cabeza del tirador, respetando todas las coberturas
	  del mapa para que ninguna bala atraviese muros o vehículos.
	- Aplica daño (cabeza o cuerpo) y envía confirmación de impacto (Hitmarker).
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

type PlayerAmmoState = {
	Ammo: number,
	LastFireTime: number,
	IsReloading: boolean,
}

local stats = WeaponStats.G18
local playerStates: { [number]: PlayerAmmoState } = {}

local function resetAmmo(userId: number)
	playerStates[userId] = {
		Ammo = stats.MagazineSize,
		LastFireTime = 0,
		IsReloading = false,
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
	task.delay(stats.ReloadTime, function()
		local currentState = playerStates[player.UserId]
		if currentState and currentState.IsReloading then
			currentState.Ammo = stats.MagazineSize
			currentState.IsReloading = false
		end
	end)
end)

FireWeaponEvent.OnServerEvent:Connect(function(player: Player, targetPoint: unknown)
	if typeof(targetPoint) ~= "Vector3" then
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

	if not hasEquippedG18(character) then
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
	local direction = delta.Unit * stats.MaxRange

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, rayParams)
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

	local isHeadshot = result.Instance.Name == "Head"
	local damage = if isHeadshot then stats.DamageHead else stats.DamageBody

	targetHumanoid:SetAttribute("LastAttackerUserId", player.UserId)
	targetHumanoid:TakeDamage(damage)

	HitConfirmEvent:FireClient(player, {
		IsHeadshot = isHeadshot,
		HitPosition = result.Position,
		RemainingHealth = math.max(0, targetHumanoid.Health),
	})
end)
