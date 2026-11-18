# AI Context (`AI_CONTEXT.md`)

Documento de referencia rápida para que cualquier IA comprenda al instante el contexto, las restricciones del usuario y la arquitectura técnica del proyecto antes de proponer o escribir código.

---

## 1. Contexto del usuario y flujo de trabajo
- **Dispositivo del usuario:** Trabaja **exclusivamente desde un teléfono móvil** (no tiene PC ni acceso a Roblox Studio).
- **Entorno de compilación:** Todo el proyecto de Roblox se compila y publica en la nube mediante **GitHub Actions** (runner Linux `ubuntu-latest`), ejecutando **Rojo** + **Lune** y subiendo el binario `build/game.rbxl` con la **API Open Cloud v1 de Roblox**.
- **Entorno web auxiliar:** El repositorio convive con una plantilla Vite/React (`src/App.tsx`). El usuario pidió explícitamente mantener la web únicamente como un **"Hello World"** limpio para que el entorno web compile sin errores.

---

## 2. Reglas críticas que NO se deben romper
1. **GitHub Action 100% manual:**
   - `.github/workflows/deploy-roblox.yml` solo puede tener el trigger `on: workflow_dispatch:`.
   - **Prohibido** añadir `push` o `pull_request` como triggers automáticos.
   - Los secretos `ROBLOX_API_KEY`, `ROBLOX_UNIVERSE_ID` y `ROBLOX_PLACE_ID` se leen desde `secrets.*` (con respaldo `|| vars.*` para los dos IDs).
2. **Construcción de mapa y armas sin Roblox Studio:**
   - Todo objeto 3D del mapa (`MapaRuinas`), iluminación (`Lighting` + `Atmosphere`), `RemoteEvent`s y modelos de armas (`G18`) se construyen programáticamente en **`tools/build_map.luau`** usando `@lune/roblox`.
   - Para unir piezas de un `Tool` en Lune, usar **`Weld`** con `C0` calculado explícitamente respecto al `Handle` (evitar depender de cálculo implícito de `WeldConstraint` de Studio). Todas las piezas del arma deben tener `CanCollide = false`, `Massless = true` y `Anchored = false`.
3. **Animaciones 100% procedurales:**
   - El usuario no puede subir animaciones desde Studio (`rbxassetid://` privados de terceros no funcionan en juegos propios).
   - Todas las posturas (`Slide`, `Dive`, `Crouch`, `Jump`, `Sprint`, `Aim`) se animan manipulando `Motor6D.C0` en `src/roblox/client/CharacterAnimator.client.luau`, soportando tanto **R15** como **R6**.
4. **Cámara equilibrada y jugabilidad móvil:**
   - La cámara (`CameraController.client.luau`) debe ser fluida mediante interpolación exponencial (`1 - math.exp(-k * dt)`), con *head-bob* mínimo y retroceso controlado que no maree ni desoriente.
   - Toda mecánica nueva (ej. placas, cambio de arma, granadas) debe incluir su botón táctil correspondiente en `TouchHUD.client.luau`, además de su tecla en PC.
5. **Seguridad de marcas registradas:**
   - Evitar nombres comerciales protegidos (marcas reales de armas, vehículos o franquicias) en nombres de archivos, carpetas, modelos o textos del juego. Usar identificadores genéricos o abreviados como `G18`, `VehiculoDestruido`, etc.

---

## 3. Stack y versiones activas
- **Rojo:** `rojo-rbx/rojo@7.7.1` (definido en `rokit.toml`)
- **Lune:** `lune-org/lune@0.10.4` (definido en `rokit.toml`)
- **Lenguaje de juego:** Luau (`--!strict`)
- **Validación en repositorio:** TypeScript + `node:test` (`src/roblox/validateConfig.ts` y `src/roblox/validateConfig.test.ts`)
