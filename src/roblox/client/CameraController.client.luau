--!strict
--[=[
	Controlador de cámara fluida y equilibrada (LocalScript en StarterPlayerScripts.Client).
	Lógica:
	- Mantiene la cámara en tercera persona táctica sobre el hombro derecho para
	  poder ver claramente las animaciones de slide, slide-cancel y dive.
	- Interpola suavemente el FOV y el desplazamiento vertical (CameraOffset) según
	  si estás apuntando, corriendo, agachado, deslizando o lanzándote al suelo.
	- Aplica un balanceo sutil al esprintar (casi nulo al caminar o apuntar) y
	  retroceso controlado al disparar la G18, garantizando fluidez sin mareos.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MovementConfig = require(Shared:WaitForChild("MovementConfig"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local localPlayer = Players.LocalPlayer

local currentFOV = MovementConfig.DefaultFOV
local currentOffset = MovementConfig.BaseCameraOffset
local bobPhase = 0

local function getTargets(hum: Humanoid): (number, Vector3)
	local state = ClientState.MoveState

	if ClientState.IsAiming then
		return MovementConfig.AimFOV, MovementConfig.AimCameraOffset
	elseif state == "Slide" then
		return MovementConfig.SlideFOV, MovementConfig.SlideCameraOffset
	elseif state == "Dive" then
		return MovementConfig.DiveFOV, MovementConfig.DiveCameraOffset
	elseif state == "Crouch" then
		return MovementConfig.DefaultFOV - 2, MovementConfig.CrouchCameraOffset
	elseif state == "Sprint" and hum.MoveDirection.Magnitude > 0.1 then
		return MovementConfig.SprintFOV, MovementConfig.BaseCameraOffset
	end

	return MovementConfig.DefaultFOV, MovementConfig.BaseCameraOffset
end

RunService:BindToRenderStep("WarzoneSmoothCamera", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	local camera = workspace.CurrentCamera
	local character = localPlayer.Character
	local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not camera or not hum or hum.Health <= 0 then
		return
	end

	local safeDt = math.min(dt, 0.05)
	local targetFOV, targetOffset = getTargets(hum)

	local fovAlpha = 1 - math.exp(-MovementConfig.CameraFovLerpSpeed * safeDt)
	currentFOV = currentFOV + (targetFOV - currentFOV) * fovAlpha
	camera.FieldOfView = currentFOV

	-- Balanceo sutil solo al correr en suelo (sin exageraciones)
	local bobOffset = Vector3.zero
	if ClientState.MoveState == "Sprint" and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
		bobPhase += safeDt * MovementConfig.CameraBobFrequency
		bobOffset = Vector3.new(
			math.cos(bobPhase * 0.5) * (MovementConfig.CameraBobAmplitude * 0.6),
			math.sin(bobPhase) * MovementConfig.CameraBobAmplitude,
			0
		)
	else
		bobPhase = 0
	end

	local offAlpha = 1 - math.exp(-MovementConfig.CameraOffsetLerpSpeed * safeDt)
	currentOffset = currentOffset:Lerp(targetOffset + bobOffset, offAlpha)
	hum.CameraOffset = currentOffset

	-- Retroceso suave y recuperación de la G18
	if math.abs(ClientState.RecoilPitch) > 0.001 or math.abs(ClientState.RecoilYaw) > 0.001 then
		local recoilFrame = CFrame.Angles(
			math.rad(ClientState.RecoilPitch * 0.28),
			math.rad(ClientState.RecoilYaw * 0.28),
			0
		)
		camera.CFrame = camera.CFrame * recoilFrame

		local decay = math.exp(-14 * safeDt)
		ClientState.RecoilPitch *= decay
		ClientState.RecoilYaw *= decay
	end
end)
