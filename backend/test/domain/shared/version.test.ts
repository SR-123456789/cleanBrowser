import assert from 'node:assert/strict'
import test from 'node:test'

import { compareVersions, validateVersion } from '../../../internal/domain/shared/version.ts'

test('compareVersions handles semver-like values', () => {
  assert.equal(compareVersions('1.2', '1.2.0'), 0)
  assert.equal(compareVersions('1.2.3', '1.2.4'), -1)
  assert.equal(compareVersions('2.0.0', '1.9.9'), 1)
  assert.equal(compareVersions('v1.3.0-beta.1', '1.2.9'), 1)
})

test('validateVersion rejects invalid value', () => {
  assert.throws(() => validateVersion('1..2'))
})
