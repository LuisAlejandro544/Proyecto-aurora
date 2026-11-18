--!strict
--[=[
	Reproductor de animaciones por fotogramas clave (LocalScript en StarterPlayerScripts.Client).
	Lógica:
	- Reemplaza las animaciones procedurales por un sistema de clips con keyframes
	  compilados en `ReplicatedStorage.Shared.AnimationClips` (desde GitHub Releases).
	- Interpola entre fotogramas con curvas de suavizado (Linear, Quad, Cubic, Back)
	  y aplica las poses sobre `Motor6D.Transform`, manteniendo intacto el `Animate`
	  nativo de Roblox cuando no hay override y respetando la caída Ragdoll al morir.
	- Soporta capas: cuerpo completo (Slide, Dive, Crouch, Jump, Sprint) y tren superior
	  para arma/combate (EquipG18, Aim, ReloadG18, FireKick).
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnimationClips = require(Shared:WaitForChild("AnimationClips"))

type JointMap = { [string]: Motor6D }

type TrackState = {
	ClipName: string,
	StartTime: number,
	Weight: number,
	TargetWeight: number,
}

type CharacterTrackRig = {
	Joints: JointMap,
	IsR15: boolean,
	BaseTrack: TrackState?,
	UpperTrack: TrackState?,
	ActionTrack: TrackState?,
	LastShotStamp: number,
	WasReloading: boolean,
}

local trackedRigs: { [Model]: CharacterTrackRig } = {}

local function applyEasing(easingName: string, alpha: number): number
	local t = math.clamp(alpha, 0, 1)
	if easingName == "QuadOut" then
		return 1 - (1 - t) * (1 - t)
	elseif easingName == "QuadInOut" then
		return if t < 0.5 then 2 * t * t else 1 - ((-2 * t + 2) ^ 2) / 2
	elseif easingName == "CubicOut" then
		return 1 - (1 - t) ^ 3
	elseif easingName == "BackOut" then
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * ((t - 1) ^ 3) + c1 * ((t - 1) ^ 2)
	end
	return t
end

local function sampleClip(clip: AnimationClips.AnimationClip, isR15: boolean, elapsed: number): { [string]: CFrame }
	local frames = if isR15 then clip.R15 else clip.R6
	local count = #frames
	if count == 0 then
		return {}
	end
	if count == 1 then
		return frames[1].Bones
	end

	local t = elapsed
	if clip.Loop and clip.Duration > 0 then
		t = elapsed % clip.Duration
	else
		t = math.clamp(elapsed, 0, clip.Duration)
	end

	local frameA = frames[1]
	local frameB = frames[count]
	for i = 1, count - 1 do
		if t >= frames[i].Time and t <= frames[i + 1].Time then
			frameA = frames[i]
			frameB = frames[i + 1]
			break
		end
	end

	if frameA == frameB or (frameB.Time - frameA.Time) <= 0.0001 then
		return frameB.Bones
	end

	local span = frameB.Time - frameA.Time
	local rawAlpha = (t - frameA.Time) / span
	local eased = applyEasing(frameB.Easing, rawAlpha)

	local result: { [string]: CFrame } = {}
	for boneName, cfA in frameA.Bones do
		local cfB = frameB.Bones[boneName]
		if cfB then
			result[boneName] = cfA:Lerp(cfB, eased)
		else
			result[boneName] = cfA:Lerp(CFrame.identity, eased)
		end
	end
	for boneName, cfB in frameB.Bones do
		if not result[boneName] then
			result[boneName] = CFrame.identity:Lerp(cfB, eased)
		end
	end

	return result
end

local function registerCharacter(character: Model)
	task.wait(0.15)
	if not character.Parent then
		return
	end

	local joints: JointMap = {}
	local isR15 = false

	for _, desc in character:GetDescendants() do
		if desc:IsA("Motor6D") then
			joints[desc.Name] = desc
			if desc.Name == "LowerTorso" or desc.Name == "Waist" or desc.Name == "RightKnee" then
				isR15 = true
			end
		end
	end

	trackedRigs[character] = {
		Joints = joints,
		IsR15 = isR15,
		BaseTrack = nil,
		UpperTrack = nil,
		ActionTrack = nil,
		LastShotStamp = 0,
		WasReloading = false,
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

-- Detectar también el Bot de combate en Workspace para reproducir sus keyframes
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:GetAttribute("IsBot") == true then
		task.spawn(registerCharacter, child)
	end
end)

local function setTrack(current: TrackState?, desiredClip: string?, now: number): TrackState?
	if not desiredClip then
		if current then
			current.TargetWeight = 0
		end
		return current
	end

	if not current or current.ClipName ~= desiredClip then
		return {
			ClipName = desiredClip,
			StartTime = now,
			Weight = 0.05,
			TargetWeight = 1,
		}
	end

	current.TargetWeight = 1
	return current
end

local function advanceAndBlend(
	track: TrackState?,
	rig: CharacterTrackRig,
	now: number,
	dt: number,
	poseAccum: { [string]: { CF: CFrame, Weight: number } }
): TrackState?
	if not track then
		return nil
	end

	local clip = AnimationClips[track.ClipName]
	if not clip then
		return nil
	end

	local elapsed = now - track.StartTime
	if not clip.Loop and elapsed >= clip.Duration then
		track.TargetWeight = 0
	end

	local fadeSpeed = if track.TargetWeight > track.Weight
		then (1 / math.max(0.02, clip.FadeIn))
		else (1 / math.max(0.02, clip.FadeOut))

	if track.Weight < track.TargetWeight then
		track.Weight = math.min(track.TargetWeight, track.Weight + fadeSpeed * dt)
	elseif track.Weight > track.TargetWeight then
		track.Weight = math.max(track.TargetWeight, track.Weight - fadeSpeed * dt)
	end

	if track.Weight <= 0.005 and track.TargetWeight == 0 then
		return nil
	end

	local sampled = sampleClip(clip, rig.IsR15, elapsed)
	for boneName, boneCF in sampled do
		local prev = poseAccum[boneName]
		if prev then
			prev.CF = prev.CF:Lerp(boneCF, track.Weight)
			prev.Weight = math.max(prev.Weight, track.Weight)
		else
			poseAccum[boneName] = { CF = boneCF, Weight = track.Weight }
		end
	end

	return track
end

RunService:BindToRenderStep("WarzoneKeyframeAnimator", Enum.RenderPriority.Character.Value + 1, function(dt: number)
	local now = os.clock()
	local safeDt = math.min(dt, 0.05)

	for character, rig in trackedRigs do
		if not character.Parent then
			continue
		end

		local hum = character:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 or character:GetAttribute("IsRagdolled") == true then
			continue
		end

		local state = (character:GetAttribute("MoveState") :: string?) or "Idle"
		local isAiming = character:GetAttribute("IsAiming") == true
		local hasTool = character:FindFirstChildOfClass("Tool") ~= nil
		local isReloading = character:GetAttribute("IsReloading") == true
		local shotStampAttr = character:GetAttribute("LastShotClock")
		local shotStamp = if typeof(shotStampAttr) == "number" then shotStampAttr else 0

		-- Capa 1: Locomoción especial por keyframes (Idle/Walk normal quedan al Animate nativo)
		local desiredBase: string? = nil
		if state == "Slide" or state == "Dive" or state == "Crouch" or state == "Jump" or state == "Sprint" then
			desiredBase = state
		end
		rig.BaseTrack = setTrack(rig.BaseTrack, desiredBase, now)

		-- Capa 2: Tren superior con la G18
		local desiredUpper: string? = nil
		if isReloading then
			desiredUpper = "ReloadG18"
		elseif isAiming and state ~= "Dive" then
			desiredUpper = "Aim"
		elseif hasTool and state ~= "Dive" then
			desiredUpper = "EquipG18"
		end

		if desiredUpper == "ReloadG18" then
			if not rig.WasReloading then
				rig.UpperTrack = setTrack(nil, "ReloadG18", now)
			end
			rig.WasReloading = true
		else
			rig.WasReloading = false
			rig.UpperTrack = setTrack(rig.UpperTrack, desiredUpper, now)
		end

		-- Capa 3: Retroceso corto por disparo
		if shotStamp > rig.LastShotStamp then
			rig.LastShotStamp = shotStamp
			if not isReloading and state ~= "Dive" then
				rig.ActionTrack = setTrack(nil, "FireKick", now)
			end
		end

		local poseAccum: { [string]: { CF: CFrame, Weight: number } } = {}
		rig.BaseTrack = advanceAndBlend(rig.BaseTrack, rig, now, safeDt, poseAccum)
		rig.UpperTrack = advanceAndBlend(rig.UpperTrack, rig, now, safeDt, poseAccum)
		rig.ActionTrack = advanceAndBlend(rig.ActionTrack, rig, now, safeDt, poseAccum)

		for boneName, poseData in poseAccum do
			local motor = rig.Joints[boneName]
			if motor and motor.Parent and motor.Enabled then
				motor.Transform = motor.Transform:Lerp(poseData.CF, poseData.Weight)
			end
		end
	end
end)
