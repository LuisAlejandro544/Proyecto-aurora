/**
 * Módulo de validación estática para el pipeline Rojo + Lune + GitHub Actions manual.
 * Verifica la estructura de `default.project.json`, que `rokit.toml` incluya Rojo y Lune,
 * y que `.github/workflows/deploy-roblox.yml` sea exclusivamente manual (`workflow_dispatch`).
 */

export interface RojoProject {
  name: string;
  tree: {
    $className: string;
    Workspace?: { $className: string; [key: string]: unknown };
    ReplicatedStorage?: { $className: string; [key: string]: unknown };
    ServerScriptService?: { $className: string; [key: string]: unknown };
    StarterPlayer?: {
      $className: string;
      StarterPlayerScripts?: { $className: string; [key: string]: unknown };
    };
    [serviceName: string]: unknown;
  };
}

export function validateRojoLuneProject(project: RojoProject): string[] {
  const errors: string[] = [];

  if (!project.name || typeof project.name !== 'string') {
    errors.push('El proyecto Rojo debe tener un campo "name" válido.');
  }

  if (project.tree?.$className !== 'DataModel') {
    errors.push('La raíz "tree.$className" debe ser "DataModel".');
  }

  if (project.tree?.Workspace?.$className !== 'Workspace') {
    errors.push('Falta Workspace en tree.');
  }

  const rep = project.tree?.ReplicatedStorage as Record<string, unknown> | undefined;
  if (!rep || rep.$className !== 'ReplicatedStorage') {
    errors.push('Falta ReplicatedStorage en tree.');
  } else {
    if (!rep.Shared) errors.push('Falta ReplicatedStorage.Shared.');
    if (!rep.Remotes) errors.push('Falta ReplicatedStorage.Remotes.');
    if (!rep.Weapons) errors.push('Falta ReplicatedStorage.Weapons.');
  }

  const sss = project.tree?.ServerScriptService as Record<string, unknown> | undefined;
  if (!sss || sss.$className !== 'ServerScriptService' || !sss.Server) {
    errors.push('Falta ServerScriptService.Server.');
  }

  const sp = project.tree?.StarterPlayer;
  const sps = sp?.StarterPlayerScripts as Record<string, unknown> | undefined;
  if (!sps || sps.$className !== 'StarterPlayerScripts' || !sps.Client) {
    errors.push('Falta StarterPlayer.StarterPlayerScripts.Client.');
  }

  return errors;
}

export function validateManualDeployWorkflow(yamlContent: string): string[] {
  const errors: string[] = [];

  // Verificar que sea SOLO manual (sin push ni pull_request en el bloque `on:`)
  const onSectionMatch = yamlContent.match(/^on:\s*([\s\S]*?)^jobs:/m);
  const onSection = onSectionMatch ? onSectionMatch[1] : '';

  if (!onSection.includes('workflow_dispatch:')) {
    errors.push('El workflow debe incluir trigger manual workflow_dispatch.');
  }
  if (/^\s*push\s*:/m.test(onSection)) {
    errors.push('El workflow NO debe ejecutarse en push (debe ser solo manual).');
  }
  if (/^\s*pull_request\s*:/m.test(onSection)) {
    errors.push('El workflow NO debe ejecutarse en pull_request (debe ser solo manual).');
  }

  if (!yamlContent.includes('CompeyDev/setup-rokit')) {
    errors.push('El workflow debe instalar Rokit (Rojo + Lune).');
  }
  if (!yamlContent.includes('rojo build default.project.json --output build/game.rbxl')) {
    errors.push('El workflow debe ejecutar "rojo build default.project.json --output build/game.rbxl".');
  }
  if (!yamlContent.includes('lune run tools/build_map.luau')) {
    errors.push('El workflow debe ejecutar "lune run tools/build_map.luau".');
  }
  if (
    !yamlContent.includes(
      'https://apis.roblox.com/universes/v1/${ROBLOX_UNIVERSE_ID}/places/${ROBLOX_PLACE_ID}/versions'
    )
  ) {
    errors.push('El workflow debe publicar usando Roblox Open Cloud API v1.');
  }
  if (!yamlContent.includes('secrets.ROBLOX_API_KEY')) {
    errors.push('El workflow debe leer secrets.ROBLOX_API_KEY.');
  }

  return errors;
}
