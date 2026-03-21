import type { Context } from 'hono'

import { statusAndMessage, writeError } from '../response/json.ts'

export class ErrorPresenter {
  present(c: Context, error: unknown) {
    const { status, message } = statusAndMessage(error)
    return writeError(c, status, message)
  }
}
