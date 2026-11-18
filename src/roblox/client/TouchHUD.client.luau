--!strict
--[=[
	Interfaz táctica, selector de modo y botones táctiles para celular (LocalScript).
	Lógica:
	- Al iniciar el juego muestra el selector de modo:
	  1. "1v1 CONTRA BOT" (bot con comportamiento táctico humano).
	  2. "MULTIJUGADOR 1v1" (marcado como PRÓXIMAMENTE).
	- Muestra marcador superior con botón para volver al menú, retícula dinámica,
	  Hitmarker con zona corporal impactada (cabeza, pecho, brazo, mano, pierna, pie)
	  y controles táctiles cómodos para jugar 100% desde el teléfono.
]=]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScoreUpdateEvent = Remotes:WaitForChild("ScoreUpdateEvent") :: RemoteEvent
local SelectModeEvent = Remotes:WaitForChild("SelectModeEvent") :: RemoteEvent
local MatchStateEvent = Remotes:WaitForChild("MatchStateEvent") :: RemoteEvent

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
-- 1. MARCADOR SUPERIOR 1v1, ESTADO Y BOTÓN DE MENÚ
-- ============================================================================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.AnchorPoint = Vector2.new(0.5, 0)
topBar.Position = UDim2.new(0.5, 0, 0, 12)
topBar.Size = UDim2.fromOffset(340, 48)
topBar.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
topBar.BackgroundTransparency = 0.22
topBar.BorderSizePixel = 0
topBar.Parent = gui

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(1, -86, 0.55, 0)
scoreLabel.Position = UDim2.fromOffset(10, 2)
scoreLabel.BackgroundTransparency = 1
scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 14
scoreLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
scoreLabel.Text = "RUINAS 1v1  |  ELIGE MODO"
scoreLabel.Parent = topBar

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(1, -86, 0.4, 0)
stateLabel.Position = UDim2.new(0, 10, 0.55, 0)
stateLabel.BackgroundTransparency = 1
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.Font = Enum.Font.GothamMedium
stateLabel.TextSize = 11
stateLabel.TextColor3 = Color3.fromRGB(185, 200, 215)
stateLabel.Text = "ESTADO: EN MENÚ"
stateLabel.Parent = topBar

local menuToggleBtn = Instance.new("TextButton")
menuToggleBtn.Name = "MenuButton"
menuToggleBtn.AnchorPoint = Vector2.new(1, 0.5)
menuToggleBtn.Position = UDim2.new(1, -8, 0.5, 0)
menuToggleBtn.Size = UDim2.fromOffset(68, 32)
menuToggleBtn.BackgroundColor3 = Color3.fromRGB(48, 54, 66)
menuToggleBtn.BorderSizePixel = 0
menuToggleBtn.Font = Enum.Font.GothamBold
menuToggleBtn.TextSize = 11
menuToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuToggleBtn.Text = "MODO"
menuToggleBtn.Parent = topBar

local menuBtnCorner = Instance.new("UICorner")
menuBtnCorner.CornerRadius = UDim.new(0, 6)
menuBtnCorner.Parent = menuToggleBtn

menuToggleBtn.Activated:Connect(function()
	SelectModeEvent:FireServer("Menu")
end)

-- ============================================================================
-- 2. PANTALLA DE SELECCIÓN DE MODO (BOT TÁCTICO vs MULTIJUGADOR PRÓXIMAMENTE)
-- ============================================================================
local modeOverlay = Instance.new("Frame")
modeOverlay.Name = "ModeMenu"
modeOverlay.Size = UDim2.fromScale(1, 1)
modeOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
modeOverlay.BackgroundTransparency = 0.22
modeOverlay.BorderSizePixel = 0
modeOverlay.ZIndex = 20
modeOverlay.Visible = true
modeOverlay.Parent = gui

local menuBox = Instance.new("Frame")
menuBox.AnchorPoint = Vector2.new(0.5, 0.5)
menuBox.Position = UDim2.fromScale(0.5, 0.5)
menuBox.Size = UDim2.new(0.92, 0, 0.86, 0)
menuBox.BackgroundColor3 = Color3.fromRGB(20, 23, 29)
menuBox.BorderSizePixel = 0
menuBox.ZIndex = 21
menuBox.Parent = modeOverlay

