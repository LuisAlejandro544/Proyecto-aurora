--!strict
--[=[
	Script de Lune ejecutado en GitHub Actions (tools/build_map.luau).
	Lógica:
	1. Abre el archivo compilado por Rojo (`build/game.rbxl`).
	2. Construye en Workspace el mapa "MapaRuinas": una ciudad en ruinas pequeña
	   diseñada para duelos 1v1 con calles destruidas, edificios rotos, rampas
	   de escombros y coberturas bajas/medias estilo Warzone.
	3. Configura iluminación atmosférica de atardecer polvoriento y dos spawns opuestos.
	4. Crea las carpetas de RemoteEvents y construye la pistola automática "G18"
	   (modelo multipieza soldado con Weld) en ReplicatedStorage.Weapons.
	5. Guarda de nuevo `build/game.rbxl` listo para subir a Roblox Open Cloud.
]=]

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local PLACE_PATH = "build/game.rbxl"
assert(fs.isFile(PLACE_PATH), "No se encontró build/game.rbxl. Ejecuta primero `rojo build`.")

local rawPlace = fs.readFile(PLACE_PATH)
local game = roblox.deserializePlace(rawPlace)

local workspace = game:GetService("Workspace")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Limpiar mapa previo si existiera
local existingMap = workspace:FindFirstChild("MapaRuinas")
if existingMap then
	existingMap:Destroy()
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "MapaRuinas"
mapFolder.Parent = workspace

local spawnsFolder = Instance.new("Folder")
spawnsFolder.Name = "Spawns1v1"
spawnsFolder.Parent = mapFolder

-- Helper para crear piezas estáticas del mapa con rotación en grados
local function makePart(
	parent: any,
	name: string,
	size: any,
	pos: any,
	color: any,
	material: any,
	rotDeg: any?,
	canCollide: boolean?
)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	local cf = CFrame.new(pos.X, pos.Y, pos.Z)
	if rotDeg then
		cf = cf * CFrame.Angles(math.rad(rotDeg.X), math.rad(rotDeg.Y), math.rad(rotDeg.Z))
	end
	part.CFrame = cf
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = if canCollide ~= nil then canCollide else true
	part.Parent = parent
	return part
end

-- Paleta urbana en ruinas
local COL_ASPHALT = Color3.fromRGB(36, 38, 42)
local COL_SIDEWALK = Color3.fromRGB(115, 114, 108)
local COL_CONCRETE_DARK = Color3.fromRGB(78, 80, 78)
local COL_CONCRETE_LIGHT = Color3.fromRGB(136, 132, 122)
local COL_BRICK_RUIN = Color3.fromRGB(112, 74, 60)
local COL_RUST = Color3.fromRGB(98, 56, 40)
local COL_STEEL = Color3.fromRGB(48, 52, 56)
local COL_SANDBAG = Color3.fromRGB(145, 130, 96)
local COL_LINE = Color3.fromRGB(190, 165, 80)
local COL_TIRE = Color3.fromRGB(24, 24, 26)
local COL_LAMP_GLOW = Color3.fromRGB(255, 200, 125)

-- ============================================================================
-- 1. SUELO, CALLE CENTRAL Y ACERAS
-- ============================================================================
local groundModel = Instance.new("Model")
groundModel.Name = "SueloCiudad"
groundModel.Parent = mapFolder

-- Base de tierra/escombros debajo de todo para evitar huecos
makePart(groundModel, "BaseSuelo", Vector3.new(170, 4, 150), Vector3.new(0, -2.2, 0), Color3.fromRGB(58, 54, 48), Enum.Material.Slate)

-- Calle central asfaltada (eje Norte-Sur de Z = -70 a +70)
makePart(groundModel, "CalleAsfalto", Vector3.new(38, 1, 142), Vector3.new(0, -0.45, 0), COL_ASPHALT, Enum.Material.Asphalt)

