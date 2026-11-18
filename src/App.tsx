/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * Componente principal de la web (App).
 * Su única función es mostrar un "Hello World" limpio para que el entorno
 * web compile y sirva correctamente, mientras el proyecto real de Roblox
 * vive en `default.project.json`, `src/roblox/` y `.github/workflows/`.
 */
export default function App() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-white text-neutral-900">
      <h1 className="text-3xl font-semibold tracking-tight">Hello World</h1>
    </main>
  );
}
