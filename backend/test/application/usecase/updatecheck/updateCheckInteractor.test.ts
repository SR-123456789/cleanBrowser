import assert from 'node:assert/strict'
import test from 'node:test'

import { AppUpdateRuleRepository } from '../../../../internal/infrastructure/repository/appversion/appUpdateRuleRepository.ts'
import { UpdateCheckInteractor } from '../../../../internal/application/usecase/updatecheck/updateCheckInteractor.ts'

test('UpdateCheckInteractor.execute maps update result for client', async () => {
  const interactor = new UpdateCheckInteractor(new AppUpdateRuleRepository())

  const result = await interactor.execute({ appVersion: '2.1.4' })

  assert.equal(result.mustUpdate, false)
  assert.equal(result.shouldUpdate, false)
  assert.equal(result.repeatUpdatePrompt, false)
  assert.equal(result.updateLink, 'https://apps.apple.com/app/id1234567890')
  assert.equal(result.message, '現在のバージョンは最新です。')
})
