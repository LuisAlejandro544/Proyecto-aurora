--!strict
--[=[
	Servicio de caída realista tipo Ragdoll al morir (ModuleScript en ServerScriptService.Server).
	Lógica:
	- Evita que el avatar se desarme en piezas sueltas (BreakJointsOnDeath = false).
	- Convierte cada Motor6D en un BallSocketConstraint con límites anatómicos reales
	  (cuello, cintura, hombros, codos, caderas, rodillas, muñecas y tobillos).
	- Añade NoCollisionConstraint entre partes conectadas para evitar temblores físicos,
	  activa colisión en extremidades/torso y desactiva colisión en HumanoidRootPart.
	- Aplica un impulso sutil en la dirección del último impacto para que el cuerpo
	  caiga de manera natural sobre el asfalto, rampas o coberturas.
]=]

local RagdollService = {}

local JOINT_LIMITS: { [string]: { Upper: number, TwistMin: number, TwistMax: number } } = {
	Neck = { Upper = 38, TwistMin = -35, TwistMax = 35 },
	Waist = { Upper = 35, TwistMin = -25, TwistMax = 25 },
	RightShoulder = { Upper = 75, TwistMin = -45, TwistMax = 45 },
	LeftShoulder = { Upper = 75, TwistMin = -45, TwistMax = 45 },
	RightElbow = { Upper = 55, TwistMin = -15, TwistMax = 15 },
	LeftElbow = { Upper = 55, TwistMin = -15, TwistMax = 15 },
	RightWrist = { Upper = 30, TwistMin = -20, TwistMax = 20 },
	LeftWrist = { Upper = 30, TwistMin = -20, TwistMax = 20 },
	RightHip = { Upper = 65, TwistMin = -30, TwistMax = 30 },
	LeftHip = { Upper = 65, TwistMin = -30, TwistMax = 30 },
	RightKnee = { Upper = 60, TwistMin = -10, TwistMax = 10 },
	LeftKnee = { Upper = 60, TwistMin = -10, TwistMax = 10 },
	RightAnkle = { Upper = 28, TwistMin = -15, TwistMax = 15 },
	LeftAnkle = { Upper = 28, TwistMin = -15, TwistMax = 15 },
}

function RagdollService.PrepareCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.BreakJointsOnDeath = false
	end

	-- Evitar que sombreros/accesorios bloqueen balas dirigidas a la cabeza o torso
	for _, desc in character:GetDescendants() do
		if desc:IsA("Accessory") then
			for _, child in desc:GetDescendants() do
				if child:IsA("BasePart") then
					child.CanQuery = false
					child.CanCollide = false
				end
			end
		end
	end
end

function RagdollService.ApplyRagdoll(character: Model, hitDirection: Vector3?)
	if character:GetAttribute("IsRagdolled") then
		return
	end
	character:SetAttribute("IsRagdolled", true)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if humanoid then
		humanoid.BreakJointsOnDeath = false
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	end

	-- Desactivar fuerzas temporales (como LinearVelocity del Slide) si existieran
	for _, desc in character:GetDescendants() do
		if desc:IsA("LinearVelocity") or desc:IsA("BodyVelocity") then
			desc:Destroy()
		end
	end

	-- Convertir Motor6D a BallSocketConstraint manteniendo todas las partes unidas
	for _, desc in character:GetDescendants() do
		if desc:IsA("Motor6D") then
			local part0 = desc.Part0
			local part1 = desc.Part1

			-- Mantener Root / RootJoint unido al HumanoidRootPart sin soltar el cuerpo,
			-- o desactivarlo solo si hay torso separado con colisión propia
			if desc.Name == "Root" or desc.Name == "RootJoint" then
				desc.Enabled = false
				continue
			end

			if part0 and part1 then
				local att0 = Instance.new("Attachment")
				att0.Name = "RagdollAtt0_" .. desc.Name
				att0.CFrame = desc.C0
				att0.Parent = part0

				local att1 = Instance.new("Attachment")
				att1.Name = "RagdollAtt1_" .. desc.Name
				att1.CFrame = desc.C1
				att1.Parent = part1

				local limits = JOINT_LIMITS[desc.Name]
				local socket = Instance.new("BallSocketConstraint")
				socket.Name = "RagdollSocket_" .. desc.Name
				socket.Attachment0 = att0
				socket.Attachment1 = att1
				socket.LimitsEnabled = true
				socket.UpperAngle = if limits then limits.Upper else 55
				socket.TwistLimitsEnabled = true
				socket.TwistLowerAngle = if limits then limits.TwistMin else -30
				socket.TwistUpperAngle = if limits then limits.TwistMax else 30
				socket.Restitution = 0.05
				socket.Parent = part0

				local noCol = Instance.new("NoCollisionConstraint")
				noCol.Name = "RagdollNoCol_" .. desc.Name
				noCol.Part0 = part0
				noCol.Part1 = part1
				noCol.Parent = part0

				desc.Enabled = false
			end
		end
	end

	-- Ajustar colisiones del cuerpo para que caiga naturalmente sobre el suelo
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			if desc == root then
				desc.CanCollide = false
				desc.Massless = true
			elseif desc:FindFirstAncestorOfClass("Tool") or desc:FindFirstAncestorOfClass("Accessory") then
				desc.CanCollide = false
			else
				desc.CanCollide = true
			end
		end
	end

	-- Impulso realista de caída según la dirección del disparo fatal
	local torso = character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("LowerTorso")
	if torso and torso:IsA("BasePart") then
		-- Redirigir propiedad física al servidor para evitar congelamientos
		pcall(function()
			torso:SetNetworkOwner(nil)
		end)

		local dir = if hitDirection and hitDirection.Magnitude > 0.05
			then Vector3.new(hitDirection.X, 0, hitDirection.Z).Unit
			else (torso.CFrame.LookVector * -1)
		local fallVelocity = dir * 11 + Vector3.new(0, 3.5, 0)
		torso.AssemblyLinearVelocity = fallVelocity
		torso.AssemblyAngularVelocity = Vector3.new(
			(math.random() - 0.5) * 4,
			(math.random() - 0.5) * 3,
			(math.random() - 0.5) * 4
		)
	end
end

return RagdollService
