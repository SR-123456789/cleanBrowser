import type { Context } from 'hono'

import type { HealthPresenter } from '../presenter/healthPresenter.ts'

export class HealthController {
  readonly #presenter: HealthPresenter

  constructor(presenter: HealthPresenter) {
    this.#presenter = presenter
  }

  handle(c: Context) {
    return this.#presenter.present(c)
  }
}