local menuBoxConstraint = Instance.new("UISizeConstraint")
menuBoxConstraint.MaxSize = Vector2.new(480, 310)
menuBoxConstraint.Parent = menuBox

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 14)
boxCorner.Parent = menuBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Thickness = 1.5
boxStroke.Color = Color3.fromRGB(85, 95, 115)
boxStroke.Parent = menuBox

local menuTitle = Instance.new("TextLabel")
menuTitle.Position = UDim2.fromOffset(20, 16)
menuTitle.Size = UDim2.new(1, -40, 0, 28)
menuTitle.BackgroundTransparency = 1
menuTitle.Font = Enum.Font.GothamBlack
menuTitle.TextSize = 20
menuTitle.TextColor3 = Color3.fromRGB(245, 247, 250)
menuTitle.Text = "RUINAS 1v1 — SELECCIONA MODO"
menuTitle.ZIndex = 22
menuTitle.Parent = menuBox

local menuSub = Instance.new("TextLabel")
menuSub.Position = UDim2.fromOffset(20, 44)
menuSub.Size = UDim2.new(1, -40, 0, 20)
menuSub.BackgroundTransparency = 1
menuSub.Font = Enum.Font.GothamMedium
menuSub.TextSize = 12
menuSub.TextColor3 = Color3.fromRGB(165, 178, 196)
menuSub.Text = "Arma equipada: G18 Táctica (daño por zona corporal)"
menuSub.ZIndex = 22
menuSub.Parent = menuBox

-- Tarjeta 1: Contra Bot
local botCard = Instance.new("Frame")
botCard.Position = UDim2.fromOffset(20, 76)
botCard.Size = UDim2.new(0.5, -26, 0, 175)
botCard.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
botCard.BorderSizePixel = 0
botCard.ZIndex = 22
botCard.Parent = menuBox

local botCardCorner = Instance.new("UICorner")
botCardCorner.CornerRadius = UDim.new(0, 10)
botCardCorner.Parent = botCard

local botCardStroke = Instance.new("UIStroke")
botCardStroke.Thickness = 1.5
botCardStroke.Color = Color3.fromRGB(70, 170, 115)
botCardStroke.Parent = botCard

local botTitle = Instance.new("TextLabel")
botTitle.Position = UDim2.fromOffset(12, 12)
botTitle.Size = UDim2.new(1, -24, 0, 22)
botTitle.BackgroundTransparency = 1
botTitle.TextXAlignment = Enum.TextXAlignment.Left
botTitle.Font = Enum.Font.GothamBold
botTitle.TextSize = 15
botTitle.TextColor3 = Color3.fromRGB(120, 235, 165)
botTitle.Text = "CONTRA BOT"
botTitle.ZIndex = 23
botTitle.Parent = botCard

local botDesc = Instance.new("TextLabel")
botDesc.Position = UDim2.fromOffset(12, 38)
botDesc.Size = UDim2.new(1, -24, 0, 76)
botDesc.BackgroundTransparency = 1
botDesc.TextXAlignment = Enum.TextXAlignment.Left
botDesc.TextYAlignment = Enum.TextYAlignment.Top
botDesc.TextWrapped = true
botDesc.Font = Enum.Font.Gotham
botDesc.TextSize = 12
botDesc.TextColor3 = Color3.fromRGB(210, 216, 225)
botDesc.Text = "Duelo 1v1 contra un rival inteligente: usa coberturas, flanquea, hace slide y dispara en ráfagas reales."
botDesc.ZIndex = 23
botDesc.Parent = botCard

