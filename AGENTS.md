# Agents Guidelines (`AGENTS.md`)

Instrucciones operativas obligatorias para cualquier agente o asistente de programación que trabaje sobre este repositorio.

---

## 1. Antes de editar código
1. Lee `AI_CONTEXT.md` y `STRUCTURE.md` para ubicarte en la arquitectura **Rojo + Lune** sin Roblox Studio.
2. Verifica si el usuario pidió explícitamente **"No hagas cambios"**; en ese caso solo investiga o responde sin tocar archivos.
3. No modifiques `src/App.tsx`, `index.html` ni añadas interfaz web compleja salvo que el usuario pida cambiar la parte web (actualmente debe permanecer como un "Hello World").

---

## 2. Convenciones de código Luau (`src/roblox/` y `tools/`)
- **Tipado estricto:** Todos los archivos `.luau` deben comenzar con `--!strict`.
- **Comentarios explicativos en español:** Cada archivo debe incluir en su cabecera un bloque `--[=[ ... ]=]` explicando claramente qué hace la lógica que contiene.
- **Convención de archivos Rojo:**
  - `*.server.luau` → `Script` en `ServerScriptService.Server`.
  - `*.client.luau` → `LocalScript` en `StarterPlayerScripts.Client`.
  - `*.luau` (sin `.server` ni `.client`) → `ModuleScript`.
- **Separación de responsabilidades:**
  - Configuraciones y balances numéricos van en `src/roblox/shared/`.
  - Nunca confíes daño, munición ni cadencia solo al cliente: `WeaponServer.server.luau` siempre valida y ejecuta el `Raycast` real.
  - Comunicación entre módulos cliente pasa por `src/roblox/client/ClientState.luau` para evitar dependencias circulares.

---

## 3. Reglas para `tools/build_map.luau` (Lune)
- Importa siempre los tipos de `@lune/roblox` (`roblox.Instance`, `roblox.Vector3`, `roblox.CFrame`, `roblox.Color3`, `roblox.Enum`).
- Mantén el mapa simétrico o tácticamente equilibrado para 1v1, con coberturas bajas (`~3.5 - 4` studs) y altas (`~7+` studs).
- Si agregas nuevos `RemoteEvent` o `Tool`, créalos en `tools/build_map.luau` (o asegúrate de que existan en `default.project.json`) para evitar bloqueos infinitos en `WaitForChild`.

---

## 4. Reglas para `.github/workflows/deploy-roblox.yml`
- Mantén **únicamente** `on: workflow_dispatch:` (no agregues `push` ni `pull_request`).
- Mantén el orden de pasos: `checkout` → `setup-rokit` → `rojo build` → `lune run tools/build_map.luau` → `upload-artifact` → `curl` Open Cloud v1.
- Sigue leyendo `ROBLOX_UNIVERSE_ID` y `ROBLOX_PLACE_ID` con `${{ secrets.* || vars.* }}`.

---

## 5. Verificación obligatoria tras cada cambio
Antes de dar una tarea por terminada, ejecuta y confirma que pasen sin errores:
1. Pruebas unitarias de configuración y pipeline:
   ```bash
   npx --yes tsx --test src/roblox/validateConfig.test.ts
   ```
2. Verificación TypeScript y compilación web:
   ```bash
   npm run lint
   npm run build
   ```
3. Si añades nuevos archivos `.luau` obligatorios o reglas nuevas en el workflow, actualiza `src/roblox/validateConfig.ts` y `src/roblox/validateConfig.test.ts` en consecuencia.
