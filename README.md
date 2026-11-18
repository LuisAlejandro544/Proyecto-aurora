# Ruinas 1v1 — Shooter Táctico en Roblox (Rojo + Lune + GitHub Actions Manual)

Juego 1v1 de disparos estilo Warzone ambientado en una **ciudad en ruinas pequeña**, compilado y publicado sin PC ni Roblox Studio usando **Rojo + Lune** en un **GitHub Action exclusivamente manual**.

---

## ¿Qué incluye?

### 1. Mapa en Ciudad en Ruinas (`tools/build_map.luau` con Lune)
- Calle central asfaltada con aceras, escombros y farolas inclinadas con luz cálida.
- Edificios destruidos simétricos en ambos flancos con **segunda planta**, rampas de escombros y ventanas bajas para disparar desde cobertura.
- Coberturas tácticas estilo Warzone: barreras Jersey de hormigón, autos quemados/destruidos, contenedor militar, sacos de arena y cajas.
- Dos spawns opuestos (`SpawnA` y `SpawnB`) e iluminación atmosférica de atardecer polvoriento.

### 2. Movimiento y Animaciones Procedurales (`src/roblox/client/` + `server/`)
Funciona tanto en **R15** como en **R6** sin necesitar IDs de animaciones externas:
- **Sprint táctico**: aumenta velocidad y abre suavemente el FOV de cámara.
- **Agacharse (`Crouch`)**: baja la postura y la cámara para cubrirte detrás de barreras y ventanas.
- **Deslizar (`Slide`)**: impulso rápido hacia adelante con animación de pierna extendida y torso inclinado.
- **Slide Cancel + Saltar**: al presionar **Saltar** o **Deslizar** mientras deslizas, cancelas al instante la inercia y saltas limpio.
- **Lanzarse al suelo (`Dolphin Dive`)**: impulso aéreo hacia adelante con animación horizontal boca abajo y breve recuperación al caer.
- **Cámara suave**: interpolación exponencial de FOV, offset de hombro derecho y balanceo mínimo para mantener fluidez sin mareos.

### 3. Pistola Automática G18
- Construida multipieza en `ReplicatedStorage.Weapons.G18` por `tools/build_map.luau` (corredera metálica, armazón, cargador extendido de 33 balas y mira verde).
- Disparo automático (`880 RPM` aprox.), trazadores, fogonazo, apuntado (`ADS`), recarga (`1.45s`), validación autoritativa en servidor que respeta todas las coberturas y `Hitmarker` en pantalla.
- Botones táctiles dedicados en pantalla para jugar desde el teléfono (`DISPARAR`, `APUNTAR`, `RECARGAR`, `SPRINT`, `DESLIZAR`, `SALTAR`, `LANZARSE`).

---

## Cómo compilar y subir a Roblox (Solo Manual)

El workflow `.github/workflows/deploy-roblox.yml` **nunca** se ejecuta solo con commits o pull requests:

1. Configura en tu repo (**Settings -> Secrets and variables -> Actions**):
   - Secret: `ROBLOX_API_KEY` (con permiso `universe-places:write` e IP `0.0.0.0/0`).
   - Variables: `ROBLOX_UNIVERSE_ID` y `ROBLOX_PLACE_ID`.
2. Desde tu teléfono en GitHub ve a la pestaña **Actions**.
3. Selecciona **Compilar Mapa y Subir a Roblox**.
4. Pulsa **Run workflow** -> elige `Published` (o `Saved`) -> **Run workflow**.