local playBotBtn = Instance.new("TextButton")
playBotBtn.Name = "PlayBotButton"
playBotBtn.AnchorPoint = Vector2.new(0.5, 1)
playBotBtn.Position = UDim2.new(0.5, 0, 1, -12)
playBotBtn.Size = UDim2.new(1, -24, 0, 40)
playBotBtn.BackgroundColor3 = Color3.fromRGB(48, 155, 95)
playBotBtn.BorderSizePixel = 0
playBotBtn.Font = Enum.Font.GothamBold
playBotBtn.TextSize = 13
playBotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBotBtn.Text = "JUGAR CONTRA BOT"
playBotBtn.ZIndex = 23
playBotBtn.Parent = botCard

local playBotCorner = Instance.new("UICorner")
playBotCorner.CornerRadius = UDim.new(0, 8)
playBotCorner.Parent = playBotBtn

-- Tarjeta 2: Multijugador (Próximamente)
local mpCard = Instance.new("Frame")
mpCard.Position = UDim2.new(0.5, 6, 0, 76)
mpCard.Size = UDim2.new(0.5, -26, 0, 175)
mpCard.BackgroundColor3 = Color3.fromRGB(26, 28, 35)
mpCard.BorderSizePixel = 0
mpCard.ZIndex = 22
mpCard.Parent = menuBox

local mpCardCorner = Instance.new("UICorner")
mpCardCorner.CornerRadius = UDim.new(0, 10)
mpCardCorner.Parent = mpCard

local mpCardStroke = Instance.new("UIStroke")
mpCardStroke.Thickness = 1
mpCardStroke.Color = Color3.fromRGB(70, 75, 90)
mpCardStroke.Parent = mpCard

local mpTitle = Instance.new("TextLabel")
mpTitle.Position = UDim2.fromOffset(12, 12)
mpTitle.Size = UDim2.new(1, -24, 0, 22)
mpTitle.BackgroundTransparency = 1
mpTitle.TextXAlignment = Enum.TextXAlignment.Left
mpTitle.Font = Enum.Font.GothamBold
mpTitle.TextSize = 15
mpTitle.TextColor3 = Color3.fromRGB(220, 200, 120)
mpTitle.Text = "MULTIJUGADOR 1v1"
mpTitle.ZIndex = 23
mpTitle.Parent = mpCard

local mpDesc = Instance.new("TextLabel")
mpDesc.Position = UDim2.fromOffset(12, 38)
mpDesc.Size = UDim2.new(1, -24, 0, 76)
mpDesc.BackgroundTransparency = 1
mpDesc.TextXAlignment = Enum.TextXAlignment.Left
mpDesc.TextYAlignment = Enum.TextYAlignment.Top
mpDesc.TextWrapped = true
mpDesc.Font = Enum.Font.Gotham
mpDesc.TextSize = 12
mpDesc.TextColor3 = Color3.fromRGB(170, 176, 188)
mpDesc.Text = "Combate en vivo contra otro jugador en línea con sistema de rondas y marcador competitivo."
mpDesc.ZIndex = 23
mpDesc.Parent = mpCard

local mpBtn = Instance.new("TextButton")
mpBtn.Name = "MultiplayerSoonButton"
mpBtn.AnchorPoint = Vector2.new(0.5, 1)
mpBtn.Position = UDim2.new(0.5, 0, 1, -12)
mpBtn.Size = UDim2.new(1, -24, 0, 40)
mpBtn.BackgroundColor3 = Color3.fromRGB(62, 66, 78)
mpBtn.BorderSizePixel = 0
mpBtn.Font = Enum.Font.GothamBold
mpBtn.TextSize = 12
mpBtn.TextColor3 = Color3.fromRGB(235, 215, 130)
mpBtn.Text = "PRÓXIMAMENTE"
mpBtn.ZIndex = 23
mpBtn.Parent = mpCard

local mpBtnCorner = Instance.new("UICorner")
mpBtnCorner.CornerRadius = UDim.new(0, 8)
mpBtnCorner.Parent = mpBtn

local noticeLabel = Instance.new("TextLabel")
noticeLabel.Position = UDim2.fromOffset(20, 264)
noticeLabel.Size = UDim2.new(1, -40, 0, 34)
noticeLabel.BackgroundTransparency = 1
noticeLabel.TextWrapped = true
noticeLabel.Font = Enum.Font.GothamMedium
noticeLabel.TextSize = 12
noticeLabel.TextColor3 = Color3.fromRGB(250, 200, 100)
noticeLabel.Text = ""
noticeLabel.ZIndex = 22
noticeLabel.Parent = menuBox

