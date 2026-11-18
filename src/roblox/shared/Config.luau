--!strict
--[=[
	Configuración general del juego 1v1 en ciudad en ruinas (ModuleScript compartido).
	Contiene nombres estándar de carpetas, arma inicial, modos de juego
	(Contra Bot / Multijugador próximamente) y reglas básicas de la partida.
]=]

local Config = {
	GameTitle = "Ruinas 1v1",
	MapFolderName = "MapaRuinas",
	SpawnsFolderName = "Spawns1v1",
	DefaultWeaponName = "G18",
	RespawnDelay = 2.5,
	BotRespawnDelay = 2.8,
	BotNames = {
		"Kairo_Tactico",
		"Sombra_1v1",
		"Vektor_AR",
		"Nexo_Ruinas",
	},
}

return Config
