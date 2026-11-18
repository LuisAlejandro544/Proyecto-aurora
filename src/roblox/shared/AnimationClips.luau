--!strict
--[=[
	Librería compilada de animaciones por fotogramas clave (ModuleScript compartido).
	Archivo generado automáticamente por `tools/compile_animations.py` a partir
	del paquete de animaciones (`animations-pack.json`) publicado en GitHub Releases.
	Contiene los clips R15 y R6 para Slide, Dive, Crouch, Jump, Sprint, Aim, ReloadG18 y FireKick.
]=]

export type KeyframeEntry = {
	Time: number,
	Easing: string,
	Bones: { [string]: CFrame },
}

export type AnimationClip = {
	Duration: number,
	Loop: boolean,
	Priority: string,
	FadeIn: number,
	FadeOut: number,
	R15: { KeyframeEntry },
	R6: { KeyframeEntry },
}

local AnimationClips: { [string]: AnimationClip } = {
	Slide = {
		Duration = 0.62,
		Loop = false,
		Priority = "Action",
		FadeIn = 0.08,
		FadeOut = 0.14,
		R15 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					Root = CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(12), math.rad(-4), math.rad(0)),
					Waist = CFrame.Angles(math.rad(-6), math.rad(4), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(25), math.rad(0), math.rad(-2)),
					RightKnee = CFrame.Angles(math.rad(-20), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(15), math.rad(0), math.rad(4)),
					LeftKnee = CFrame.Angles(math.rad(-45), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.11,
				Easing = "CubicOut",
				Bones = {
					Root = CFrame.new(0, -1.25, 0) * CFrame.Angles(math.rad(42), math.rad(-16), math.rad(0)),
					Waist = CFrame.Angles(math.rad(-14), math.rad(16), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(68), math.rad(0), math.rad(-6)),
					RightKnee = CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(26), math.rad(0), math.rad(8)),
					LeftKnee = CFrame.Angles(math.rad(-96), math.rad(0), math.rad(0)),
					LeftShoulder = CFrame.Angles(math.rad(-34), math.rad(0), math.rad(-18)),
					LeftElbow = CFrame.Angles(math.rad(28), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.42,
				Easing = "Linear",
				Bones = {
					Root = CFrame.new(0, -1.22, 0) * CFrame.Angles(math.rad(40), math.rad(-14), math.rad(0)),
					Waist = CFrame.Angles(math.rad(-12), math.rad(14), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(65), math.rad(0), math.rad(-6)),
					RightKnee = CFrame.Angles(math.rad(-12), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(24), math.rad(0), math.rad(8)),
					LeftKnee = CFrame.Angles(math.rad(-94), math.rad(0), math.rad(0)),
					LeftShoulder = CFrame.Angles(math.rad(-30), math.rad(0), math.rad(-16)),
					LeftElbow = CFrame.Angles(math.rad(24), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.62,
				Easing = "QuadInOut",
				Bones = {
					Root = CFrame.new(0, -1.02, 0) * CFrame.Angles(math.rad(-8), math.rad(0), math.rad(0)),
					Waist = CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(58), math.rad(0), math.rad(4)),
					RightKnee = CFrame.Angles(math.rad(-84), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(54), math.rad(0), math.rad(-4)),
					LeftKnee = CFrame.Angles(math.rad(-80), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					RootJoint = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
					["Right Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(28)),
					["Left Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-22)),
				},
			},
			{
				Time = 0.14,
				Easing = "CubicOut",
				Bones = {
					RootJoint = CFrame.new(0, -1.3, 0) * CFrame.Angles(math.rad(42), math.rad(0), math.rad(0)),
					["Right Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(64)),
					["Left Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-48)),
				},
			},
			{
				Time = 0.62,
				Easing = "QuadInOut",
				Bones = {
					RootJoint = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
					["Right Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(46)),
					["Left Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-46)),
				},
			},
				},
	},
	Dive = {
		Duration = 0.75,
		Loop = false,
		Priority = "Action2",
		FadeIn = 0.06,
		FadeOut = 0.16,
		R15 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					Root = CFrame.new(0, -0.25, 0) * CFrame.Angles(math.rad(-28), math.rad(0), math.rad(0)),
					Waist = CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(65), math.rad(0), math.rad(8)),
					LeftShoulder = CFrame.Angles(math.rad(65), math.rad(0), math.rad(-8)),
					RightHip = CFrame.Angles(math.rad(35), math.rad(0), math.rad(4)),
					LeftHip = CFrame.Angles(math.rad(35), math.rad(0), math.rad(-4)),
					RightKnee = CFrame.Angles(math.rad(-55), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-55), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.16,
				Easing = "CubicOut",
				Bones = {
					Root = CFrame.new(0, -1.42, 0) * CFrame.Angles(math.rad(-78), math.rad(0), math.rad(0)),
					Waist = CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
					Neck = CFrame.Angles(math.rad(48), math.rad(0), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(108), math.rad(0), math.rad(10)),
					LeftShoulder = CFrame.Angles(math.rad(108), math.rad(0), math.rad(-10)),
					RightElbow = CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
					LeftElbow = CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(-16), math.rad(0), math.rad(6)),
					LeftHip = CFrame.Angles(math.rad(-16), math.rad(0), math.rad(-6)),
					RightKnee = CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-16), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.5,
				Easing = "Linear",
				Bones = {
					Root = CFrame.new(0, -1.52, 0) * CFrame.Angles(math.rad(-82), math.rad(0), math.rad(0)),
					Waist = CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
					Neck = CFrame.Angles(math.rad(44), math.rad(0), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(96), math.rad(0), math.rad(14)),
					LeftShoulder = CFrame.Angles(math.rad(96), math.rad(0), math.rad(-14)),
					RightElbow = CFrame.Angles(math.rad(36), math.rad(0), math.rad(0)),
					LeftElbow = CFrame.Angles(math.rad(36), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(-10), math.rad(0), math.rad(6)),
					LeftHip = CFrame.Angles(math.rad(-10), math.rad(0), math.rad(-6)),
					RightKnee = CFrame.Angles(math.rad(-24), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-24), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.75,
				Easing = "QuadOut",
				Bones = {
					Root = CFrame.new(0, -1.55, 0) * CFrame.Angles(math.rad(-72), math.rad(0), math.rad(0)),
					Waist = CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
					Neck = CFrame.Angles(math.rad(36), math.rad(0), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(74), math.rad(0), math.rad(16)),
					LeftShoulder = CFrame.Angles(math.rad(74), math.rad(0), math.rad(-16)),
					RightElbow = CFrame.Angles(math.rad(52), math.rad(0), math.rad(0)),
					LeftElbow = CFrame.Angles(math.rad(52), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(8), math.rad(0), math.rad(5)),
					LeftHip = CFrame.Angles(math.rad(8), math.rad(0), math.rad(-5)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					RootJoint = CFrame.new(0, -0.3, 0) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0)),
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(60)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-60)),
				},
			},
			{
				Time = 0.18,
				Easing = "CubicOut",
				Bones = {
					RootJoint = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-76), math.rad(0), math.rad(0)),
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(98)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-98)),
				},
			},
			{
				Time = 0.75,
				Easing = "Linear",
				Bones = {
					RootJoint = CFrame.new(0, -1.55, 0) * CFrame.Angles(math.rad(-74), math.rad(0), math.rad(0)),
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(86)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-86)),
				},
			},
				},
	},
	Crouch = {
		Duration = 0.2,
		Loop = true,
		Priority = "Movement",
		FadeIn = 0.1,
		FadeOut = 0.12,
		R15 = {
			{
				Time = 0,
				Easing = "QuadInOut",
				Bones = {
					Root = CFrame.new(0, -1.05, 0) * CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
					Waist = CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(62), math.rad(0), math.rad(5)),
					LeftHip = CFrame.Angles(math.rad(56), math.rad(0), math.rad(-5)),
					RightKnee = CFrame.Angles(math.rad(-88), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-82), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "QuadInOut",
				Bones = {
					RootJoint = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
					["Right Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(48)),
					["Left Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-48)),
				},
			},
				},
	},
	Jump = {
		Duration = 0.42,
		Loop = false,
		Priority = "Movement",
		FadeIn = 0.06,
		FadeOut = 0.12,
		R15 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					Waist = CFrame.Angles(math.rad(-10), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(32), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
					RightKnee = CFrame.Angles(math.rad(-54), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-28), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.24,
				Easing = "QuadInOut",
				Bones = {
					Waist = CFrame.Angles(math.rad(-6), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
					RightKnee = CFrame.Angles(math.rad(-36), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-22), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.42,
				Easing = "Linear",
				Bones = {
					Waist = CFrame.Angles(math.rad(-4), math.rad(0), math.rad(0)),
					RightHip = CFrame.Angles(math.rad(16), math.rad(0), math.rad(0)),
					LeftHip = CFrame.Angles(math.rad(10), math.rad(0), math.rad(0)),
					RightKnee = CFrame.Angles(math.rad(-26), math.rad(0), math.rad(0)),
					LeftKnee = CFrame.Angles(math.rad(-18), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					["Right Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(24)),
					["Left Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-18)),
				},
			},
			{
				Time = 0.42,
				Easing = "Linear",
				Bones = {
					["Right Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(14)),
					["Left Hip"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-12)),
				},
			},
				},
	},
	Sprint = {
		Duration = 0.4,
		Loop = true,
		Priority = "Movement",
		FadeIn = 0.12,
		FadeOut = 0.12,
		R15 = {
			{
				Time = 0,
				Easing = "QuadInOut",
				Bones = {
					Waist = CFrame.Angles(math.rad(-14), math.rad(3), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(36), math.rad(16), math.rad(-12)),
					RightElbow = CFrame.Angles(math.rad(34), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.2,
				Easing = "QuadInOut",
				Bones = {
					Waist = CFrame.Angles(math.rad(-15), math.rad(-3), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(42), math.rad(20), math.rad(-10)),
					RightElbow = CFrame.Angles(math.rad(38), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.4,
				Easing = "QuadInOut",
				Bones = {
					Waist = CFrame.Angles(math.rad(-14), math.rad(3), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(36), math.rad(16), math.rad(-12)),
					RightElbow = CFrame.Angles(math.rad(34), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "Linear",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(46)),
				},
			},
				},
	},
	EquipG18 = {
		Duration = 0.25,
		Loop = true,
		Priority = "UpperBody",
		FadeIn = 0.08,
		FadeOut = 0.1,
		R15 = {
			{
				Time = 0,
				Easing = "Linear",
				Bones = {
					RightShoulder = CFrame.Angles(math.rad(64), math.rad(8), math.rad(-6)),
					RightElbow = CFrame.Angles(math.rad(18), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "Linear",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(68)),
				},
			},
				},
	},
	Aim = {
		Duration = 0.2,
		Loop = true,
		Priority = "UpperBodyHigh",
		FadeIn = 0.08,
		FadeOut = 0.1,
		R15 = {
			{
				Time = 0,
				Easing = "CubicOut",
				Bones = {
					Neck = CFrame.Angles(math.rad(-4), math.rad(-6), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(84), math.rad(8), math.rad(-4)),
					RightElbow = CFrame.Angles(math.rad(12), math.rad(0), math.rad(0)),
					LeftShoulder = CFrame.Angles(math.rad(74), math.rad(-26), math.rad(16)),
					LeftElbow = CFrame.Angles(math.rad(34), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "CubicOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(86)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(18), math.rad(-72)),
				},
			},
				},
	},
	ReloadG18 = {
		Duration = 1.45,
		Loop = false,
		Priority = "UpperAction",
		FadeIn = 0.08,
		FadeOut = 0.12,
		R15 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					RightShoulder = CFrame.Angles(math.rad(78), math.rad(8), math.rad(-6)),
					RightElbow = CFrame.Angles(math.rad(22), math.rad(0), math.rad(0)),
					LeftShoulder = CFrame.Angles(math.rad(64), math.rad(-18), math.rad(12)),
					LeftElbow = CFrame.Angles(math.rad(32), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.22,
				Easing = "CubicOut",
				Bones = {
					Neck = CFrame.Angles(math.rad(-10), math.rad(-8), math.rad(4)),
					RightShoulder = CFrame.Angles(math.rad(68), math.rad(-18), math.rad(14)),
					RightElbow = CFrame.Angles(math.rad(42), math.rad(0), math.rad(0)),
					RightWrist = CFrame.Angles(math.rad(0), math.rad(0), math.rad(18)),
					LeftShoulder = CFrame.Angles(math.rad(24), math.rad(10), math.rad(-14)),
					LeftElbow = CFrame.Angles(math.rad(48), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.48,
				Easing = "QuadInOut",
				Bones = {
					Neck = CFrame.Angles(math.rad(-12), math.rad(-6), math.rad(4)),
					RightShoulder = CFrame.Angles(math.rad(72), math.rad(-16), math.rad(12)),
					RightElbow = CFrame.Angles(math.rad(46), math.rad(0), math.rad(0)),
					RightWrist = CFrame.Angles(math.rad(-8), math.rad(0), math.rad(16)),
					LeftShoulder = CFrame.Angles(math.rad(8), math.rad(16), math.rad(-22)),
					LeftElbow = CFrame.Angles(math.rad(28), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.84,
				Easing = "BackOut",
				Bones = {
					Neck = CFrame.Angles(math.rad(-8), math.rad(-8), math.rad(2)),
					RightShoulder = CFrame.Angles(math.rad(66), math.rad(-14), math.rad(10)),
					RightElbow = CFrame.Angles(math.rad(44), math.rad(0), math.rad(0)),
					RightWrist = CFrame.Angles(math.rad(4), math.rad(0), math.rad(14)),
					LeftShoulder = CFrame.Angles(math.rad(58), math.rad(-16), math.rad(14)),
					LeftElbow = CFrame.Angles(math.rad(52), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 1.12,
				Easing = "CubicOut",
				Bones = {
					Neck = CFrame.Angles(math.rad(-6), math.rad(-4), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(74), math.rad(-8), math.rad(4)),
					RightElbow = CFrame.Angles(math.rad(32), math.rad(0), math.rad(0)),
					RightWrist = CFrame.Angles(math.rad(8), math.rad(0), math.rad(6)),
					LeftShoulder = CFrame.Angles(math.rad(72), math.rad(-24), math.rad(18)),
					LeftElbow = CFrame.Angles(math.rad(68), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 1.45,
				Easing = "QuadInOut",
				Bones = {
					Neck = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
					RightShoulder = CFrame.Angles(math.rad(82), math.rad(8), math.rad(-6)),
					RightElbow = CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
					RightWrist = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
					LeftShoulder = CFrame.Angles(math.rad(70), math.rad(-22), math.rad(14)),
					LeftElbow = CFrame.Angles(math.rad(30), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "QuadOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(78)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-56)),
				},
			},
			{
				Time = 0.35,
				Easing = "CubicOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(-15), math.rad(0), math.rad(64)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-18)),
				},
			},
			{
				Time = 0.85,
				Easing = "BackOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(-10), math.rad(0), math.rad(68)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(14), math.rad(-64)),
				},
			},
			{
				Time = 1.45,
				Easing = "QuadInOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(82)),
					["Left Shoulder"] = CFrame.Angles(math.rad(0), math.rad(14), math.rad(-70)),
				},
			},
				},
	},
	FireKick = {
		Duration = 0.09,
		Loop = false,
		Priority = "Recoil",
		FadeIn = 0.01,
		FadeOut = 0.05,
		R15 = {
			{
				Time = 0,
				Easing = "CubicOut",
				Bones = {
					RightShoulder = CFrame.Angles(math.rad(92), math.rad(8), math.rad(-4)),
					RightWrist = CFrame.Angles(math.rad(14), math.rad(0), math.rad(0)),
				},
			},
			{
				Time = 0.09,
				Easing = "QuadOut",
				Bones = {
					RightShoulder = CFrame.Angles(math.rad(82), math.rad(8), math.rad(-6)),
					RightWrist = CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),
				},
			},
				},
		R6 = {
			{
				Time = 0,
				Easing = "CubicOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(94)),
				},
			},
			{
				Time = 0.09,
				Easing = "QuadOut",
				Bones = {
					["Right Shoulder"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(82)),
				},
			},
				},
	},
}

return AnimationClips
