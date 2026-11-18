--!strict
--[=[
	Controlador de movimiento estilo Warzone (LocalScript en StarterPlayerScripts.Client).
	Lógica:
	- Sprint táctico (LeftShift en PC o botón Sprint en móvil).
	- Agacharse (C / Ctrl) o Deslizarse (Slide) si vas corriendo rápido.
	- Slide Cancel + Saltar (Espacio / botón Saltar durante un Slide corta el impulso
	  al instante y te lanza en salto limpio).
	- Lanzarse al suelo / Dolphin Dive (V / F o botón Lanzarse) con impulso aéreo
	  y breve recuperación al aterrizar.
	- Sincroniza el estado con el servidor para que las animaciones sean visibles al rival.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared:WaitForChild("MovementConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementStateEvent = Remotes:WaitForChild("MovementStateEvent") :: RemoteEvent

local ClientState = require(script.Parent:WaitForChild("ClientState"))

local localPlayer = Players.LocalPlayer

local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentRoot: BasePart? = nil
local baseHipHeight = 2.0

local isSliding = false
local slideStartTime = 0
local lastSlideEndTime = 0
local slideDirection = Vector3.zero
local activeSlideForce: LinearVelocity? = nil

local isDiving = false
local diveStartTime = 0
local lastDiveEndTime = 0
local diveRecovering = false
local diveDirection = Vector3.zero

local lastSentState = ""
local lastSentAim = false

local function syncStateToServer(newState: ClientState.MoveState)
	ClientState.MoveState = newState
	if currentCharacter then
		currentCharacter:SetAttribute("MoveState", newState)
		currentCharacter:SetAttribute("IsAiming", ClientState.IsAiming)
	end
	if newState ~= lastSentState or ClientState.IsAiming ~= lastSentAim then
		lastSentState = newState
		lastSentAim = ClientState.IsAiming
		MovementStateEvent:FireServer(newState, ClientState.IsAiming)
	end
end

local function clearSlideForce()
	if activeSlideForce then
		activeSlideForce:Destroy()
		activeSlideForce = nil
	end
end

local function stopSlide(keepCrouch: boolean)
	if not isSliding then
		return
	end
	isSliding = false
	lastSlideEndTime = os.clock()
	clearSlideForce()

	local hum = currentHumanoid
	if hum then
		hum.AutoRotate = true
		hum.JumpPower = MovementConfig.JumpPower
		if keepCrouch then
			ClientState.IsCrouching = true
			hum.HipHeight = math.max(0.2, baseHipHeight - 1.1)
		else
			ClientState.IsCrouching = false
			hum.HipHeight = baseHipHeight
		end
	end
end

local function startSlide()
	local hum = currentHumanoid
	local root = currentRoot
	if not hum or not root or hum.Health <= 0 then
		return
	end
	if isSliding or isDiving then
		return
	end
	if hum.FloorMaterial == Enum.Material.Air then
		return
	end
	if (os.clock() - lastSlideEndTime) < MovementConfig.SlideCooldown then
		return
	end

	local moveDir = hum.MoveDirection
	if moveDir.Magnitude < 0.1 then
		moveDir = root.CFrame.LookVector
	end
	slideDirection = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

	isSliding = true
	ClientState.IsCrouching = false
	slideStartTime = os.clock()

	hum.AutoRotate = false
	hum.HipHeight = math.max(0.2, baseHipHeight - 1.35)

	clearSlideForce()
	local att = root:FindFirstChild("RootAttachment") or root:FindFirstChildOfClass("Attachment")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "SlideAttachment"
		att.Parent = root
	end

	local lv = Instance.new("LinearVelocity")
	lv.Name = "SlideVelocity"
	lv.Attachment0 = att :: Attachment
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.MaxForce = 28000
	lv.PlaneVelocity = Vector2.new(
		slideDirection.X * MovementConfig.SlideInitialSpeed,
		slideDirection.Z * MovementConfig.SlideInitialSpeed
	)
	lv.Parent = root
	activeSlideForce = lv

	syncStateToServer("Slide")
end

local function triggerCrouchOrSlide()
	if ClientState.GameMode == "Menu" then
		return
	end
	local hum = currentHumanoid
	if not hum or hum.Health <= 0 or isDiving then
		return
	end

	-- Si ya estás deslizando, tocar Agacharse hace Slide Cancel limpio a sprint/agachado
	if isSliding then
		stopSlide(false)
		return
	end

	local isMovingFast = hum.MoveDirection.Magnitude > 0.15
		and (ClientState.IsSprinting or (currentRoot and currentRoot.AssemblyLinearVelocity.Magnitude > 19))

	if isMovingFast and hum.FloorMaterial ~= Enum.Material.Air then
		startSlide()
	else
		ClientState.IsCrouching = not ClientState.IsCrouching
		if ClientState.IsCrouching then
			ClientState.IsSprinting = false
			hum.HipHeight = math.max(0.2, baseHipHeight - 1.1)
		else
			hum.HipHeight = baseHipHeight
		end
	end
end

local function triggerJumpOrSlideCancel()
	if ClientState.GameMode == "Menu" then
		return
	end
	local hum = currentHumanoid
	if not hum or hum.Health <= 0 or isDiving then
		return
	end

	-- Slide Cancel + Saltar (estilo Warzone)
	if isSliding then
		stopSlide(false)
		hum.JumpPower = MovementConfig.SlideCancelJumpBoost
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		syncStateToServer("Jump")
		return
	end

	if ClientState.IsCrouching then
		ClientState.IsCrouching = false
		hum.HipHeight = baseHipHeight
	end

	if hum.FloorMaterial ~= Enum.Material.Air then
		hum.JumpPower = MovementConfig.JumpPower
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

local function triggerDive()
	if ClientState.GameMode == "Menu" then
		return
	end
	local hum = currentHumanoid
	local root = currentRoot
	if not hum or not root or hum.Health <= 0 then
		return
	end
	if isDiving or diveRecovering then
		return
	end
	if (os.clock() - lastDiveEndTime) < MovementConfig.DiveCooldown then
		return
	end

	if isSliding then
		stopSlide(false)
	end

	ClientState.IsCrouching = false
	ClientState.IsAiming = false

	local moveDir = hum.MoveDirection
	if moveDir.Magnitude < 0.1 then
		moveDir = root.CFrame.LookVector
	end
	diveDirection = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

	isDiving = true
	diveStartTime = os.clock()
	hum.AutoRotate = false
	hum.HipHeight = math.max(0.2, baseHipHeight - 1.4)

	-- Impulso balístico hacia adelante y ligeramente arriba
	root.CFrame = CFrame.lookAt(root.Position, root.Position + diveDirection)
	root.AssemblyLinearVelocity = diveDirection * MovementConfig.DiveHorizontalSpeed
		+ Vector3.new(0, MovementConfig.DiveVerticalBoost, 0)

	syncStateToServer("Dive")
end

local function toggleSprint()
	if isDiving then
		return
	end
	if isSliding then
		stopSlide(false)
	end
	ClientState.IsCrouching = false
	if currentHumanoid then
		currentHumanoid.HipHeight = baseHipHeight
	end
	ClientState.IsSprinting = not ClientState.IsSprinting
end

-- Exponer acciones para TouchHUD
ClientState.OnToggleSprint = toggleSprint
ClientState.OnCrouchOrSlide = triggerCrouchOrSlide
ClientState.OnJumpOrCancel = triggerJumpOrSlideCancel
ClientState.OnDive = triggerDive

-- Controles de teclado en PC
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if ClientState.IsCrouching and currentHumanoid then
			ClientState.IsCrouching = false
			currentHumanoid.HipHeight = baseHipHeight
		end
		ClientState.IsSprinting = true
	elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
		triggerCrouchOrSlide()
	elseif input.KeyCode == Enum.KeyCode.Space then
		triggerJumpOrSlideCancel()
	elseif input.KeyCode == Enum.KeyCode.V or input.KeyCode == Enum.KeyCode.F then
		triggerDive()
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		ClientState.IsSprinting = false
	end
end)

-- Soporte nativo para el botón de salto móvil por defecto de Roblox (por si lo tocan)
UserInputService.JumpRequest:Connect(function()
	if isSliding then
		triggerJumpOrSlideCancel()
	end
end)

RunService.Heartbeat:Connect(function()
	local hum = currentHumanoid
	local root = currentRoot
	if not hum or not root or hum.Health <= 0 then
		clearSlideForce()
		return
	end
	if ClientState.GameMode == "Menu" then
		hum.WalkSpeed = 0
		return
	end

	local now = os.clock()

	-- Actualizar deslizamiento (Slide)
	if isSliding then
		local elapsed = now - slideStartTime
		local t = math.clamp(elapsed / MovementConfig.SlideDuration, 0, 1)
		local speed = MovementConfig.SlideInitialSpeed
			+ (MovementConfig.SlideEndSpeed - MovementConfig.SlideInitialSpeed) * (t * t)

		if activeSlideForce then
			activeSlideForce.PlaneVelocity = Vector2.new(slideDirection.X * speed, slideDirection.Z * speed)
		end

		if t >= 1 then
			-- Al terminar el slide de forma natural queda agachado
			stopSlide(true)
		else
			syncStateToServer("Slide")
			return
		end
	end

	-- Actualizar lanzamiento al suelo (Dolphin Dive)
	if isDiving then
		local elapsed = now - diveStartTime
		local onGround = hum.FloorMaterial ~= Enum.Material.Air
		if (elapsed > 0.18 and onGround) or elapsed > MovementConfig.DiveMaxAirTime then
			isDiving = false
			diveRecovering = true
			lastDiveEndTime = now
			hum.WalkSpeed = 4
			task.delay(MovementConfig.DiveRecoveryTime, function()
				diveRecovering = false
				if currentHumanoid and currentHumanoid.Health > 0 then
					currentHumanoid.AutoRotate = true
					currentHumanoid.HipHeight = baseHipHeight
				end
			end)
		end
		syncStateToServer("Dive")
		return
	end

	if diveRecovering then
		hum.WalkSpeed = 4
		syncStateToServer("Dive")
		return
	end

	-- Velocidad normal según estado
	local targetSpeed = MovementConfig.WalkSpeed
	local nextState: ClientState.MoveState = "Idle"

	if hum.FloorMaterial == Enum.Material.Air then
		nextState = "Jump"
		if ClientState.IsSprinting then
			targetSpeed = MovementConfig.SprintSpeed
		end
	elseif ClientState.IsCrouching then
		targetSpeed = MovementConfig.CrouchSpeed
		nextState = "Crouch"
	elseif ClientState.IsAiming then
		targetSpeed = MovementConfig.AimSpeed
		nextState = "Idle"
	elseif ClientState.IsSprinting and hum.MoveDirection.Magnitude > 0.1 then
		targetSpeed = MovementConfig.SprintSpeed
		nextState = "Sprint"
	end

	hum.WalkSpeed = targetSpeed
	syncStateToServer(nextState)
end)

local function onCharacterAdded(character: Model)
	clearSlideForce()
	isSliding = false
	isDiving = false
	diveRecovering = false
	ClientState.IsCrouching = false
	ClientState.IsSprinting = false
	ClientState.IsAiming = false

	currentCharacter = character
	local hum = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	currentHumanoid = hum
	currentRoot = root
	baseHipHeight = hum.HipHeight
	hum.JumpPower = MovementConfig.JumpPower
	hum.UseJumpPower = true

	hum.Died:Connect(function()
		clearSlideForce()
		isSliding = false
		isDiving = false
		diveRecovering = false
		ClientState.IsFiring = false
		ClientState.IsAiming = false
	end)

	syncStateToServer("Idle")
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
