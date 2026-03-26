import assert from 'node:assert/strict'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'

import { loadConfig } from '../../internal/bootstrap/config.ts'

test('loadConfig loads PUBLIC_API_KEYS from .env', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'cleanbrowser-config-'))

  try {
    writeFileSync(
      join(tempDir, '.env'),
      [
        'PUBLIC_API_KEYS=ios-app-key,admin-key',
        'PORT=4900',
      ].join('\n'),
    )

    const config = loadConfig({
      env: { NODE_ENV: 'development' },
      envFileDirectories: [tempDir],
    })

    assert.deepEqual(config.publicApiKeys, ['ios-app-key', 'admin-key'])
    assert.equal(config.port, 4900)
    assert.equal(config.httpAddr, ':4900')
  } finally {
    rmSync(tempDir, { recursive: true, force: true })
  }
})

test('.env.local overrides .env and explicit env still wins', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'cleanbrowser-config-'))

  try {
    writeFileSync(join(tempDir, '.env'), 'PUBLIC_API_KEYS=from-dot-env\n')
    writeFileSync(join(tempDir, '.env.local'), 'PUBLIC_API_KEYS=from-dot-env-local\n')

    const fromFiles = loadConfig({
      env: { NODE_ENV: 'development' },
      envFileDirectories: [tempDir],
    })
    assert.deepEqual(fromFiles.publicApiKeys, ['from-dot-env-local'])

    const fromExplicitEnv = loadConfig({
      env: {
        NODE_ENV: 'development',
        PUBLIC_API_KEYS: 'from-shell',
      },
      envFileDirectories: [tempDir],
    })
    assert.deepEqual(fromExplicitEnv.publicApiKeys, ['from-shell'])
  } finally {
    rmSync(tempDir, { recursive: true, force: true })
  }
})