-- Líneas discontinuas desgastadas de la carretera
for z = -54, 54, 18 do
	makePart(groundModel, "LineaCalle", Vector3.new(1.1, 0.1, 8), Vector3.new(0, 0.06, z), COL_LINE, Enum.Material.SmoothPlastic, nil, false)
end

-- Aceras izquierda y derecha (subidas ligeramente sobre la calzada)
makePart(groundModel, "AceraOeste", Vector3.new(56, 1.3, 142), Vector3.new(-47, -0.15, 0), COL_SIDEWALK, Enum.Material.Concrete)
makePart(groundModel, "AceraEste", Vector3.new(56, 1.3, 142), Vector3.new(47, -0.15, 0), COL_SIDEWALK, Enum.Material.Concrete)

-- Parches de escombros rotos sobre la calle
makePart(groundModel, "EscombroCalle1", Vector3.new(7, 0.4, 5), Vector3.new(-9, 0.2, -18), COL_CONCRETE_DARK, Enum.Material.Slate, Vector3.new(2, 18, -3))
makePart(groundModel, "EscombroCalle2", Vector3.new(6, 0.45, 6), Vector3.new(10, 0.22, 22), COL_CONCRETE_LIGHT, Enum.Material.Slate, Vector3.new(-2, -25, 4))

-- ============================================================================
-- 2. MUROS PERIMETRALES Y FACHADAS EN RUINAS
-- ============================================================================
local perimeter = Instance.new("Model")
perimeter.Name = "PerimetroRuinas"
perimeter.Parent = mapFolder

-- Muros altos perimetrales para cerrar el campo 1v1
makePart(perimeter, "MuroNorte", Vector3.new(152, 22, 4), Vector3.new(0, 11, -70), COL_CONCRETE_DARK, Enum.Material.Concrete)
makePart(perimeter, "MuroSur", Vector3.new(152, 22, 4), Vector3.new(0, 11, 70), COL_CONCRETE_DARK, Enum.Material.Concrete)
makePart(perimeter, "MuroOeste", Vector3.new(4, 24, 144), Vector3.new(-74, 12, 0), COL_BRICK_RUIN, Enum.Material.Brick)
makePart(perimeter, "MuroEste", Vector3.new(4, 24, 144), Vector3.new(74, 12, 0), COL_BRICK_RUIN, Enum.Material.Brick)

-- Siluetas de edificios destruidos fuera/en el borde para dar sensación de ciudad
makePart(perimeter, "TorreRotaNO", Vector3.new(22, 38, 20), Vector3.new(-64, 19, -58), COL_CONCRETE_DARK, Enum.Material.Concrete)
makePart(perimeter, "TorreRotaSE", Vector3.new(22, 34, 20), Vector3.new(64, 17, 58), COL_CONCRETE_DARK, Enum.Material.Concrete)
makePart(perimeter, "TorreRotaNE", Vector3.new(20, 30, 18), Vector3.new(65, 15, -58), COL_BRICK_RUIN, Enum.Material.Brick)
makePart(perimeter, "TorreRotaSO", Vector3.new(20, 32, 18), Vector3.new(-65, 16, 58), COL_BRICK_RUIN, Enum.Material.Brick)

