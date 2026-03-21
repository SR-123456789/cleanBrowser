import assert from 'node:assert/strict'
import test from 'node:test'

import { AppUpdateRuleRepository } from '../../../../internal/infrastructure/repository/appversion/appUpdateRuleRepository.ts'
import { UpdateCheckInteractor } from '../../../../internal/application/usecase/updatecheck/updateCheckInteractor.ts'

test('UpdateCheckInteractor.execute maps update result for client', async () => {
  const interactor = new UpdateCheckInteractor(new AppUpdateRuleRepository())

  const result = await interactor.execute({ appVersion: '0.9.0' })

  assert.equal(result.mustUpdate, true)
  assert.equal(result.shouldUpdate, true)
  assert.equal(result.repeatUpdatePrompt, true)
  assert.equal(result.updateLink, 'https://apps.apple.com/app/id1234567890')
  assert.equal(result.message, 'このバージョンはサポート対象外です。App Storeから最新版へ更新してください。')
})
