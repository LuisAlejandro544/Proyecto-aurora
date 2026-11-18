--!strict
--[=[
	Gestor principal de la partida 1v1 (Script en ServerScriptService.Server).
	Lógica:
	- Asigna spawns opuestos (SpawnA y SpawnB) para los jugadores en la ciudad en ruinas.
	- Entrega y equipa automáticamente la pistola G18 al aparecer.
	- Registra bajas/muertes del duelo 1v1 y notifica a los clientes para el marcador.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local WeaponsFolder = ReplicatedStorage:WaitForChild("Weapons")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScoreUpdateEvent = Remotes:WaitForChild("ScoreUpdateEvent") :: RemoteEvent

Players.RespawnTime = Config.RespawnDelay

local playerSlots: { [number]: number } = {}
local nextSlot = 1

local function getSpawnCFrame(slotIndex: number): CFrame?
	local mapFolder = workspace:FindFirstChild(Config.MapFolderName)
	if not mapFolder then
		return nil
	end
	local spawnsFolder = mapFolder:FindFirstChild(Config.SpawnsFolderName)
	if not spawnsFolder then
		return nil
	end

	local targetName = if slotIndex % 2 == 1 then "SpawnA" else "SpawnB"
	local spawnPart = spawnsFolder:FindFirstChild(targetName)
	if spawnPart and spawnPart:IsA("BasePart") then
		return spawnPart.CFrame + Vector3.new(0, 3.5, 0)
	end
	return nil
end

local function broadcastScores()
	local summary = {}
	for _, player in Players:GetPlayers() do
		local leaderstats = player:FindFirstChild("leaderstats")
		local kills = if leaderstats and leaderstats:FindFirstChild("Kills")
			then (leaderstats:FindFirstChild("Kills") :: IntValue).Value
			else 0
		local deaths = if leaderstats and leaderstats:FindFirstChild("Deaths")
			then (leaderstats:FindFirstChild("Deaths") :: IntValue).Value
			else 0
		table.insert(summary, {
			UserId = player.UserId,
			Name = player.DisplayName,
			Kills = kills,
			Deaths = deaths,
		})
	end
	ScoreUpdateEvent:FireAllClients(summary)
end

local function giveDefaultWeapon(player: Player, character: Model)
	local template = WeaponsFolder:FindFirstChild(Config.DefaultWeaponName)
	if not (template and template:IsA("Tool")) then
		return
	end

	local backpack = player:WaitForChild("Backpack")
	for _, item in backpack:GetChildren() do
		if item.Name == Config.DefaultWeaponName then
			item:Destroy()
		end
	end

	local weaponClone = template:Clone()
	weaponClone.Parent = backpack

	-- Equipar automáticamente la G18 al aparecer
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		task.defer(function()
			if weaponClone.Parent == backpack and humanoid.Health > 0 then
				humanoid:EquipTool(weaponClone)
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(player: Player)
	playerSlots[player.UserId] = nextSlot
	nextSlot += 1

	-- Tabla estándar de puntuación 1v1
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = 0
	kills.Parent = leaderstats

	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = 0
	deaths.Parent = leaderstats

	player.CharacterAdded:Connect(function(character: Model)
		character:SetAttribute("MoveState", "Idle")
		character:SetAttribute("IsAiming", false)

		local slot = playerSlots[player.UserId] or 1
		local spawnCF = getSpawnCFrame(slot)
		if spawnCF then
			task.defer(function()
				character:PivotTo(spawnCF)
			end)
		end

		giveDefaultWeapon(player, character)

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			deaths.Value += 1
			local attackerId = humanoid:GetAttribute("LastAttackerUserId")
			if typeof(attackerId) == "number" and attackerId ~= player.UserId then
				local killer = Players:GetPlayerByUserId(attackerId)
				if killer then
					local kStats = killer:FindFirstChild("leaderstats")
					local kKills = if kStats then kStats:FindFirstChild("Kills") else nil
					if kKills and kKills:IsA("IntValue") then
						kKills.Value += 1
					end
				end
			end
			broadcastScores()
		end)
	end)

	broadcastScores()
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerSlots[player.UserId] = nil
	task.defer(broadcastScores)
end)
