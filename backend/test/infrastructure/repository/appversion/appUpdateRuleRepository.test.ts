import assert from 'node:assert/strict'
import test from 'node:test'

import { PLATFORM_IOS } from '../../../../internal/domain/shared/platform.ts'
import { AppUpdateRuleRepository } from '../../../../internal/infrastructure/repository/appversion/appUpdateRuleRepository.ts'

test('AppUpdateRuleRepository.findMatchedPublishedRule returns force update rule', async () => {
  const repository = new AppUpdateRuleRepository()

  const rule = await repository.findMatchedPublishedRule(PLATFORM_IOS, '0.9.0')

  assert.ok(rule)
  assert.equal(rule.id, 'ios-force-update')
})

test('AppUpdateRuleRepository.findMatchedPublishedRule returns latest rule', async () => {
  const repository = new AppUpdateRuleRepository()

  const rule = await repository.findMatchedPublishedRule(PLATFORM_IOS, '1.2.0')

  assert.ok(rule)
  assert.equal(rule.id, 'ios-latest')
})
