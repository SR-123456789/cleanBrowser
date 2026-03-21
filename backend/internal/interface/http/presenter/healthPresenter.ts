import type { Context } from 'hono'

import { writeJSON } from '../response/json.ts'

export class HealthPresenter {
  present(c: Context) {
    return writeJSON(c, 200, { status: 'ok' })
  }
}