playBotBtn.Activated:Connect(function()
	noticeLabel.Text = ""
	SelectModeEvent:FireServer("Bot")
end)

mpBtn.Activated:Connect(function()
	noticeLabel.Text = "El modo Multijugador estará disponible próximamente. ¡Prueba el modo Contra Bot!"
	SelectModeEvent:FireServer("Multiplayer")
end)

-- ============================================================================
-- 3. RETÍCULA DINÁMICA Y HITMARKER CON ZONA CORPORAL
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

local hitZoneLabel = Instance.new("TextLabel")
hitZoneLabel.Name = "HitZoneLabel"
hitZoneLabel.AnchorPoint = Vector2.new(0.5, 0)
hitZoneLabel.Position = UDim2.new(0.5, 0, 0.5, 18)
hitZoneLabel.Size = UDim2.fromOffset(140, 20)
hitZoneLabel.BackgroundTransparency = 1
hitZoneLabel.Font = Enum.Font.GothamBold
hitZoneLabel.TextSize = 11
hitZoneLabel.Text = ""
hitZoneLabel.TextTransparency = 1
hitZoneLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hitZoneLabel.Parent = gui

local ZONE_NAMES_ES: { [string]: string } = {
	Head = "CABEZA",
	Chest = "PECHO",
	Arm = "BRAZO",
	Hand = "MANO",
	Leg = "PIERNA",
	Foot = "PIE",
}

local hitTimer = 0
ClientState.OnHitConfirm = function(isHeadshot: boolean, hitZone: string?, damage: number?)
	hitTimer = 0.24
	local color = if isHeadshot
		then Color3.fromRGB(255, 70, 70)
		elseif hitZone == "Chest" then Color3.fromRGB(255, 205, 95)
		else Color3.fromRGB(255, 255, 255)
	hitmarker.TextColor3 = color
	hitmarker.TextTransparency = 0

	if hitZone and damage then
		local zoneEs = ZONE_NAMES_ES[hitZone] or hitZone
		hitZoneLabel.Text = string.format("%s -%d", zoneEs, damage)
		hitZoneLabel.TextColor3 = color
		hitZoneLabel.TextTransparency = 0
	end
end

-- ============================================================================
-- 4. PANEL DE SALUD Y MUNICIÓN G18 (PARTE INFERIOR IZQUIERDA)
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
-- 5. BOTONES TÁCTILES DE COMBATE Y MOVIMIENTO (OPTIMIZADOS PARA TELÉFONO)
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

local fireBtn = createActionButton("FireButton", "DISPARAR", UDim2.new(1, -24, 1, -110), UDim2.fromOffset(78, 78), Color3.fromRGB(195, 55, 45))
local aimBtn = createActionButton("AimButton", "APUNTAR", UDim2.new(1, -112, 1, -120), UDim2.fromOffset(64, 54), Color3.fromRGB(48, 92, 165))
local reloadBtn = createActionButton("ReloadButton", "RECARGA", UDim2.new(1, -112, 1, -184), UDim2.fromOffset(64, 44), Color3.fromRGB(70, 74, 84))

local jumpBtn = createActionButton("JumpButton", "SALTAR", UDim2.new(1, -24, 1, -200), UDim2.fromOffset(68, 52), Color3.fromRGB(54, 130, 88))
local slideBtn = createActionButton("SlideButton", "DESLIZAR", UDim2.new(1, -112, 1, -54), UDim2.fromOffset(74, 48), Color3.fromRGB(185, 128, 38))
local diveBtn = createActionButton("DiveButton", "LANZARSE", UDim2.new(1, -196, 1, -54), UDim2.fromOffset(74, 48), Color3.fromRGB(150, 72, 165))
local sprintBtn = createActionButton("SprintButton", "SPRINT", UDim2.new(1, -24, 1, -54), UDim2.fromOffset(78, 48), Color3.fromRGB(58, 62, 72))