-- ============================================================================
-- 3. EDIFICIOS EN RUINAS SIMÉTRICOS (FLANCOS OESTE Y ESTE CON SEGUNDA PLANTA)
-- ============================================================================
local function buildRuinedFlankBuilding(sideSign: number, zSign: number, suffix: string)
	local bModel = Instance.new("Model")
	bModel.Name = "EdificioRuinas_" .. suffix
	bModel.Parent = mapFolder

	local bx = sideSign * 38
	local bz = zSign * 26

	-- Pared frontal hacia la calle con hueco central de puerta y ventana baja
	-- Tramo izquierdo y derecho de la pared frontal
	makePart(bModel, "ParedCalleA", Vector3.new(2, 11, 9), Vector3.new(bx - sideSign * 12, 6, bz - 10), COL_BRICK_RUIN, Enum.Material.Brick)
	makePart(bModel, "ParedCalleB", Vector3.new(2, 11, 9), Vector3.new(bx - sideSign * 12, 6, bz + 10), COL_BRICK_RUIN, Enum.Material.Brick)
	-- Antepecho de ventana central (altura 3.6 studs para cubrir agachado y disparar de pie)
	makePart(bModel, "AntepechoVentana", Vector3.new(2, 3.6, 11), Vector3.new(bx - sideSign * 12, 2.3, bz), COL_CONCRETE_LIGHT, Enum.Material.Concrete)

	-- Pared trasera parcialmente derrumbada
	makePart(bModel, "ParedTrasera", Vector3.new(2, 13, 22), Vector3.new(bx + sideSign * 12, 7, bz), COL_CONCRETE_DARK, Enum.Material.Concrete)

	-- Losa de segunda planta rota (altura Y = 9)
	makePart(bModel, "LosaPiso2", Vector3.new(20, 1.4, 24), Vector3.new(bx, 9, bz), COL_CONCRETE_DARK, Enum.Material.Concrete)

	-- Parapeto bajo en segunda planta (cobertura para el que sube)
	makePart(bModel, "ParapetoPiso2", Vector3.new(1.5, 3.4, 18), Vector3.new(bx - sideSign * 9.2, 11.4, bz), COL_CONCRETE_LIGHT, Enum.Material.Concrete)

	-- Rampa de escombros para subir caminando/haciendo slide al segundo piso
	makePart(
		bModel,
		"RampaEscombros",
		Vector3.new(8, 1.4, 22),
		Vector3.new(bx + sideSign * 2, 4.8, bz - zSign * 19),
		COL_CONCRETE_LIGHT,
		Enum.Material.Slate,
		Vector3.new(zSign * 24, 0, 0)
	)

	-- Vigas metálicas expuestas en el techo roto
	makePart(bModel, "VigaAcero1", Vector3.new(16, 0.8, 0.8), Vector3.new(bx, 13.5, bz - 6), COL_RUST, Enum.Material.CorrodedMetal, Vector3.new(0, 8, -12))
	makePart(bModel, "VigaAcero2", Vector3.new(14, 0.8, 0.8), Vector3.new(bx - sideSign * 2, 14, bz + 5), COL_STEEL, Enum.Material.Metal, Vector3.new(0, -10, 8))
end

buildRuinedFlankBuilding(-1, -1, "NO")
buildRuinedFlankBuilding(1, 1, "SE")

-- ============================================================================
-- 4. COBERTURAS TÁCTICAS ESTILO WARZONE EN LA CALLE Y FLANCOS
-- ============================================================================
local covers = Instance.new("Model")
covers.Name = "CoberturasTacticas"
covers.Parent = mapFolder

