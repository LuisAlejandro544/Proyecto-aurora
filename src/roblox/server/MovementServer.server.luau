--!strict
--[=[
	Sincronizador de estados de movimiento en servidor (Script en ServerScriptService.Server).
	Lógica: Recibe el estado actual del jugador (Idle, Sprint, Crouch, Slide, Dive, Jump)
	y si está apuntando (IsAiming), valida que sea un estado permitido y lo publica
	como atributos en el Character para que el rival en el 1v1 vea sus animaciones.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MovementStateEvent = Remotes:WaitForChild("MovementStateEvent") :: RemoteEvent

local VALID_STATES: { [string]: boolean } = {
	Idle = true,
	Sprint = true,
	Crouch = true,
	Slide = true,
	Dive = true,
	Jump = true,
}

MovementStateEvent.OnServerEvent:Connect(function(player: Player, moveState: unknown, isAiming: unknown)
	local character = player.Character
	if not character then
		return
	end

	if typeof(moveState) == "string" and VALID_STATES[moveState] then
		character:SetAttribute("MoveState", moveState)
	end

	if typeof(isAiming) == "boolean" then
		character:SetAttribute("IsAiming", isAiming)
	end
end)