-- Rastrear el dedo específico del botón de disparo para que nunca se quede pegado
local activeFireInput: InputObject? = nil
fireBtn.InputBegan:Connect(function(input)
	if ClientState.GameMode == "Menu" then
		return
	end
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		activeFireInput = input
		ClientState.IsFiring = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if activeFireInput and input == activeFireInput then
		activeFireInput = nil
		ClientState.IsFiring = false
	end
end)

aimBtn.Activated:Connect(function()
	if ClientState.GameMode == "Menu" then
		return
	end
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

local isTouch = UserInputService.TouchEnabled
controlsContainer.Visible = false

local pcHint: TextLabel? = nil
if not isTouch then
	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(1, 1)
	hint.Position = UDim2.new(1, -16, 1, -16)
	hint.Size = UDim2.fromOffset(290, 48)
	hint.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	hint.BackgroundTransparency = 0.3
	hint.BorderSizePixel = 0
	hint.Font = Enum.Font.GothamMedium
	hint.TextSize = 11
	hint.TextColor3 = Color3.fromRGB(215, 220, 230)
	hint.Text = "Shift: Sprint | C: Deslizar | Espacio: Cancel/Saltar\nV/F: Lanzarse | R: Recargar | Clic Der: Apuntar"
	hint.Visible = false
	hint.Parent = gui

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 8)
	hintCorner.Parent = hint
	pcHint = hint
end

MatchStateEvent.OnClientEvent:Connect(function(state: {
	Mode: string,
	BotName: string?,
	PlayerKills: number?,
	BotKills: number?,
	Notice: string?,
})
	if state.Notice and state.Notice ~= "" then
		noticeLabel.Text = state.Notice
	end

	local mode = state.Mode
	if mode == "Bot" then
		ClientState.GameMode = "Bot"
		modeOverlay.Visible = false
		controlsContainer.Visible = isTouch
		if pcHint then
			pcHint.Visible = true
		end
		scoreLabel.Text = string.format(
			"TÚ: %d  vs  %s (BOT): %d",
			state.PlayerKills or 0,
			state.BotName or "Bot",
			state.BotKills or 0
		)
	else
		ClientState.GameMode = "Menu"
		ClientState.IsFiring = false
		ClientState.IsAiming = false
		activeFireInput = nil
		modeOverlay.Visible = true
		controlsContainer.Visible = false
		if pcHint then
			pcHint.Visible = false
		end
		scoreLabel.Text = "RUINAS 1v1  |  ELIGE MODO"
	end
end)

ScoreUpdateEvent.OnClientEvent:Connect(function(summary: { { UserId: number, Name: string, Kills: number, Deaths: number } })
	if ClientState.GameMode ~= "Multiplayer" then
		return
	end
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
	if ClientState.GameMode == "Menu" then
		stateLabel.Text = "ESTADO: EN MENÚ"
	else
		local stateText = STATE_NAMES_ES[ClientState.MoveState] or ClientState.MoveState
		if ClientState.IsAiming then
			stateText ..= " • APUNTANDO"
		end
		stateLabel.Text = "ESTADO: " .. stateText
	end

	sprintBtn.BackgroundColor3 = if ClientState.IsSprinting
		then Color3.fromRGB(55, 145, 220)
		else Color3.fromRGB(58, 62, 72)
	aimBtn.BackgroundColor3 = if ClientState.IsAiming
		then Color3.fromRGB(215, 155, 40)
		else Color3.fromRGB(48, 92, 165)

	if ClientState.IsReloading then
		ammoLabel.Text = "G18  |  RECARGANDO..."
	else
		ammoLabel.Text = string.format("G18  |  %d / %d", ClientState.Ammo, ClientState.MaxAmmo)
	end

	local character = localPlayer.Character
	local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if hum then
		local ratio = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
		hpFill.Size = UDim2.fromScale(ratio, 1)
		hpText.Text = string.format("%d HP", math.ceil(math.max(0, hum.Health)))
	end

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
			hitZoneLabel.TextTransparency = 1
		end
	end
end)
