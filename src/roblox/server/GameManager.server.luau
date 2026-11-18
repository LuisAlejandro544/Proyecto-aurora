--!strict
--[=[
	Gestor principal de la partida 1v1 (Script en ServerScriptService.Server).
	Lógica:
	- Gestiona la selección de modo al iniciar: "Contra Bot" (activo) o
	  "Multijugador 1v1" (próximamente), además de volver al menú.
	- Asigna spawns opuestos (SpawnA y SpawnB) y reutiliza slots al salir.
	- Prepara los personajes para caída realista (RagdollService) sin desarmarse al morir.
	- Entrega la G18, coordina el marcador contra el Bot o rivales y notifica al HUD.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MovementConfig = require(Shared:WaitForChild("MovementConfig"))

local BotManager = require(script.Parent:WaitForChild("BotManager"))
local RagdollService = require(script.Parent:WaitForChild("RagdollService"))

local WeaponsFolder = ReplicatedStorage:WaitForChild("Weapons")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScoreUpdateEvent = Remotes:WaitForChild("ScoreUpdateEvent") :: RemoteEvent
local SelectModeEvent = Remotes:WaitForChild("SelectModeEvent") :: RemoteEvent
local MatchStateEvent = Remotes:WaitForChild("MatchStateEvent") :: RemoteEvent

Players.RespawnTime = Config.RespawnDelay

local playerSlots: { [number]: number } = {}
local playerModes: { [number]: string } = {}
local botMatchScore: { PlayerKills: number, BotKills: number, BotName: string } = {
	PlayerKills = 0,
	BotKills = 0,
	BotName = Config.BotNames[1],
}

local function pickAvailableSlot(): number
	local used1 = false
	local used2 = false
	for _, slot in playerSlots do
		if slot == 1 then
			used1 = true
		elseif slot == 2 then
			used2 = true
		end
	end
	if not used1 then
		return 1
	elseif not used2 then
		return 2
	end
	return 1
end

local function getSpawnPart(slotIndex: number): SpawnLocation?
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
	if spawnPart and spawnPart:IsA("SpawnLocation") then
		return spawnPart
	end
	return nil
end

local function getSpawnCFrame(slotIndex: number): CFrame?
	local spawnPart = getSpawnPart(slotIndex)
	if spawnPart then
		return spawnPart.CFrame + Vector3.new(0, 3.5, 0)
	end
	return nil
end

local function sendMatchState(player: Player, notice: string?)
	local mode = playerModes[player.UserId] or "Menu"
	MatchStateEvent:FireClient(player, {
		Mode = mode,
		BotName = botMatchScore.BotName,
		PlayerKills = botMatchScore.PlayerKills,
		BotKills = botMatchScore.BotKills,
		Notice = notice,
	})
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

local function clearWeapons(player: Player, character: Model?)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in backpack:GetChildren() do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end
	end
	if character then
		for _, item in character:GetChildren() do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end
	end
end

local function giveDefaultWeapon(player: Player, character: Model)
	local template = WeaponsFolder:FindFirstChild(Config.DefaultWeaponName)
	if not (template and template:IsA("Tool")) then
		return
	end

	clearWeapons(player, character)

	local backpack = player:WaitForChild("Backpack")
	local weaponClone = template:Clone()
	weaponClone.Parent = backpack

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		task.defer(function()
			if weaponClone.Parent == backpack and humanoid.Health > 0 then
				humanoid:EquipTool(weaponClone)
			end
		end)
	end
end

local function setupCharacterForMode(player: Player, character: Model)
	local mode = playerModes[player.UserId] or "Menu"
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	RagdollService.PrepareCharacter(character)
	character:SetAttribute("MoveState", "Idle")
	character:SetAttribute("IsAiming", false)

	local slot = playerSlots[player.UserId] or 1
	local spawnCF = getSpawnCFrame(slot)
	if spawnCF then
		task.defer(function()
			if character.Parent then
				character:PivotTo(spawnCF)
			end
		end)
	end

	if mode == "Bot" then
		humanoid.WalkSpeed = MovementConfig.WalkSpeed
		giveDefaultWeapon(player, character)
	else
		humanoid.WalkSpeed = 0
		clearWeapons(player, character)
	end
end

SelectModeEvent.OnServerEvent:Connect(function(player: Player, requestedMode: unknown)
	if typeof(requestedMode) ~= "string" then
		return
	end

	if requestedMode == "Multiplayer" then
		sendMatchState(player, "Modo Multijugador 1v1 estará disponible próximamente. ¡Entrena contra el Bot!")
		return
	end

	if requestedMode == "Menu" then
		playerModes[player.UserId] = "Menu"
		player:SetAttribute("GameMode", "Menu")
		BotManager.StopBotMatch()
		if player.Character then
			setupCharacterForMode(player, player.Character)
		end
		sendMatchState(player)
		return
	end

	if requestedMode == "Bot" then
		playerModes[player.UserId] = "Bot"
		player:SetAttribute("GameMode", "Bot")

		local botName = Config.BotNames[math.random(1, #Config.BotNames)]
		botMatchScore = {
			PlayerKills = 0,
			BotKills = 0,
			BotName = botName,
		}

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local k = leaderstats:FindFirstChild("Kills")
			local d = leaderstats:FindFirstChild("Deaths")
			if k and k:IsA("IntValue") then
				k.Value = 0
			end
			if d and d:IsA("IntValue") then
				d.Value = 0
			end
		end

		if player.Character then
			setupCharacterForMode(player, player.Character)
		end

		BotManager.StartBotMatch(player, botName, {
			OnBotKilled = function()
				if playerModes[player.UserId] ~= "Bot" then
					return
				end
				botMatchScore.PlayerKills += 1
				if leaderstats then
					local k = leaderstats:FindFirstChild("Kills")
					if k and k:IsA("IntValue") then
						k.Value = botMatchScore.PlayerKills
					end
				end
				sendMatchState(player)
				broadcastScores()
			end,
			OnPlayerKilledByBot = function()
				-- El conteo de muerte del jugador se consolida en humanoid.Died
			end,
		})

		sendMatchState(player)
		broadcastScores()
	end
end)

Players.PlayerAdded:Connect(function(player: Player)
	local slot = pickAvailableSlot()
	playerSlots[player.UserId] = slot
	playerModes[player.UserId] = "Menu"
	player:SetAttribute("GameMode", "Menu")

	local spawnPart = getSpawnPart(slot)
	if spawnPart then
		player.RespawnLocation = spawnPart
	end

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
		setupCharacterForMode(player, character)
		sendMatchState(player)

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Connect(function()
			deaths.Value += 1

			-- Caída realista tipo Ragdoll en lugar de desarmarse
			local hitDirAttr = humanoid:GetAttribute("LastHitDirection")
			local hitDir = if typeof(hitDirAttr) == "Vector3" then hitDirAttr else nil
			RagdollService.ApplyRagdoll(character, hitDir)

			local attackerId = humanoid:GetAttribute("LastAttackerUserId")
			if attackerId == -1 and playerModes[player.UserId] == "Bot" then
				botMatchScore.BotKills += 1
				sendMatchState(player)
			elseif typeof(attackerId) == "number" and attackerId ~= player.UserId then
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

	sendMatchState(player)
	broadcastScores()
end)

Players.PlayerRemoving:Connect(function(player: Player)
	playerSlots[player.UserId] = nil
	playerModes[player.UserId] = nil
	BotManager.StopBotMatch()
	task.defer(broadcastScores)
end)