-- Helper para crear vehículos abandonados / quemados (sin marcas comerciales)
local function buildWreckedCar(pos: any, yawDeg: number, color: any, name: string)
	local car = Instance.new("Model")
	car.Name = name
	car.Parent = covers

	local baseCF = CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, math.rad(yawDeg), 0)

	local function carPiece(pieceName: string, size: any, offset: any, pColor: any, mat: any)
		local p = Instance.new("Part")
		p.Name = pieceName
		p.Size = size
		p.CFrame = baseCF * CFrame.new(offset.X, offset.Y, offset.Z)
		p.Color = pColor
		p.Material = mat
		p.Anchored = true
		p.Parent = car
	end

	-- Chasis bajo (altura ~3.5 studs para cubrirte agachado y asomarte de pie)
	carPiece("Chasis", Vector3.new(6.2, 2.3, 13.5), Vector3.new(0, 1.8, 0), color, Enum.Material.CorrodedMetal)
	-- Cabina superior (cobertura media ~5.2 studs para cubrirte de pie detrás de la cabina)
	carPiece("Cabina", Vector3.new(5.6, 2.2, 6.2), Vector3.new(0, 3.9, -0.5), color, Enum.Material.Metal)
	-- 4 Ruedas negras
	carPiece("RuedaFI", Vector3.new(1.1, 2.2, 2.2), Vector3.new(-3.0, 1.1, -4.2), COL_TIRE, Enum.Material.Rubber)
	carPiece("RuedaFD", Vector3.new(1.1, 2.2, 2.2), Vector3.new(3.0, 1.1, -4.2), COL_TIRE, Enum.Material.Rubber)
	carPiece("RuedaTI", Vector3.new(1.1, 2.2, 2.2), Vector3.new(-3.0, 1.1, 4.2), COL_TIRE, Enum.Material.Rubber)
	carPiece("RuedaTD", Vector3.new(1.1, 2.2, 2.2), Vector3.new(3.0, 1.1, 4.2), COL_TIRE, Enum.Material.Rubber)
end

-- Dos autos destruidos en ángulos cruzados en la calle central
buildWreckedCar(Vector3.new(-8, 0.05, -14), 28, Color3.fromRGB(78, 86, 78), "VehiculoDestruido_Norte")
buildWreckedCar(Vector3.new(8, 0.05, 14), -152, Color3.fromRGB(92, 62, 52), "VehiculoDestruido_Sur")

-- Barreras Jersey de hormigón (cobertura baja 3.7 studs para slide-cancel y peek)
makePart(covers, "BarreraCentroNorte", Vector3.new(11, 3.7, 2.2), Vector3.new(6, 1.85, -28), COL_CONCRETE_LIGHT, Enum.Material.Concrete, Vector3.new(0, -14, 0))
makePart(covers, "BarreraCentroSur", Vector3.new(11, 3.7, 2.2), Vector3.new(-6, 1.85, 28), COL_CONCRETE_LIGHT, Enum.Material.Concrete, Vector3.new(0, -14, 0))
makePart(covers, "BarreraSpawnNorte", Vector3.new(14, 4.2, 2.5), Vector3.new(0, 2.1, -46), COL_CONCRETE_DARK, Enum.Material.Concrete)
makePart(covers, "BarreraSpawnSur", Vector3.new(14, 4.2, 2.5), Vector3.new(0, 2.1, 46), COL_CONCRETE_DARK, Enum.Material.Concrete)

-- Contenedor militar oxidado en el centro (cobertura alta para rotar y cortar línea de tiro)
makePart(covers, "ContenedorCentral", Vector3.new(8.5, 8.5, 16), Vector3.new(0, 4.25, 0), Color3.fromRGB(64, 82, 68), Enum.Material.CorrodedMetal, Vector3.new(0, 35, 0))

-- Sacos de arena y bloques en los flancos abiertos
makePart(covers, "SacosFlancoOeste", Vector3.new(9, 3.5, 3), Vector3.new(-36, 2.2, -32), COL_SANDBAG, Enum.Material.Fabric, Vector3.new(0, 22, 0))
makePart(covers, "SacosFlancoEste", Vector3.new(9, 3.5, 3), Vector3.new(36, 2.2, 32), COL_SANDBAG, Enum.Material.Fabric, Vector3.new(0, 22, 0))
makePart(covers, "CajasMilitaresNE", Vector3.new(6, 5.5, 6), Vector3.new(34, 3.2, -24), Color3.fromRGB(72, 78, 58), Enum.Material.Metal, Vector3.new(0, 15, 0))
makePart(covers, "CajasMilitaresSO", Vector3.new(6, 5.5, 6), Vector3.new(-34, 3.2, 24), Color3.fromRGB(72, 78, 58), Enum.Material.Metal, Vector3.new(0, 15, 0))

