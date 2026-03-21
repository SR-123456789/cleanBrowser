import type { Context } from 'hono'

import { isNotFoundError, isUnauthorizedError, isValidationError } from '../../../domain/shared/errors.ts'

export interface ErrorResponse {
  error: string
}

export function writeJSON<T>(c: Context, status: number, payload: T) {
  return c.json(payload, status)
}

export function writeError(c: Context, status: number, message: string) {
  return writeJSON<ErrorResponse>(c, status, { error: message })
}

export function statusAndMessage(error: unknown): { status: number; message: string } {
  if (isUnauthorizedError(error)) {
    return { status: 401, message: error.message }
  }

  if (isNotFoundError(error)) {
    return { status: 404, message: 'resource not found' }
  }

  if (isValidationError(error)) {
    return { status: 400, message: error.message }
  }

  return { status: 500, message: 'internal server error' }
}
