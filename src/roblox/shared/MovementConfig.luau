--!strict
--[=[
	Parámetros de movimiento tipo Warzone y cámara suave (ModuleScript compartido).
	Centraliza velocidades, tiempos de deslizar (slide), cancelación (slide cancel),
	lanzamiento al suelo (dolphin dive) y límites suaves de cámara para evitar mareos.
]=]

local MovementConfig = {
	-- Velocidades de desplazamiento
	WalkSpeed = 16,
	SprintSpeed = 24,
	CrouchSpeed = 10.5,
	AimSpeed = 12,
	JumpPower = 50,

	-- Deslizamiento (Slide) y Slide Cancel
	SlideInitialSpeed = 38,
	SlideEndSpeed = 14,
	SlideDuration = 0.62,
	SlideCooldown = 0.25,
	SlideCancelJumpBoost = 52, -- Impulso limpio al cancelar deslizar con salto

	-- Lanzarse al suelo (Dolphin Dive)
	DiveHorizontalSpeed = 34,
	DiveVerticalBoost = 20,
	DiveMaxAirTime = 0.90,
	DiveRecoveryTime = 0.35, -- Breve pausa en el suelo tras caer del dive
	DiveCooldown = 0.60,

	-- Cámara fluida (controlada, sin sacudidas excesivas)
	DefaultFOV = 72,
	SprintFOV = 79,
	SlideFOV = 82,
	DiveFOV = 81,
	AimFOV = 56,

	BaseCameraOffset = Vector3.new(1.55, 0.45, 0),
	CrouchCameraOffset = Vector3.new(1.55, -1.05, 0),
	SlideCameraOffset = Vector3.new(1.65, -1.45, 0),
	DiveCameraOffset = Vector3.new(1.55, -1.95, 0),
	AimCameraOffset = Vector3.new(1.85, 0.45, 0),

	CameraFovLerpSpeed = 10,
	CameraOffsetLerpSpeed = 12,
	CameraBobAmplitude = 0.08, -- Muy sutil al correr para mantener fluidez sin mareo
	CameraBobFrequency = 9.5,
}

return MovementConfig
