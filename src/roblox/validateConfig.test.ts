/**
 * Tests unitarios que verifican la integridad del proyecto Rojo + Lune,
 * los scripts Luau del juego 1v1 y el workflow manual de GitHub Actions.
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

test('tools/build_map.luau y todos los módulos Luau requeridos existen', () => {
  const requiredFiles = [
    'tools/build_map.luau',
    'src/roblox/shared/Config.luau',
    'src/roblox/shared/MovementConfig.luau',
    'src/roblox/shared/WeaponStats.luau',
    'src/roblox/server/GameManager.server.luau',
    'src/roblox/server/MovementServer.server.luau',
    'src/roblox/server/WeaponServer.server.luau',
    'src/roblox/client/ClientState.luau',
    'src/roblox/client/MovementController.client.luau',
    'src/roblox/client/CameraController.client.luau',
    'src/roblox/client/CharacterAnimator.client.luau',
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
});

test('.github/workflows/deploy-roblox.yml es estrictamente manual y usa Rojo + Lune', () => {
  const yaml = fs.readFileSync(
    path.join(ROOT, '.github/workflows/deploy-roblox.yml'),
    'utf8'
  );
  assert.deepEqual(validateManualDeployWorkflow(yaml), []);
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
