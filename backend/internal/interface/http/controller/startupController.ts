import type { Context } from 'hono'

import type { AdVisibilityUseCase } from '../../../application/usecase/advisibility/adVisibilityInteractor.ts'
import type { UpdateCheckUseCase } from '../../../application/usecase/updatecheck/updateCheckInteractor.ts'
import type { StartupPresenter } from '../presenter/startupPresenter.ts'

const STARTUP_AD_IDS = ['daily_interstitial'] as const

export class StartupController {
  readonly #updateCheckUseCase: UpdateCheckUseCase
  readonly #adVisibilityUseCase: AdVisibilityUseCase
  readonly #presenter: StartupPresenter

  constructor(
    updateCheckUseCase: UpdateCheckUseCase,
    adVisibilityUseCase: AdVisibilityUseCase,
    presenter: StartupPresenter,
  ) {
    this.#updateCheckUseCase = updateCheckUseCase
    this.#adVisibilityUseCase = adVisibilityUseCase
    this.#presenter = presenter
  }

  async handle(c: Context) {
    const update = await this.#updateCheckUseCase.execute({
      appVersion: c.req.query('appVersion') ?? '',
    })

    const adVisibilityChecks = await Promise.all(
      STARTUP_AD_IDS.map(async (adID) => {
        const visibility = await this.#adVisibilityUseCase.execute({ adId: adID })
        return {
          adID,
          visibility,
        }
      }),
    )

    return this.#presenter.present(c, update, adVisibilityChecks)
  }
}
