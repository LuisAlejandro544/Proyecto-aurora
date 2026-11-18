--!strict
--[=[
	Estado compartido en el cliente (ModuleScript en StarterPlayerScripts.Client).
	Lógica: Conecta de forma modular los controladores de movimiento, cámara,
	arma G18 y botones táctiles de la pantalla sin crear dependencias circulares.
]=]

local WeaponStats = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("WeaponStats"))

export type MoveState = "Idle" | "Sprint" | "Crouch" | "Slide" | "Dive" | "Jump"

local ClientState = {
	MoveState = "Idle" :: MoveState,
	IsSprinting = false,
	IsCrouching = false,
	IsAiming = false,
	IsFiring = false,
	IsReloading = false,
	IsWeaponEquipped = false,

	Ammo = WeaponStats.G18.MagazineSize,
	MaxAmmo = WeaponStats.G18.MagazineSize,

	-- Retroceso acumulado de la cámara (la cámara lo consume y suaviza cada frame)
	RecoilPitch = 0,
	RecoilYaw = 0,

	-- Callbacks registrados por los controladores para que TouchHUD los invoque
	OnToggleSprint = nil :: (() -> ())?,
	OnCrouchOrSlide = nil :: (() -> ())?,
	OnJumpOrCancel = nil :: (() -> ())?,
	OnDive = nil :: (() -> ())?,
	OnReload = nil :: (() -> ())?,
	OnHitConfirm = nil :: ((isHeadshot: boolean) -> ())?,
}

function ClientState.AddCameraRecoil(pitchDeg: number, yawDeg: number)
	ClientState.RecoilPitch = math.clamp(ClientState.RecoilPitch + pitchDeg, -12, 12)
	ClientState.RecoilYaw = math.clamp(ClientState.RecoilYaw + yawDeg, -8, 8)
end

return ClientState
