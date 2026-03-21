const DEFAULT_PORT = 4782
const DEFAULT_DEV_PUBLIC_API_KEY = 'dev-public-api-key'
const DEFAULT_DEV_CORS_ALLOW_ORIGINS = ['vscode-webview://*']

export interface Config {
  httpAddr: string
  port: number
  corsAllowOrigins: string[]
  publicApiKeys: string[]
}

export function loadConfig(): Config {
  const publicApiKeys = parsePublicAPIKeys()
  if (publicApiKeys.length === 0) {
    throw new Error('PUBLIC_API_KEYS must include at least one API key')
  }

  const corsAllowOrigins = parseCorsAllowOrigins()
  const httpAddr = process.env.HTTP_ADDR?.trim()
  if (httpAddr) {
    return {
      httpAddr,
      port: parsePort(httpAddr),
      corsAllowOrigins,
      publicApiKeys,
    }
  }

  const rawPort = process.env.PORT?.trim() || `${DEFAULT_PORT}`
  const port = Number.parseInt(rawPort, 10)
  if (!Number.isInteger(port) || port <= 0) {
    throw new Error('PORT must be a positive integer')
  }

  return {
    httpAddr: `:${port}`,
    port,
    corsAllowOrigins,
    publicApiKeys,
  }
}

function parsePort(httpAddr: string): number {
  const normalized = httpAddr.startsWith(':') ? httpAddr.slice(1) : httpAddr.split(':').at(-1) ?? ''
  const port = Number.parseInt(normalized, 10)
  if (!Number.isInteger(port) || port <= 0) {
    throw new Error('HTTP_ADDR must include a valid port')
  }
  return port
}

function parseCSV(rawValue: string | undefined): string[] {
  return (rawValue ?? '')
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value !== '')
}

function parsePublicAPIKeys(): string[] {
  const publicApiKeys = parseCSV(process.env.PUBLIC_API_KEYS)
  if (publicApiKeys.length > 0) {
    return publicApiKeys
  }

  if (process.env.NODE_ENV === 'production') {
    return []
  }

  return [DEFAULT_DEV_PUBLIC_API_KEY]
}

function parseCorsAllowOrigins(): string[] {
  const corsAllowOrigins = parseCSV(process.env.CORS_ALLOW_ORIGINS)
  if (corsAllowOrigins.length > 0) {
    return corsAllowOrigins
  }

  if (process.env.NODE_ENV === 'production') {
    return []
  }

  return [...DEFAULT_DEV_CORS_ALLOW_ORIGINS]
}
