import assert from 'node:assert/strict'
import test from 'node:test'

import { PLATFORM_IOS } from '../../../../internal/domain/shared/platform.ts'
import { AppUpdateRuleRepository } from '../../../../internal/infrastructure/repository/appversion/appUpdateRuleRepository.ts'

test('AppUpdateRuleRepository.findMatchedPublishedRule returns the published 2.1.4 rule', async () => {
  const repository = new AppUpdateRuleRepository()

  const rule = await repository.findMatchedPublishedRule(PLATFORM_IOS, '2.1.4')

  assert.ok(rule)
  assert.equal(rule.id, 'ios-2-1-4')
})

test('AppUpdateRuleRepository.findMatchedPublishedRule returns null for other versions', async () => {
  const repository = new AppUpdateRuleRepository()

  const rule = await repository.findMatchedPublishedRule(PLATFORM_IOS, '2.1.3')

  assert.equal(rule, null)
})
