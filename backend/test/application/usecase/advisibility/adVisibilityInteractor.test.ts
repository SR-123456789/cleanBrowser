import assert from 'node:assert/strict'
import test from 'node:test'

import { AdMobPlacementRepository } from '../../../../internal/infrastructure/repository/admob/adMobPlacementRepository.ts'
import { AdVisibilityInteractor } from '../../../../internal/application/usecase/advisibility/adVisibilityInteractor.ts'

test('AdVisibilityInteractor.execute returns visibility when appVersion is in range', async () => {
  const interactor = new AdVisibilityInteractor(
    new AdMobPlacementRepository(),
    () => new Date('2026-03-19T00:00:00Z'),
  )

  const result = await interactor.execute({ adId: 'daily_interstitial', appVersion: '2.1.4' })

  assert.equal(result.isShow, true)
})

test('AdVisibilityInteractor.execute returns false when appVersion is out of range', async () => {
  const interactor = new AdVisibilityInteractor(
    new AdMobPlacementRepository(),
    () => new Date('2026-03-19T00:00:00Z'),
  )

  const result = await interactor.execute({ adId: 'daily_interstitial', appVersion: '2.1.5' })

  assert.equal(result.isShow, false)
})
