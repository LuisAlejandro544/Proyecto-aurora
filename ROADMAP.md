# Roadmap — Ruinas 1v1

Plan de evolución por fases para el juego de disparos 1v1 estilo Warzone compilado sin Roblox Studio (Rojo + Lune + GitHub Actions).

---

## Fase 1 — Base jugable 1v1 *(Completada)*
- [x] Pipeline en la nube con **Rojo** (`7.7.1`) + **Lune** (`0.10.4`) gestionado por `rokit.toml`.
- [x] Workflow manual en GitHub Actions (`.github/workflows/deploy-roblox.yml` con `workflow_dispatch`) que compila `build/game.rbxl` y publica vía Open Cloud API.
- [x] Mapa pequeño de **ciudad en ruinas** (`MapaRuinas`) generado por `tools/build_map.luau`: calle central, aceras, edificios simétricos con segunda planta y rampas, vehículos destruidos, barreras Jersey, contenedor militar, farolas y spawns opuestos (`SpawnA` / `SpawnB`).
- [x] Pistola automática **G18** multipieza (`ReplicatedStorage.Weapons.G18`) con disparo automático, trazadores, fogonazo, apuntado (ADS), recarga y Raycast autoritativo en servidor.
- [x] Movimiento estilo Warzone: Sprint táctico, Agacharse, Deslizar (*Slide*), *Slide Cancel + Saltar* y Lanzarse al suelo (*Dolphin Dive*).
- [x] Animaciones procedurales `Motor6D` compatibles con R15 y R6 sincronizadas entre jugadores.
- [x] Cámara fluida equilibrada sobre el hombro y HUD táctil completo para teléfono (`TouchHUD.client.luau`).

---

## Fase 2 — Flujo de duelo 1v1 y retroalimentación *(Siguiente)*
- [ ] **Sistema de rondas formal** (ej. al mejor de 5 o 7 rondas, cuenta regresiva de 3 segundos antes de empezar, congelamiento breve en spawn y cambio de lado entre rondas).
- [ ] **Sistema de blindaje / placas tácticas** (hasta 2 o 3 placas equipables con botón táctil dedicado para replicar el ritmo de duelos de Warzone).
- [ ] **Audio táctico**: sonidos para disparo de G18, recarga, impacto en cuerpo/cabeza, pasos y deslizamiento sobre asfalto/hormigón.
- [ ] **Ajustes rápidos en pantalla (móvil)**: menú compacto en HUD para ajustar sensibilidad de cámara táctil y activar/desactivar auto-sprint.

---

## Fase 3 — Arsenal modular y equipamiento táctico
- [ ] **Múltiples armas en `WeaponStats.luau` y `tools/build_map.luau`**: añadir un subfusil táctico, un fusil de asalto y una escopeta manteniendo nombres genéricos (sin marcas registradas).
- [ ] **Ranura Principal + Secundaria (`G18`)** con botón rápido de cambio de arma en el HUD móvil.
- [ ] **Equipamiento táctico**: granada de fragmentación y granada de humo para cruzar calles abiertas o forzar coberturas.
- [ ] **Mejoras visuales de daño**: indicador direccional de daño recibido en pantalla y pantalla breve de victoria/derrota al terminar la partida.

---

## Fase 4 — Variedad de mapas, progresión y calidad de código
- [ ] **Rotación de arenas 1v1** (ej. *Ciudad en Ruinas*, *Estación Abandonada*, *Patio Industrial*) seleccionables o aleatorias al iniciar duelo.
- [ ] **Persistencia de estadísticas** (`DataStoreService`): guardar victorias, bajas y racha de cada jugador.
- [ ] **Análisis estático en GitHub Actions**: integrar `Selene` (linter de Luau) y `StyLua` en `rokit.toml` y en el workflow manual para detectar errores antes de publicar en Roblox.
