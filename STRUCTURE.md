# Estructura del Proyecto (`STRUCTURE.md`)

Este documento describe la organización real de carpetas y archivos del repositorio, y cómo **Rojo** + **Lune** los transforman en el juego final de Roblox (`build/game.rbxl`).

---

## 1. Árbol de archivos del repositorio

```text
.
├── .github/
│   └── workflows/
│       └── deploy-roblox.yml       # Action MANUAL (workflow_dispatch) Rojo + Lune + Open Cloud
├── tools/
│   └── build_map.luau              # Script Lune: crea MapaRuinas, iluminación, Remotes y arma G18
├── src/
│   ├── App.tsx                     # Web mínima "Hello World" para el entorno Vite/React
│   ├── index.css                   # Estilos base Tailwind v4 para la web mínima
│   ├── main.tsx                    # Punto de entrada React
│   └── roblox/
│       ├── validateConfig.ts       # Validador estático de default.project.json y deploy-roblox.yml
│       ├── validateConfig.test.ts  # Suite de tests unitarios (node:test)
│       ├── shared/                 # -> ReplicatedStorage.Shared
│       │   ├── Config.luau         # Constantes globales (nombres de mapa, spawns, G18, respawn)
│       │   ├── MovementConfig.luau # Velocidades, tiempos de Slide/Dive y límites suaves de cámara
│       │   └── WeaponStats.luau    # Estadísticas de disparo, cargador, dispersión y retroceso
│       ├── server/                 # -> ServerScriptService.Server
│       │   ├── GameManager.server.luau    # Spawns 1v1 (SpawnA/SpawnB), entrega G18 y marcador Kills/Deaths
│       │   ├── MovementServer.server.luau # Valida y replica MoveState e IsAiming en atributos
│       │   └── WeaponServer.server.luau   # Munición autoritativa, recarga y Raycast con coberturas
│       └── client/                 # -> StarterPlayer.StarterPlayerScripts.Client
│           ├── ClientState.luau               # Estado compartido y callbacks entre scripts cliente
│           ├── MovementController.client.luau # Sprint, Crouch, Slide, Slide Cancel Jump y Dive
│           ├── CameraController.client.luau   # Cámara táctica fluida y consumo suave de retroceso
│           ├── CharacterAnimator.client.luau# Animaciones procedurales Motor6D (R15 y R6)
│           ├── WeaponController.client.luau # Disparo automático G18, trazadores, fogonazo y ADS
│           └── TouchHUD.client.luau         # Retícula, Hitmarker, marcador 1v1 y botones táctiles
├── default.project.json            # Mapa de servicios para Rojo
├── rokit.toml                      # Versiones fijadas de Rojo (7.7.1) y Lune (0.10.4)
├── index.html                      # HTML raíz del Hello World web
├── metadata.json                   # Metadatos del applet
├── package.json                    # Scripts web (dev, build, lint)
├── README.md                       # Guía principal y configuración desde el teléfono
├── ROADMAP.md                      # Plan por fases del proyecto
├── STRUCTURE.md                    # Este documento
├── AI_CONTEXT.md                   # Contexto técnico para asistentes IA
├── AGENTS.md                       # Reglas y convenciones para agentes que editen el repo
└── README_AI.md                    # Guía rápida de entrada para sesiones asistidas por IA
```

---

## 2. Mapeo dentro del `DataModel` de Roblox

Al ejecutar `rojo build` y luego `lune run tools/build_map.luau`, el archivo `build/game.rbxl` queda estructurado así:

- **`Workspace`**:
  - `MapaRuinas` *(generado por Lune)*:
    - `SueloCiudad` (calle asfaltada, líneas, aceras, escombros)
    - `PerimetroRuinas` (muros perimetrales y siluetas de edificios)
    - `EdificioRuinas_NO` y `EdificioRuinas_SE` (edificios simétricos con segundo piso y rampa)
    - `CoberturasTacticas` (barreras Jersey, autos destruidos, contenedor, sacos de arena, cajas)
    - `FarolaOeste` y `FarolaEste` (con `PointLight`)
    - `Spawns1v1` (`SpawnA` y `SpawnB`)
- **`Lighting`**:
  - Configuración de atardecer polvoriento + instancia `Atmosphere`.
- **`ReplicatedStorage`**:
  - `Shared` *(desde `src/roblox/shared/`)*: `Config`, `MovementConfig`, `WeaponStats` (`ModuleScript`).
  - `Remotes` *(generado por Lune)*: `MovementStateEvent`, `FireWeaponEvent`, `ReloadWeaponEvent`, `HitConfirmEvent`, `ScoreUpdateEvent` (`RemoteEvent`).
  - `Weapons` *(generado por Lune)*: `G18` (`Tool` multipieza soldado con `Weld`).
- **`ServerScriptService`**:
  - `Server` *(desde `src/roblox/server/`)*: `GameManager`, `MovementServer`, `WeaponServer` (`Script`).
- **`StarterPlayer.StarterPlayerScripts`**:
  - `Client` *(desde `src/roblox/client/`)*: `ClientState` (`ModuleScript`) y los 5 `LocalScript` de control, animación, cámara, arma y HUD táctil.

---

## 3. Flujo de comunicación en tiempo real

1. **Movimiento y Animación**:
   `TouchHUD` / Teclado → `MovementController` aplica velocidad/física (`LinearVelocity` en Slide, impulso en Dive) → envía estado a `MovementStateEvent` → `MovementServer` valida y guarda `MoveState` / `IsAiming` como atributos del `Character` → `CharacterAnimator` anima los `Motor6D` de todos los jugadores visibles.
2. **Combate con G18**:
   `TouchHUD` / Ratón → `WeaponController` dispara visualmente (trazador + luz + retroceso suave a `ClientState`) y envía el punto de mira a `FireWeaponEvent` → `WeaponServer` valida munición/cadencia, lanza `workspace:Raycast` desde el tirador respetando coberturas, aplica daño y responde por `HitConfirmEvent`.
