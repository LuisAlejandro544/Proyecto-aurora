--!strict
--[=[
	Estadísticas de la pistola automática G18 (ModuleScript compartido).
	Define cadencia, cargador de 33 balas, dispersión, retroceso controlado
	y la tabla de daño anatómico por zona corporal (cabeza, pecho, brazos,
	manos, piernas y pies) compatible con avatares R15 y R6.
]=]

export type HitZone = "Head" | "Chest" | "Arm" | "Hand" | "Leg" | "Foot"

local WeaponStats = {
	G18 = {
		DisplayName = "G18 Táctica",
		FireMode = "Auto",
		FireRate = 0.068, -- ~880 RPM (automática rápida)
		MagazineSize = 33,
		ReloadTime = 1.45,
		DamageByZone = {
			Head = 34, -- Cabeza
			Chest = 22, -- Pecho / Torso
			Arm = 16, -- Brazos
			Hand = 12, -- Manos
			Leg = 15, -- Piernas
			Foot = 10, -- Pies
		},
		MaxRange = 260,
		HipSpreadDeg = 2.4,
		AimSpreadDeg = 0.75,
		CrouchSpreadMultiplier = 0.72,
		RecoilPitchDeg = 0.85,
		RecoilYawDeg = 0.35,
		MuzzleFlashDuration = 0.045,
	},
}

local PART_TO_ZONE: { [string]: HitZone } = {
	Head = "Head",

	-- Pecho / Torso (R15 y R6)
	UpperTorso = "Chest",
	LowerTorso = "Chest",
	Torso = "Chest",
	HumanoidRootPart = "Chest",

	-- Brazos (R15 y R6)
	LeftUpperArm = "Arm",
	LeftLowerArm = "Arm",
	RightUpperArm = "Arm",
	RightLowerArm = "Arm",
	["Left Arm"] = "Arm",
	["Right Arm"] = "Arm",

	-- Manos (R15)
	LeftHand = "Hand",
	RightHand = "Hand",

	-- Piernas (R15 y R6)
	LeftUpperLeg = "Leg",
	LeftLowerLeg = "Leg",
	RightUpperLeg = "Leg",
	RightLowerLeg = "Leg",
	["Left Leg"] = "Leg",
	["Right Leg"] = "Leg",

	-- Pies (R15)
	LeftFoot = "Foot",
	RightFoot = "Foot",
}

function WeaponStats.ResolveHitDamage(weaponName: string, partName: string): (number, HitZone)
	local weapon = (WeaponStats :: { [string]: any })[weaponName] or WeaponStats.G18
	local zone: HitZone = PART_TO_ZONE[partName] or "Chest"
	local dmg = weapon.DamageByZone[zone] or weapon.DamageByZone.Chest
	return dmg, zone
end

return WeaponStats
