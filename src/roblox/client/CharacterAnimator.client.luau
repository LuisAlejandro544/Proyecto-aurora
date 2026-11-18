--!strict
--[=[
	Animador procedural del personaje (LocalScript en StarterPlayerScripts.Client).
	Lógica: Anima directamente las articulaciones Motor6D de cada personaje (R15 y R6)
	sin depender de IDs externos de Roblox Studio:
	- Slide: torso inclinado hacia atrás, pierna derecha extendida y rodilla izquierda doblada.
	- Dive (lanzarse al suelo): cuerpo horizontal boca abajo, brazos al frente y piernas atrás.
	- Crouch: cadera baja y rodillas flexionadas.
	- Jump / Slide Cancel: transición rápida erguida con rodillas recogidas en el aire.
	- Apuntado G18: hombro derecho levantado hacia el frente.
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

type JointEntry = {
	Motor: Motor6D,
	BaseC0: CFrame,
	CurrentOffset: CFrame,
}

type CharacterRig = {
	Joints: { [string]: JointEntry },
	IsR15: boolean,
}

local trackedRigs: { [Model]: CharacterRig } = {}

local function registerCharacter(character: Model)
	local joints: { [string]: JointEntry } = {}
	local isR15 = false

	-- Esperar brevemente a que carguen las partes del avatar
	task.wait(0.15)
	if not character.Parent then
		return
	end

	for _, desc in character:GetDescendants() do
		if desc:IsA("Motor6D") then
			joints[desc.Name] = {
				Motor = desc,
				BaseC0 = desc.C0,
				CurrentOffset = CFrame.identity,
			}
			if desc.Name == "LowerTorso" or desc.Name == "Waist" or desc.Name == "RightKnee" then
				isR15 = true
			end
		end
	end

	trackedRigs[character] = {
		Joints = joints,
		IsR15 = isR15,
	}

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			trackedRigs[character] = nil
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(registerCharacter)
	if player.Character then
		task.spawn(registerCharacter, player.Character)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do
	setupPlayer(p)
end

local function getTargetOffsets(rig: CharacterRig, state: string, isAiming: boolean, hasTool: boolean): { [string]: CFrame }
	local targets: { [string]: CFrame } = {}

	if rig.IsR15 then
		if state == "Slide" then
			targets.Root = CFrame.new(0, -1.25, 0) * CFrame.Angles(math.rad(42), math.rad(-14), 0)
			targets.Waist = CFrame.Angles(math.rad(-12), math.rad(14), 0)
			targets.RightHip = CFrame.Angles(math.rad(65), 0, math.rad(-6))
			targets.RightKnee = CFrame.Angles(math.rad(-12), 0, 0)
			targets.LeftHip = CFrame.Angles(math.rad(25), 0, math.rad(8))
			targets.LeftKnee = CFrame.Angles(math.rad(-95), 0, 0)
			targets.LeftShoulder = CFrame.Angles(math.rad(-35), 0, math.rad(-18))
		elseif state == "Dive" then
			targets.Root = CFrame.new(0, -1.45, 0) * CFrame.Angles(math.rad(-76), 0, 0)
			targets.Waist = CFrame.Angles(math.rad(14), 0, 0)
			targets.Neck = CFrame.Angles(math.rad(48), 0, 0)
			targets.RightShoulder = CFrame.Angles(math.rad(105), 0, math.rad(10))
			targets.LeftShoulder = CFrame.Angles(math.rad(105), 0, math.rad(-10))
			targets.RightHip = CFrame.Angles(math.rad(-15), 0, math.rad(6))
			targets.LeftHip = CFrame.Angles(math.rad(-15), 0, math.rad(-6))
			targets.RightKnee = CFrame.Angles(math.rad(-18), 0, 0)
			targets.LeftKnee = CFrame.Angles(math.rad(-18), 0, 0)
		elseif state == "Crouch" then
			targets.Root = CFrame.new(0, -1.05, 0) * CFrame.Angles(math.rad(-10), 0, 0)
			targets.Waist = CFrame.Angles(math.rad(12), 0, 0)
			targets.RightHip = CFrame.Angles(math.rad(62), 0, math.rad(5))
			targets.LeftHip = CFrame.Angles(math.rad(56), 0, math.rad(-5))
			targets.RightKnee = CFrame.Angles(math.rad(-88), 0, 0)
			targets.LeftKnee = CFrame.Angles(math.rad(-82), 0, 0)
		elseif state == "Jump" then
			targets.Waist = CFrame.Angles(math.rad(-8), 0, 0)
			targets.RightHip = CFrame.Angles(math.rad(26), 0, 0)
			targets.LeftHip = CFrame.Angles(math.rad(16), 0, 0)
			targets.RightKnee = CFrame.Angles(math.rad(-42), 0, 0)
			targets.LeftKnee = CFrame.Angles(math.rad(-24), 0, 0)
		elseif state == "Sprint" then
			targets.Waist = CFrame.Angles(math.rad(-14), 0, 0)
			if not isAiming then
				targets.RightShoulder = CFrame.Angles(math.rad(38), math.rad(18), math.rad(-12))
			end
		end

		if (isAiming or hasTool) and state ~= "Dive" then
			local pitch = if isAiming then 82 else 64
			targets.RightShoulder = CFrame.Angles(math.rad(pitch), math.rad(8), math.rad(-6))
			if isAiming then
				targets.LeftShoulder = CFrame.Angles(math.rad(72), math.rad(-26), math.rad(16))
			end
		end
	else
		-- Compatibilidad completa con avatares R6
		if state == "Slide" then
			targets.RootJoint = CFrame.new(0, -1.3, 0) * CFrame.Angles(math.rad(42), 0, 0)
			targets["Right Hip"] = CFrame.Angles(0, 0, math.rad(62))
			targets["Left Hip"] = CFrame.Angles(0, 0, math.rad(-48))
		elseif state == "Dive" then
			targets.RootJoint = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-76), 0, 0)
			targets["Right Shoulder"] = CFrame.Angles(0, 0, math.rad(98))
			targets["Left Shoulder"] = CFrame.Angles(0, 0, math.rad(-98))
		elseif state == "Crouch" then
			targets.RootJoint = CFrame.new(0, -1.0, 0)
			targets["Right Hip"] = CFrame.Angles(0, 0, math.rad(48))
			targets["Left Hip"] = CFrame.Angles(0, 0, math.rad(-48))
		end

		if (isAiming or hasTool) and state ~= "Dive" then
			targets["Right Shoulder"] = CFrame.Angles(0, 0, math.rad(82))
		end
	end

	return targets
end

RunService:BindToRenderStep("WarzoneProceduralAnim", Enum.RenderPriority.Character.Value + 1, function(dt: number)
	local safeDt = math.min(dt, 0.05)

	for character, rig in trackedRigs do
		if not character.Parent then
			continue
		end

		local state = (character:GetAttribute("MoveState") :: string?) or "Idle"
		local isAiming = character:GetAttribute("IsAiming") == true
		local hasTool = character:FindFirstChildOfClass("Tool") ~= nil

		local targets = getTargetOffsets(rig, state, isAiming, hasTool)
		local speed = if state == "Jump" or state == "Dive" then 18 else 14
		local alpha = 1 - math.exp(-speed * safeDt)

		for jointName, entry in rig.Joints do
			if entry.Motor.Parent then
				local targetOffset = targets[jointName] or CFrame.identity
				entry.CurrentOffset = entry.CurrentOffset:Lerp(targetOffset, alpha)
				entry.Motor.C0 = entry.BaseC0 * entry.CurrentOffset
			end
		end
	end
end)
