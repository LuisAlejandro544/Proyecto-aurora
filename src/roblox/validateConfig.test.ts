/**
 * Tests unitarios que verifican la integridad del proyecto Rojo + Lune,
 * los scripts Luau del juego 1v1, el pipeline de animaciones por keyframes
 * en GitHub Releases y el workflow manual de despliegue a Roblox.
 */

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  validateManualDeployWorkflow,
  validateRojoLuneProject,
  type RojoProject,
} from './validateConfig';

const ROOT = process.cwd();

test('default.project.json tiene la estructura completa de Rojo para 1v1 Ruinas', () => {
  const raw = fs.readFileSync(path.join(ROOT, 'default.project.json'), 'utf8');
  const project = JSON.parse(raw) as RojoProject;
  assert.deepEqual(validateRojoLuneProject(project), []);
});

test('rokit.toml fija tanto rojo como lune', () => {
  const toml = fs.readFileSync(path.join(ROOT, 'rokit.toml'), 'utf8');
  assert.match(toml, /rojo\s*=\s*"rojo-rbx\/rojo@/);
  assert.match(toml, /lune\s*=\s*"lune-org\/lune@/);
});

test('tools/build_map.luau, generadores de animaciones y todos los módulos Luau requeridos existen', () => {
  const requiredFiles = [
    'tools/build_map.luau',
    'tools/generate_animations.py',
    'tools/compile_animations.py',
    'tools/blender_export_r15.py',
    'src/roblox/shared/Config.luau',
    'src/roblox/shared/MovementConfig.luau',
    'src/roblox/shared/WeaponStats.luau',
    'src/roblox/shared/AnimationClips.luau',
    'src/roblox/server/GameManager.server.luau',
    'src/roblox/server/MovementServer.server.luau',
    'src/roblox/server/WeaponServer.server.luau',
    'src/roblox/server/RagdollService.luau',
    'src/roblox/server/BotManager.luau',
    'src/roblox/client/ClientState.luau',
    'src/roblox/client/MovementController.client.luau',
    'src/roblox/client/CameraController.client.luau',
    'src/roblox/client/KeyframeAnimator.client.luau',
    'src/roblox/client/WeaponController.client.luau',
    'src/roblox/client/TouchHUD.client.luau',
  ];

  for (const relPath of requiredFiles) {
    assert.equal(
      fs.existsSync(path.join(ROOT, relPath)),
      true,
      `Falta el archivo requerido: ${relPath}`
    );
  }
  assert.equal(
    fs.existsSync(path.join(ROOT, 'src/roblox/client/CharacterAnimator.client.luau')),
    false,
    'El animador procedural antiguo debe estar eliminado'
  );
});

test('WeaponStats.luau define daño para cabeza, pecho, brazos, manos, piernas y pies', () => {
  const stats = fs.readFileSync(path.join(ROOT, 'src/roblox/shared/WeaponStats.luau'), 'utf8');
  for (const zone of ['Head', 'Chest', 'Arm', 'Hand', 'Leg', 'Foot']) {
    assert.match(stats, new RegExp(`\\b${zone}\\s*=`));
  }
});

test('tools/build_map.luau declara los RemoteEvents de modo, estado y trazadores', () => {
  const mapScript = fs.readFileSync(path.join(ROOT, 'tools/build_map.luau'), 'utf8');
  for (const ev of ['SelectModeEvent', 'MatchStateEvent', 'WeaponTracerEvent']) {
    assert.match(mapScript, new RegExp(`"${ev}"`));
  }
});

test('.github/workflows/deploy-roblox.yml es estrictamente manual, descarga Release y usa Rojo + Lune', () => {
  const yaml = fs.readFileSync(
    path.join(ROOT, '.github/workflows/deploy-roblox.yml'),
    'utf8'
  );
  assert.deepEqual(validateManualDeployWorkflow(yaml), []);
  assert.match(yaml, /animations_tag:/);
  assert.match(yaml, /gh release download/);
  assert.match(yaml, /compile_animations\.py/);
});

test('.github/workflows/publish-animations-release.yml es manual y pide Tag para subir al Release', () => {
  const yaml = fs.readFileSync(
    path.join(ROOT, '.github/workflows/publish-animations-release.yml'),
    'utf8'
  );
  const onSectionMatch = yaml.match(/^on:\s*([\s\S]*?)^permissions:/m);
  const onSection = onSectionMatch ? onSectionMatch[1] : '';
  assert.equal(onSection.includes('workflow_dispatch:'), true);
  assert.equal(/^\s*push\s*:/m.test(onSection), false);
  assert.equal(/^\s*pull_request\s*:/m.test(onSection), false);
  assert.match(yaml, /release_tag:/);
  assert.match(yaml, /gh release create/);
  assert.match(yaml, /generate_animations\.py/);
});

test('validateManualDeployWorkflow rechaza triggers automáticos push o pull_request', () => {
  const autoYaml = `
on:
  push:
    branches: [main]
  workflow_dispatch:
jobs:
  build:
`;
  const errors = validateManualDeployWorkflow(autoYaml);
  assert.equal(
    errors.some((e) => e.includes('NO debe ejecutarse en push')),
    true
  );
});
