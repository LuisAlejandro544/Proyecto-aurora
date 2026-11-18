# README para IA (`README_AI.md`)

Guía rápida para iniciar cualquier nueva sesión de desarrollo asistido por IA sobre **Ruinas 1v1**.

---

## Orden de lectura recomendado para la IA
1. **`AI_CONTEXT.md`** — Entiende por qué no hay Roblox Studio, por qué el Action es manual y cómo funcionan las animaciones procedurales y el HUD móvil.
2. **`AGENTS.md`** — Revisa las reglas de código Luau (`--!strict`), Lune y verificación obligatoria.
3. **`STRUCTURE.md`** — Ubica exactamente dónde va cada módulo (Shared, Server, Client, Lune `tools/`).
4. **`ROADMAP.md`** — Consulta qué fase sigue y qué piezas ya están implementadas.

---

## Estado actual del sistema (resumen en 30 segundos)
- **Juego:** Shooter 1v1 en ciudad en ruinas (`MapaRuinas`), estilo de movimiento Warzone (*Sprint*, *Crouch*, *Slide*, *Slide Cancel + Saltar*, *Dolphin Dive*), animaciones procedurales `Motor6D` y pistola automática `G18`.
- **Compilación:** GitHub Actions manual (`Compilar Mapa y Subir a Roblox`) ejecuta `rojo build` + `lune run tools/build_map.luau` y publica `build/game.rbxl` en Roblox Open Cloud API.
- **Web (`src/App.tsx`):** Solo muestra `Hello World` para mantener el entorno web compilable.

---

## Cómo pedir cambios de forma efectiva (para el dueño del proyecto)
Cuando quieras agregar algo nuevo desde el teléfono, indica:
1. **Qué fase o mecánica quieres** (por ejemplo: *"Implementa el sistema de rondas de la Fase 2 del ROADMAP"* o *"Agrega un subfusil como arma alternativa"*).
2. **Si afecta controles móviles**, dónde prefieres el botón en pantalla o si debe reemplazar/acompañar a uno existente.
3. **Al terminar los cambios**, súbelos al repositorio y lanza manualmente **Actions → Compilar Mapa y Subir a Roblox → Run workflow** para probarlo directo en la app de Roblox de tu teléfono.