-- Farolas inclinadas con luz cálida de ciudad en ruinas
local function buildRuinedLamp(pos: any, tiltDeg: any, name: string)
	local lamp = Instance.new("Model")
	lamp.Name = name
	lamp.Parent = mapFolder

	makePart(lamp, "Poste", Vector3.new(0.9, 16, 0.9), Vector3.new(pos.X, 8, pos.Z), COL_STEEL, Enum.Material.Metal, tiltDeg)
	local bulb = makePart(lamp, "Foco", Vector3.new(2.2, 0.7, 1.4), Vector3.new(pos.X, 15.4, pos.Z), COL_LAMP_GLOW, Enum.Material.Neon, tiltDeg, false)
	local light = Instance.new("PointLight")
	light.Color = COL_LAMP_GLOW
	light.Brightness = 1.6
	light.Range = 36
	light.Parent = bulb
end

buildRuinedLamp(Vector3.new(-19.5, 0, -24), Vector3.new(4, 0, -7), "FarolaOeste")
buildRuinedLamp(Vector3.new(19.5, 0, 24), Vector3.new(-4, 0, 7), "FarolaEste")

-- ============================================================================
-- 5. SPAWNS OPUESTOS PARA 1v1
-- ============================================================================
local function makeSpawn(name: string, pos: any, yawDeg: number)
	local sp = Instance.new("SpawnLocation")
	sp.Name = name
	sp.Size = Vector3.new(6, 0.5, 6)
	sp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z) * CFrame.Angles(0, math.rad(yawDeg), 0)
	sp.Anchored = true
	sp.CanCollide = false
	sp.Transparency = 0.75
	sp.Color = Color3.fromRGB(40, 42, 46)
	sp.Material = Enum.Material.SmoothPlastic
	sp.Duration = 0
	sp.Parent = spawnsFolder
	return sp
end

makeSpawn("SpawnA", Vector3.new(0, 0.3, -58), 180)
makeSpawn("SpawnB", Vector3.new(0, 0.3, 58), 0)

-- ============================================================================
-- 6. ILUMINACIÓN ATMOSFÉRICA
-- ============================================================================
lighting.ClockTime = 17.35
lighting.Brightness = 2.1
lighting.Ambient = Color3.fromRGB(78, 72, 68)
lighting.OutdoorAmbient = Color3.fromRGB(110, 102, 95)
lighting.FogColor = Color3.fromRGB(130, 118, 106)
lighting.FogEnd = 420
lighting.FogStart = 45

local oldAtmo = lighting:FindFirstChildOfClass("Atmosphere")
if oldAtmo then
	oldAtmo:Destroy()
end
local atmo = Instance.new("Atmosphere")
atmo.Density = 0.30
atmo.Offset = 0.25
atmo.Color = Color3.fromRGB(162, 146, 130)
atmo.Decay = Color3.fromRGB(112, 94, 82)
atmo.Glare = 0.15
atmo.Haze = 1.4
atmo.Parent = lighting

-- ============================================================================
-- 7. REMOTES Y ARMA AUTOMÁTICA G18 EN REPLICATEDSTORAGE
-- ============================================================================
local remotes = replicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = replicatedStorage
end

local remoteNames = {
	"MovementStateEvent",
	"FireWeaponEvent",
	"ReloadWeaponEvent",
	"HitConfirmEvent",
	"ScoreUpdateEvent",
}

for _, rName in remoteNames do
	if not remotes:FindFirstChild(rName) then
		local ev = Instance.new("RemoteEvent")
		ev.Name = rName
		ev.Parent = remotes
	end
end

local weaponsFolder = replicatedStorage:FindFirstChild("Weapons")
if not weaponsFolder then
	weaponsFolder = Instance.new("Folder")
	weaponsFolder.Name = "Weapons"
	weaponsFolder.Parent = replicatedStorage
end

local oldG18 = weaponsFolder:FindFirstChild("G18")
if oldG18 then
	oldG18:Destroy()
