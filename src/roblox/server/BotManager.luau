--!strict
--[=[
	Controlador de Bot táctico con comportamiento humano (ModuleScript en ServerScriptService.Server).
	Lógica:
	- Construye un avatar R15 completo armado con la pistola automática G18.
	- Combate como un jugador real: usa PathfindingService para rodear obstáculos,
	  busca coberturas (barreras, vehículos, contenedor), hace strafe lateral al disparar,
	  desliza (Slide) para reposicionarse, se agacha al recargar cuando está bajo de vida
	  y reacciona con tiempo humano y dispersión realista (sin aimbot instantáneo).
	- Aplica el mismo sistema de daño anatómico (cabeza, pecho, brazos, manos, piernas, pies),
	  envía trazadores visibles al jugador y al morir cae con Ragdoll realista.
]=]

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local MovementConfig = require(Shared:WaitForChild("MovementConfig"))
local WeaponStats = require(Shared:WaitForChild("WeaponStats"))

local RagdollService = require(script.Parent:WaitForChild("RagdollService"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WeaponTracerEvent = Remotes:WaitForChild("WeaponTracerEvent") :: RemoteEvent
local WeaponsFolder = ReplicatedStorage:WaitForChild("Weapons")

local BotManager = {}

export type BotCallbacks = {
	OnBotKilled: () -> (),
	OnPlayerKilledByBot: () -> (),
}

local COVER_SPOTS: { Vector3 } = {
	Vector3.new(6, 1, -28),
	Vector3.new(-6, 1, 28),
	Vector3.new(-10, 1, -14),
	Vector3.new(10, 1, 14),
	Vector3.new(0, 1, 0),
	Vector3.new(-32, 1, -28),
	Vector3.new(32, 1, 28),
	Vector3.new(32, 1, -22),
	Vector3.new(-32, 1, 22),
}

local FLANK_WAYPOINTS: { Vector3 } = {
	Vector3.new(-24, 1, -18),
	Vector3.new(24, 1, 18),
	Vector3.new(-24, 1, 18),
	Vector3.new(24, 1, -18),
	Vector3.new(-38, 10, -26),
	Vector3.new(38, 10, 26),
}

local rng = Random.new()
local activeMatchToken = 0
local activeBotModel: Model? = nil
local activeTargetPlayer: Player? = nil

local function getBotSpawnCFrame(): CFrame
	local mapFolder = workspace:FindFirstChild(Config.MapFolderName)
	local spawns = if mapFolder then mapFolder:FindFirstChild(Config.SpawnsFolderName) else nil
	local spawnB = if spawns then spawns:FindFirstChild("SpawnB") else nil
	if spawnB and spawnB:IsA("BasePart") then
		return spawnB.CFrame + Vector3.new(0, 3.5, 0)
	end
	return CFrame.new(0, 4, 58)
end

-- Crea un avatar R15 completo mediante HumanoidDescription, con respaldo manual R6 si fallara
local function createBotRig(botName: string): Model
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromRGB(214, 172, 140)
	desc.TorsoColor = Color3.fromRGB(44, 50, 56)
	desc.LeftArmColor = Color3.fromRGB(52, 58, 64)
	desc.RightArmColor = Color3.fromRGB(52, 58, 64)
	desc.LeftLegColor = Color3.fromRGB(32, 35, 40)
	desc.RightLegColor = Color3.fromRGB(32, 35, 40)
	desc.HeightScale = 1
	desc.WidthScale = 1

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	desc:Destroy()

	if ok and model then
		model.Name = botName
		return model
	end

	-- Respaldo R6 en caso de entorno sin acceso a mallas
	local fallback = Instance.new("Model")
	fallback.Name = botName

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Parent = fallback

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(44, 50, 56)
	torso.Parent = fallback

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = Color3.fromRGB(214, 172, 140)
	head.Parent = fallback

	local leftArm = Instance.new("Part")
	leftArm.Name = "Left Arm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Color = Color3.fromRGB(52, 58, 64)
	leftArm.Parent = fallback

	local rightArm = Instance.new("Part")
	rightArm.Name = "Right Arm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Color = Color3.fromRGB(52, 58, 64)
	rightArm.Parent = fallback

	local leftLeg = Instance.new("Part")
	leftLeg.Name = "Left Leg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Color = Color3.fromRGB(32, 35, 40)
	leftLeg.Parent = fallback

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "Right Leg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Color = Color3.fromRGB(32, 35, 40)
	rightLeg.Parent = fallback

	local function link(name: string, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = c0
		m.C1 = c1
		m.Parent = p0
	end

	link("RootJoint", root, torso, CFrame.new(), CFrame.new())
	link("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.6, 0))
	link("Left Shoulder", torso, leftArm, CFrame.new(-1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	link("Right Shoulder", torso, rightArm, CFrame.new(1.5, 0.5, 0), CFrame.new(0, 0.5, 0))
	link("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	link("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))

	local hum = Instance.new("Humanoid")
	hum.Parent = fallback
	fallback.PrimaryPart = root
	return fallback
end

local function hasLineOfSight(fromPos: Vector3, toPos: Vector3, botModel: Model, targetChar: Model): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { botModel }
	params.IgnoreWater = true

	local dir = toPos - fromPos
	if dir.Magnitude < 0.1 then
		return true
	end
	local result = workspace:Raycast(fromPos, dir, params)
	if not result then
		return true
	end
	return result.Instance:IsDescendantOf(targetChar)
end

local function findNearestCoverAwayFrom(botPos: Vector3, enemyPos: Vector3, botModel: Model, targetChar: Model): Vector3
	local bestSpot = COVER_SPOTS[1]
	local bestScore = -math.huge

	for _, spot in COVER_SPOTS do
		local distToBot = (spot - botPos).Magnitude
		local distToEnemy = (spot - enemyPos).Magnitude
		local blockedFromEnemy = not hasLineOfSight(spot + Vector3.new(0, 2.2, 0), enemyPos + Vector3.new(0, 2.2, 0), botModel, targetChar)
		local score = (if blockedFromEnemy then 45 else 0) + math.min(distToEnemy, 50) * 0.4 - distToBot * 0.65
		if score > bestScore then
			bestScore = score
			bestSpot = spot
		end
	end

	return bestSpot
end

local function spawnBotInstance(botName: string): (Model, Humanoid, BasePart, BasePart)
	local bot = createBotRig(botName)
	bot:SetAttribute("IsBot", true)
	bot:SetAttribute("MoveState", "Idle")
	bot:SetAttribute("IsAiming", false)

	local spawnCF = getBotSpawnCFrame()
	bot:PivotTo(spawnCF)
	bot.Parent = workspace

	RagdollService.PrepareCharacter(bot)

	local hum = bot:WaitForChild("Humanoid") :: Humanoid
	hum.DisplayName = botName
	hum.WalkSpeed = MovementConfig.WalkSpeed
	hum.JumpPower = MovementConfig.JumpPower
	hum.UseJumpPower = true

	local root = bot:WaitForChild("HumanoidRootPart") :: BasePart
	local head = bot:WaitForChild("Head") :: BasePart

	-- Asegurar simulación física fluida en servidor
	for _, desc in bot:GetDescendants() do
		if desc:IsA("BasePart") then
			pcall(function()
				desc:SetNetworkOwner(nil)
			end)
		end
	end

	-- Equipar G18 al Bot
	local template = WeaponsFolder:FindFirstChild(Config.DefaultWeaponName)
	if template and template:IsA("Tool") then
		local g18 = template:Clone()
		g18.Parent = bot
		hum:EquipTool(g18)
	end

	return bot, hum, root, head
end

function BotManager.StopBotMatch()
	activeMatchToken += 1
	activeTargetPlayer = nil
	if activeBotModel then
		activeBotModel:Destroy()
		activeBotModel = nil
	end
end

function BotManager.StartBotMatch(targetPlayer: Player, botName: string, callbacks: BotCallbacks)
	BotManager.StopBotMatch()

	local myToken = activeMatchToken
	activeTargetPlayer = targetPlayer

	task.spawn(function()
		local stats = WeaponStats.G18

		while activeMatchToken == myToken and targetPlayer.Parent do
			local bot, hum, root, head = spawnBotInstance(botName)
			activeBotModel = bot

			local baseHipHeight = hum.HipHeight
			local ammo = stats.MagazineSize
			local isReloading = false
			local isSliding = false
			local slideEndTime = 0
			local nextSlideAllowed = 0
			local nextJumpAllowed = 0
			local lastShotTime = 0
			local burstRemaining = 0
			local nextBurstTime = 0
			local reactionReadyTime = 0
			local hadSightLastTick = false

			local strafeSign = if rng:NextNumber() > 0.5 then 1 else -1
			local nextStrafeSwitch = 0
			local currentAimDir = root.CFrame.LookVector

			local waypoints: { PathWaypoint } = {}
			local waypointIndex = 1
			local nextPathUpdate = 0
			local activeSlideForce: LinearVelocity? = nil

			local botAlive = true
			local deathFinished = false

			hum.Died:Connect(function()
				botAlive = false
				if activeSlideForce then
					activeSlideForce:Destroy()
					activeSlideForce = nil
				end
				local hitDirAttr = hum:GetAttribute("LastHitDirection")
				local hitDir = if typeof(hitDirAttr) == "Vector3" then hitDirAttr else nil
				RagdollService.ApplyRagdoll(bot, hitDir)
				callbacks.OnBotKilled()
				task.delay(Config.BotRespawnDelay, function()
					deathFinished = true
				end)
			end)

			local function setSlide(enable: boolean, moveDir: Vector3)
				if enable == isSliding then
					return
				end
				isSliding = enable
				if activeSlideForce then
					activeSlideForce:Destroy()
					activeSlideForce = nil
				end
				if enable then
					slideEndTime = os.clock() + MovementConfig.SlideDuration * 0.85
					nextSlideAllowed = os.clock() + 2.4
					hum.HipHeight = math.max(0.2, baseHipHeight - 1.3)
					bot:SetAttribute("MoveState", "Slide")

					local att = root:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", root)
					local lv = Instance.new("LinearVelocity")
					lv.Attachment0 = att
					lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
					lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
					lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
					lv.MaxForce = 24000
					lv.PlaneVelocity = Vector2.new(moveDir.X * MovementConfig.SlideInitialSpeed * 0.9, moveDir.Z * MovementConfig.SlideInitialSpeed * 0.9)
					lv.Parent = root
					activeSlideForce = lv
				else
					hum.HipHeight = baseHipHeight
				end
			end

			local function startReload()
				if isReloading or ammo >= stats.MagazineSize then
					return
				end
				isReloading = true
				bot:SetAttribute("IsAiming", false)
				bot:SetAttribute("IsReloading", true)
				task.delay(stats.ReloadTime, function()
					if activeMatchToken == myToken and botAlive then
						ammo = stats.MagazineSize
						isReloading = false
						bot:SetAttribute("IsReloading", false)
					end
				end)
			end

			local function fireBotShot(targetChar: Model, targetHead: BasePart, targetTorso: BasePart)
				local now = os.clock()
				if isReloading or ammo <= 0 then
					startReload()
					return
				end
				if (now - lastShotTime) < (stats.FireRate * rng:NextNumber(1.05, 1.35)) then
					return
				end

				lastShotTime = now
				ammo -= 1
				bot:SetAttribute("LastShotClock", now)

				-- Escoger punto objetivo humano (mayormente pecho, a veces cabeza)
				local aimAnchor = if rng:NextNumber() < 0.24 then targetHead else targetTorso
				local idealDir = (aimAnchor.Position - head.Position).Unit
				currentAimDir = currentAimDir:Lerp(idealDir, 0.42).Unit

				-- Dispersión humana realista (aumenta si se mueve/desliza o a larga distancia)
				local dist = (aimAnchor.Position - head.Position).Magnitude
				local spreadDeg = if isSliding then 4.8 elseif hum.MoveDirection.Magnitude > 0.2 then 3.5 else 2.2
				if dist > 65 then
					spreadDeg += 1.2
				end
				local spreadRad = math.rad(spreadDeg)
				local shotCF = CFrame.lookAt(Vector3.zero, currentAimDir)
					* CFrame.Angles(rng:NextNumber(-spreadRad, spreadRad), rng:NextNumber(-spreadRad, spreadRad), 0)

				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = { bot }
				rayParams.IgnoreWater = true

				local origin = head.Position
				local result = workspace:Raycast(origin, shotCF.LookVector * stats.MaxRange, rayParams)
				local endPos = if result then result.Position else (origin + shotCF.LookVector * stats.MaxRange)

				-- Origen visual en el cañón de la G18 del Bot
				local muzzlePos = origin
				local equippedTool = bot:FindFirstChildOfClass("Tool")
				if equippedTool then
					local muzzle = equippedTool:FindFirstChild("Muzzle")
					if muzzle and muzzle:IsA("BasePart") then
						muzzlePos = muzzle.Position
					end
				end

				WeaponTracerEvent:FireAllClients(bot, muzzlePos, endPos)

				if result and result.Instance and result.Instance:IsDescendantOf(targetChar) then
					local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
					if targetHum and targetHum.Health > 0 then
						local damage, _zone = WeaponStats.ResolveHitDamage(Config.DefaultWeaponName, result.Instance.Name)
						-- Ajuste sutil de ritmo en ráfagas para que el duelo sea justo y táctico en móvil
						local scaledDamage = math.max(6, math.round(damage * 0.72))
						targetHum:SetAttribute("LastAttackerUserId", -1)
						targetHum:SetAttribute("LastHitDirection", shotCF.LookVector)
						targetHum:TakeDamage(scaledDamage)
						if targetHum.Health <= 0 then
							callbacks.OnPlayerKilledByBot()
						end
					end
				end

				if ammo <= 0 then
					startReload()
				end
			end

			-- Bucle principal del Bot mientras esté vivo
			while activeMatchToken == myToken and botAlive and targetPlayer.Parent do
				local now = os.clock()
				local targetChar = targetPlayer.Character
				local targetHum = if targetChar then targetChar:FindFirstChildOfClass("Humanoid") else nil
				local targetRoot = if targetChar then targetChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				local targetHead = if targetChar then targetChar:FindFirstChild("Head") :: BasePart? else nil
				local targetTorso = if targetChar
					then (targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Torso")) :: BasePart?
					else nil

				if not (targetChar and targetHum and targetHum.Health > 0 and targetRoot and targetHead and targetTorso) then
					-- Esperar con calma a que el jugador reaparezca y rotar hacia el centro
					bot:SetAttribute("MoveState", "Idle")
					bot:SetAttribute("IsAiming", false)
					hum.WalkSpeed = MovementConfig.WalkSpeed
					hum:MoveTo(root.Position)
					task.wait(0.2)
					continue
				end

				local botPos = root.Position
				local enemyPos = targetRoot.Position
				local distToEnemy = (enemyPos - botPos).Magnitude
				local canSee = hasLineOfSight(head.Position, targetHead.Position, bot, targetChar)
					or hasLineOfSight(head.Position, targetTorso.Position, bot, targetChar)

				if canSee and not hadSightLastTick then
					-- Tiempo de reacción humano al detectar al jugador
					reactionReadyTime = now + rng:NextNumber(0.20, 0.34)
				end
				hadSightLastTick = canSee

				if isSliding and now >= slideEndTime then
					setSlide(false, Vector3.zero)
				end

				-- Decidir si debe retirarse a cobertura (recargando o vida baja)
				local needsCover = isReloading or (hum.Health < 38 and ammo <= 10)

				if needsCover then
					local coverPos = findNearestCoverAwayFrom(botPos, enemyPos, bot, targetChar)
					local toCover = coverPos - botPos
					if toCover.Magnitude > 5 then
						hum.WalkSpeed = MovementConfig.SprintSpeed * 0.92
						hum.AutoRotate = true
						hum.HipHeight = baseHipHeight
						bot:SetAttribute("MoveState", "Sprint")
						bot:SetAttribute("IsAiming", false)
						hum:MoveTo(coverPos)
					else
						-- Agachado detrás de la cobertura mientras recarga
						hum.WalkSpeed = MovementConfig.CrouchSpeed
						hum.HipHeight = math.max(0.2, baseHipHeight - 1.0)
						bot:SetAttribute("MoveState", "Crouch")
						bot:SetAttribute("IsAiming", false)
					end
				elseif canSee then
					-- COMBATE ACTIVO (Strafe humano, slide ocasional, ráfagas)
					hum.HipHeight = if isSliding then math.max(0.2, baseHipHeight - 1.3) else baseHipHeight

					-- Mirar suavemente hacia el jugador al disparar
					local flatDir = Vector3.new(enemyPos.X - botPos.X, 0, enemyPos.Z - botPos.Z)
					if flatDir.Magnitude > 0.1 then
						hum.AutoRotate = false
						local targetCF = CFrame.lookAt(botPos, botPos + flatDir.Unit)
						root.CFrame = root.CFrame:Lerp(targetCF, 0.35)
					end

					-- Cambio impredecible de dirección lateral (strafe)
					if now >= nextStrafeSwitch then
						strafeSign = if rng:NextNumber() > 0.45 then -strafeSign else strafeSign
						nextStrafeSwitch = now + rng:NextNumber(0.45, 1.05)
					end

					local forwardDir = if flatDir.Magnitude > 0.1 then flatDir.Unit else root.CFrame.LookVector
					local rightDir = Vector3.new(-forwardDir.Z, 0, forwardDir.X)

					-- Mantener distancia óptima (acercarse si está lejos, retroceder un poco si está pegado)
					local radialFactor = if distToEnemy > 42 then 0.65 elseif distToEnemy < 14 then -0.45 else 0.1
					local moveVec = (rightDir * strafeSign + forwardDir * radialFactor).Unit

					-- Slide táctico ocasional para evadir disparos o cerrar distancia
					if not isSliding and now >= nextSlideAllowed and distToEnemy > 16 and distToEnemy < 55 and rng:NextNumber() < 0.08 then
						setSlide(true, moveVec)
					elseif not isSliding then
						-- Salto evasivo ocasional en duelos cercanos
						if distToEnemy < 26 and now >= nextJumpAllowed and hum.FloorMaterial ~= Enum.Material.Air and rng:NextNumber() < 0.05 then
							hum.Jump = true
							nextJumpAllowed = now + 2.8
						end

						hum.WalkSpeed = MovementConfig.WalkSpeed * 0.92
						bot:SetAttribute("MoveState", if hum.FloorMaterial == Enum.Material.Air then "Jump" else "Idle")
						bot:SetAttribute("IsAiming", true)
						hum:Move(moveVec, false)
					end

					-- Disparo por ráfagas con pausas humanas de control de retroceso
					if now >= reactionReadyTime then
						if burstRemaining <= 0 and now >= nextBurstTime then
							burstRemaining = if distToEnemy < 28 then rng:NextInteger(5, 10) else rng:NextInteger(2, 5)
						end
						if burstRemaining > 0 then
							fireBotShot(targetChar, targetHead, targetTorso)
							burstRemaining -= 1
							if burstRemaining <= 0 then
								nextBurstTime = now + rng:NextNumber(0.14, 0.30)
							end
						end
					end
				else
					-- SIN LÍNEA DE VISIÓN: navegar inteligentemente por MapaRuinas / flanquear
					hum.AutoRotate = true
					hum.HipHeight = baseHipHeight
					bot:SetAttribute("IsAiming", false)

					if now >= nextPathUpdate then
						nextPathUpdate = now + rng:NextNumber(0.65, 1.0)
						-- Ocasionalmente elegir un punto de flanqueo antes de ir directo al jugador
						local goalPos = enemyPos
						if distToEnemy > 35 and rng:NextNumber() < 0.30 then
							goalPos = FLANK_WAYPOINTS[rng:NextInteger(1, #FLANK_WAYPOINTS)]
						end

						local path = PathfindingService:CreatePath({
							AgentRadius = 2.2,
							AgentHeight = 5.2,
							AgentCanJump = true,
							WaypointSpacing = 6,
						})
						local okPath = pcall(function()
							path:ComputeAsync(botPos, goalPos)
						end)
						if okPath and path.Status == Enum.PathStatus.Success then
							waypoints = path:GetWaypoints()
							waypointIndex = 2
						else
							waypoints = {}
						end
					end

					if #waypoints > 0 and waypointIndex <= #waypoints then
						local wp = waypoints[waypointIndex]
						if wp.Action == Enum.PathWaypointAction.Jump and hum.FloorMaterial ~= Enum.Material.Air then
							hum.Jump = true
						end
						hum.WalkSpeed = MovementConfig.SprintSpeed * 0.88
						bot:SetAttribute("MoveState", "Sprint")
						hum:MoveTo(wp.Position)
						if (Vector3.new(wp.Position.X - botPos.X, 0, wp.Position.Z - botPos.Z)).Magnitude < 4.5 then
							waypointIndex += 1
						end
					else
						hum.WalkSpeed = MovementConfig.SprintSpeed * 0.88
						bot:SetAttribute("MoveState", "Sprint")
						hum:MoveTo(enemyPos)
					end
				end

				task.wait(0.05)
			end

			-- Esperar a que termine la vista de Ragdoll antes de limpiar y reaparecer
			while activeMatchToken == myToken and not deathFinished do
				task.wait(0.1)
			end

			if bot.Parent then
				bot:Destroy()
			end
			if activeBotModel == bot then
				activeBotModel = nil
			end
		end
	end)
end

return BotManager
