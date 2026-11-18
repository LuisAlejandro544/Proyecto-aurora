--!strict
--[=[
	Interfaz táctica y botones táctiles para celular (LocalScript en StarterPlayerScripts.Client).
	Lógica:
	- Crea una retícula dinámica en el centro y un Hitmarker al impactar al rival.
	- Muestra el marcador 1v1 arriba, la barra de salud y munición de la G18 abajo.
	- Incluye botones táctiles grandes y cómodos para jugar 100% desde el teléfono:
	  DISPARAR (mantener), APUNTAR (toggle), RECARGAR, SPRINT, DESLIZAR, SALTAR y LANZARSE.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScoreUpdateEvent = Remotes:WaitForChild("ScoreUpdateEvent") :: RemoteEvent

local ClientState = require(script.Parent:WaitForChild("ClientState"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("WarzoneHUD")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "WarzoneHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- ============================================================================
-- 1. MARCADOR SUPERIOR 1v1 Y ESTADO DE MOVIMIENTO
-- ============================================================================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.fromOffset(290, 44)
topBar.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
topBar.BackgroundTransparency = 0.25
topBar.BorderSizePixel = 0
topBar.Parent = gui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(1, -16, 0.55, 0)
scoreLabel.Position = UDim2.fromOffset(8, 2)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 14
scoreLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
scoreLabel.Text = "1v1 RUINAS  |  Bajas: 0"
scoreLabel.Parent = topBar

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(1, -16, 0.4, 0)
stateLabel.Position = UDim2.new(0, 8, 0.55, 0)
stateLabel.BackgroundTransparency = 1
stateLabel.Font = Enum.Font.GothamMedium
stateLabel.TextSize = 11
stateLabel.TextColor3 = Color3.fromRGB(185, 200, 215)
stateLabel.Text = "ESTADO: LISTO"
stateLabel.Parent = topBar

-- ============================================================================
-- 2. RETÍCULA DINÁMICA Y HITMARKER
-- ============================================================================
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(4, 4)
crosshair.BackgroundTransparency = 1
crosshair.Parent = gui

local function makeTick(name: string): Frame
	local tick = Instance.new("Frame")
	tick.Name = name
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
	tick.BorderSizePixel = 0
	tick.Parent = crosshair
	return tick
end

local tickTop = makeTick("Top")
tickTop.Size = UDim2.fromOffset(2, 8)
local tickBottom = makeTick("Bottom")
tickBottom.Size = UDim2.fromOffset(2, 8)
local tickLeft = makeTick("Left")
tickLeft.Size = UDim2.fromOffset(8, 2)
local tickRight = makeTick("Right")
tickRight.Size = UDim2.fromOffset(8, 2)

local hitmarker = Instance.new("TextLabel")
hitmarker.Name = "Hitmarker"
hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitmarker.Position = UDim2.fromScale(0.5, 0.5)
hitmarker.Size = UDim2.fromOffset(28, 28)
hitmarker.BackgroundTransparency = 1
hitmarker.Font = Enum.Font.GothamBold
hitmarker.TextSize = 22
hitmarker.Text = "×"
hitmarker.TextTransparency = 1
hitmarker.TextColor3 = Color3.fromRGB(255, 255, 255)
hitmarker.Parent = gui

local hitTimer = 0
ClientState.OnHitConfirm = function(isHeadshot: boolean)
	hitTimer = 0.16
	hitmarker.TextColor3 = if isHeadshot then Color3.fromRGB(255, 70, 70) else Color3.fromRGB(255, 255, 255)
	hitmarker.TextTransparency = 0
end

-- ============================================================================
-- 3. PANEL DE SALUD Y MUNICIÓN G18 (PARTE INFERIOR IZQUIERDA)
-- ============================================================================
local statusPanel = Instance.new("Frame")
statusPanel.Name = "StatusPanel"
statusPanel.AnchorPoint = Vector2.new(0, 1)
statusPanel.Position = UDim2.new(0, 16, 1, -16)
statusPanel.Size = UDim2.fromOffset(195, 68)
statusPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
statusPanel.BackgroundTransparency = 0.25
statusPanel.BorderSizePixel = 0
statusPanel.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusPanel

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Position = UDim2.fromOffset(10, 6)
ammoLabel.Size = UDim2.new(1, -20, 0, 26)
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
ammoLabel.Font = Enum.Font.GothamBold
ammoLabel.TextSize = 16
ammoLabel.TextColor3 = Color3.fromRGB(250, 225, 130)
ammoLabel.Text = "G18  |  33 / 33"
ammoLabel.Parent = statusPanel

local hpBg = Instance.new("Frame")
hpBg.Position = UDim2.fromOffset(10, 38)
hpBg.Size = UDim2.new(1, -20, 0, 18)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 44, 52)
hpBg.BorderSizePixel = 0
hpBg.Parent = statusPanel

local hpBgCorner = Instance.new("UICorner")
hpBgCorner.CornerRadius = UDim.new(0, 5)
hpBgCorner.Parent = hpBg

local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = Color3.fromRGB(70, 200, 115)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBg

local hpFillCorner = Instance.new("UICorner")
hpFillCorner.CornerRadius = UDim.new(0, 5)
hpFillCorner.Parent = hpFill

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.fromScale(1, 1)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.GothamBold
hpText.TextSize = 11
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.Text = "100 HP"
hpText.Parent = hpBg

-- ============================================================================
-- 4. BOTONES TÁCTILES DE COMBATE Y MOVIMIENTO (OPTIMIZADOS PARA TELÉFONO)
-- ============================================================================
local controlsContainer = Instance.new("Frame")
controlsContainer.Name = "MobileControls"
controlsContainer.Size = UDim2.fromScale(1, 1)
controlsContainer.BackgroundTransparency = 1
controlsContainer.Parent = gui

local function createActionButton(
	name: string,
	text: string,
	pos: UDim2,
	size: UDim2,
	bgColor: Color3
): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.AnchorPoint = Vector2.new(1, 1)
	btn.Position = pos
	btn.Size = size
	btn.BackgroundColor3 = bgColor
	btn.BackgroundTransparency = 0.22
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.AutoButtonColor = true
	btn.Active = true
	btn.Parent = controlsContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.68
	stroke.Parent = btn

	return btn
end

-- Botones lado derecho (disparo, apuntado, movimiento avanzado)
local fireBtn = createActionButton("FireButton", "DISPARAR", UDim2.new(1, -24, 1, -110), UDim2.fromOffset(78, 78), Color3.fromRGB(195, 55, 45))
local aimBtn = createActionButton("AimButton", "APUNTAR", UDim2.new(1, -112, 1, -120), UDim2.fromOffset(64, 54), Color3.fromRGB(48, 92, 165))
local reloadBtn = createActionButton("ReloadButton", "RECARGA", UDim2.new(1, -112, 1, -184), UDim2.fromOffset(64, 44), Color3.fromRGB(70, 74, 84))

local jumpBtn = createActionButton("JumpButton", "SALTAR", UDim2.new(1, -24, 1, -200), UDim2.fromOffset(68, 52), Color3.fromRGB(54, 130, 88))
local slideBtn = createActionButton("SlideButton", "DESLIZAR", UDim2.new(1, -112, 1, -54), UDim2.fromOffset(74, 48), Color3.fromRGB(185, 128, 38))
local diveBtn = createActionButton("DiveButton", "LANZARSE", UDim2.new(1, -196, 1, -54), UDim2.fromOffset(74, 48), Color3.fromRGB(150, 72, 165))
local sprintBtn = createActionButton("SprintButton", "SPRINT", UDim2.new(1, -24, 1, -54), UDim2.fromOffset(78, 48), Color3.fromRGB(58, 62, 72))

-- Mantener apretado para disparar automático en teléfono
fireBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		ClientState.IsFiring = true
	end
end)
fireBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		ClientState.IsFiring = false
	end
end)

aimBtn.Activated:Connect(function()
	ClientState.IsAiming = not ClientState.IsAiming
end)

reloadBtn.Activated:Connect(function()
	if ClientState.OnReload then
		ClientState.OnReload()
	end
end)

sprintBtn.Activated:Connect(function()
	if ClientState.OnToggleSprint then
		ClientState.OnToggleSprint()
	end
end)

slideBtn.Activated:Connect(function()
	if ClientState.OnCrouchOrSlide then
		ClientState.OnCrouchOrSlide()
	end
end)

jumpBtn.Activated:Connect(function()
	if ClientState.OnJumpOrCancel then
		ClientState.OnJumpOrCancel()
	end
end)

diveBtn.Activated:Connect(function()
	if ClientState.OnDive then
		ClientState.OnDive()
	end
end)

-- Ocultar botones táctiles únicamente si no hay pantalla táctil (PC usa teclado/ratón)
-- Mantiene un aviso discreto en PC con las teclas.
local isTouch = UserInputService.TouchEnabled
controlsContainer.Visible = isTouch

if not isTouch then
	local pcHint = Instance.new("TextLabel")
	pcHint.AnchorPoint = Vector2.new(1, 1)
	pcHint.Position = UDim2.new(1, -16, 1, -16)
	pcHint.Size = UDim2.fromOffset(290, 48)
	pcHint.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	pcHint.BackgroundTransparency = 0.3
	pcHint.BorderSizePixel = 0
	pcHint.Font = Enum.Font.GothamMedium
	pcHint.TextSize = 11
	pcHint.TextColor3 = Color3.fromRGB(215, 220, 230)
	pcHint.Text = "Shift: Sprint | C: Deslizar | Espacio: Cancel/Saltar\nV/F: Lanzarse | R: Recargar | Clic Der: Apuntar"
	pcHint.Parent = gui

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 8)
	hintCorner.Parent = pcHint