end

-- Construcción de la Pistola Automática G18 (Tool multipieza soldado con Weld)
local g18 = Instance.new("Tool")
g18.Name = "G18"
g18.CanBeDropped = false
g18.RequiresHandle = true
g18.Grip = CFrame.new(0, -0.18, 0.22)
g18.Parent = weaponsFolder

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.24, 0.68, 0.34)
handle.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-14), 0, 0)
handle.Color = Color3.fromRGB(32, 34, 38)
handle.Material = Enum.Material.Plastic
handle.CanCollide = false
handle.Massless = true
handle.Anchored = false
handle.Parent = g18

local function addGunPart(name: string, size: any, localCF: any, color: any, mat: any)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = handle.CFrame * localCF
	part.Color = color
	part.Material = mat
	part.CanCollide = false
	part.Massless = true
	part.Anchored = false
	part.Parent = g18

	local weld = Instance.new("Weld")
	weld.Name = name .. "_Weld"
	weld.Part0 = handle
	weld.Part1 = part
	weld.C0 = localCF
	weld.Parent = handle

	return part
end

local COL_FRAME = Color3.fromRGB(34, 36, 40)
local COL_SLIDE = Color3.fromRGB(22, 24, 28)
local COL_BARREL = Color3.fromRGB(58, 62, 68)
local COL_SIGHT = Color3.fromRGB(80, 255, 120)

-- Armazón inferior de polímero
addGunPart("Armazon", Vector3.new(0.26, 0.22, 1.35), CFrame.new(0, 0.34, -0.35), COL_FRAME, Enum.Material.Plastic)
-- Corredera metálica superior (Slide)
addGunPart("Corredera", Vector3.new(0.27, 0.24, 1.42), CFrame.new(0, 0.54, -0.37), COL_SLIDE, Enum.Material.Metal)
-- Cañón frontal
addGunPart("Canon", Vector3.new(0.14, 0.14, 0.22), CFrame.new(0, 0.52, -1.12), COL_BARREL, Enum.Material.Metal)
-- Cargador extendido de 33 balas (característico de la G18)
addGunPart("CargadorExtendido", Vector3.new(0.20, 0.52, 0.28), CFrame.new(0, -0.46, 0.08) * CFrame.Angles(math.rad(-14), 0, 0), Color3.fromRGB(26, 26, 30), Enum.Material.Plastic)
-- Guardamonte
addGunPart("Guardamonte", Vector3.new(0.14, 0.18, 0.34), CFrame.new(0, 0.18, -0.30), COL_FRAME, Enum.Material.Plastic)
-- Mira trasera y punto verde delantero (tritium)
addGunPart("MiraTrasera", Vector3.new(0.22, 0.08, 0.08), CFrame.new(0, 0.69, 0.26), COL_SLIDE, Enum.Material.Metal)
addGunPart("MiraDelantera", Vector3.new(0.06, 0.08, 0.08), CFrame.new(0, 0.69, -0.98), COL_SIGHT, Enum.Material.Neon)
-- Riel táctico / módulo inferior
addGunPart("ModuloTactico", Vector3.new(0.22, 0.16, 0.42), CFrame.new(0, 0.17, -0.78), Color3.fromRGB(28, 30, 34), Enum.Material.Metal)

-- Boca del cañón (para origen de trazadores y fogonazo)
local muzzle = addGunPart("Muzzle", Vector3.new(0.10, 0.10, 0.10), CFrame.new(0, 0.52, -1.24), COL_BARREL, Enum.Material.SmoothPlastic)
muzzle.Transparency = 1

-- Guardar el archivo .rbxl actualizado
local serialized = roblox.serializePlace(game)
fs.writeFile(PLACE_PATH, serialized)

print("[Lune] MapaRuinas 1v1 y arma G18 construidos correctamente en", PLACE_PATH)
