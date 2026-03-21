import type { MiddlewareHandler } from 'hono'

import { UnauthorizedError } from '../../../domain/shared/errors.ts'

export const PUBLIC_API_KEY_HEADER = 'X-API-Key'

export interface PublicApiAuthConfig {
  apiKeys: ReadonlySet<string>
}

export function publicApiAuth(config: PublicApiAuthConfig): MiddlewareHandler {
  return async (c, next) => {
    if (c.req.method === 'OPTIONS') {
      await next()
      return
    }

    const apiKey = c.req.header(PUBLIC_API_KEY_HEADER)?.trim() ?? ''
    if (apiKey === '' || !config.apiKeys.has(apiKey)) {
      throw new UnauthorizedError('invalid api key')
    }

    await next()
  }
}