end

ScoreUpdateEvent.OnClientEvent:Connect(function(summary: { { UserId: number, Name: string, Kills: number, Deaths: number } })
	local myKills = 0
	local rivalKills = 0
	local rivalName = "Rival"
	for _, entry in summary do
		if entry.UserId == localPlayer.UserId then
			myKills = entry.Kills
		else
			rivalKills = entry.Kills
			rivalName = entry.Name
		end
	end
	scoreLabel.Text = string.format("TÚ: %d  vs  %s: %d", myKills, rivalName, rivalKills)
end)

local STATE_NAMES_ES: { [string]: string } = {
	Idle = "LISTO",
	Sprint = "SPRINT",
	Crouch = "AGACHADO",
	Slide = "DESLIZANDO",
	Dive = "LANZAMIENTO",
	Jump = "EN EL AIRE",
}

RunService.RenderStepped:Connect(function(dt: number)
	-- Actualizar estado y botones visuales
	local stateText = STATE_NAMES_ES[ClientState.MoveState] or ClientState.MoveState
	if ClientState.IsAiming then
		stateText ..= " • APUNTANDO"
	end
	stateLabel.Text = "ESTADO: " .. stateText

	sprintBtn.BackgroundColor3 = if ClientState.IsSprinting
		then Color3.fromRGB(55, 145, 220)
		else Color3.fromRGB(58, 62, 72)
	aimBtn.BackgroundColor3 = if ClientState.IsAiming
		then Color3.fromRGB(215, 155, 40)
		else Color3.fromRGB(48, 92, 165)

	-- Actualizar munición
	if ClientState.IsReloading then
		ammoLabel.Text = "G18  |  RECARGANDO..."
	else
		ammoLabel.Text = string.format("G18  |  %d / %d", ClientState.Ammo, ClientState.MaxAmmo)
	end

	-- Actualizar salud
	local character = localPlayer.Character
	local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if hum then
		local ratio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
		hpFill.Size = UDim2.fromScale(ratio, 1)
		hpText.Text = string.format("%d HP", math.ceil(math.max(0, hum.Health)))
	end

	-- Retícula dinámica según dispersión
	local gap = if ClientState.IsAiming then 6 elseif ClientState.MoveState == "Slide" or ClientState.MoveState == "Sprint" then 15 else 10
	if ClientState.IsFiring then
		gap += 3
	end
	tickTop.Position = UDim2.new(0.5, 0, 0.5, -gap)
	tickBottom.Position = UDim2.new(0.5, 0, 0.5, gap)
	tickLeft.Position = UDim2.new(0.5, -gap, 0.5, 0)
	tickRight.Position = UDim2.new(0.5, gap, 0.5, 0)

	if hitTimer > 0 then
		hitTimer -= dt
		if hitTimer <= 0 then
			hitmarker.TextTransparency = 1
		end
	end
end)
