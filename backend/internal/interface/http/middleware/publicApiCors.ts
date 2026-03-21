import { cors } from 'hono/cors'

export interface PublicApiCorsConfig {
  allowedOrigins: readonly string[]
}

export function publicApiCors(config: PublicApiCorsConfig) {
  return cors({
    origin: (origin) => {
      if (origin === '') {
        return null
      }

      return matchesAllowedOrigin(origin, config.allowedOrigins) ? origin : null
    },
    allowMethods: ['GET', 'OPTIONS'],
    allowHeaders: ['Accept', 'Content-Type', 'X-API-Key'],
  })
}

function matchesAllowedOrigin(origin: string, allowedOrigins: readonly string[]): boolean {
  return allowedOrigins.some((candidate) => {
    if (candidate === '*') {
      return true
    }

    if (candidate.endsWith('*')) {
      return origin.startsWith(candidate.slice(0, -1))
    }

    return origin === candidate
  })
}
