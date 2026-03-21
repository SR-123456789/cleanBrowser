import type { Context } from 'hono'

import type { AdVisibilityUseCase } from '../../../application/usecase/advisibility/adVisibilityInteractor.ts'
import type { AdVisibilityPresenter } from '../presenter/adVisibilityPresenter.ts'

export class AdVisibilityController {
  readonly #adVisibilityUseCase: AdVisibilityUseCase
  readonly #presenter: AdVisibilityPresenter

  constructor(adVisibilityUseCase: AdVisibilityUseCase, presenter: AdVisibilityPresenter) {
    this.#adVisibilityUseCase = adVisibilityUseCase
    this.#presenter = presenter
  }

  async handle(c: Context) {
    const result = await this.#adVisibilityUseCase.execute({
      adId: c.req.param('adID'),
    })

    return this.#presenter.present(c, result)
  }
}
