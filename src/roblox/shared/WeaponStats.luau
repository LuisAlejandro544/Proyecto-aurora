--!strict
--[=[
	Estadísticas de la pistola automática G18 (ModuleScript compartido).
	Define cadencia, daño, cargador de 33 balas, dispersión y retroceso controlado.
]=]

local WeaponStats = {
	G18 = {
		DisplayName = "G18 Táctica",
		FireMode = "Auto",
		FireRate = 0.068, -- ~880 RPM (automática rápida)
		MagazineSize = 33,
		ReloadTime = 1.45,
		DamageBody = 20,
		DamageHead = 34,
		MaxRange = 260,
		HipSpreadDeg = 2.4,
		AimSpreadDeg = 0.75,
		CrouchSpreadMultiplier = 0.72,
		RecoilPitchDeg = 0.85,
		RecoilYawDeg = 0.35,
		MuzzleFlashDuration = 0.045,
	},
}

return WeaponStats
