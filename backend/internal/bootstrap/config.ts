import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const DEFAULT_PORT = 4782
const DEFAULT_DEV_PUBLIC_API_KEY = 'dev-public-api-key'
const DEFAULT_DEV_CORS_ALLOW_ORIGINS = ['vscode-webview://*']
const DEFAULT_ENV_FILE_NAMES = ['.env', '.env.local'] as const
const BACKEND_ROOT_DIR = fileURLToPath(new URL('../../', import.meta.url))

export interface Config {
  httpAddr: string
  port: number
  corsAllowOrigins: string[]
  publicApiKeys: string[]
}

interface LoadConfigOptions {
  env?: NodeJS.ProcessEnv
  envFileDirectories?: readonly string[]
}

export function loadConfig(options: LoadConfigOptions = {}): Config {
  const env = loadEnv(options)
  const publicApiKeys = parsePublicAPIKeys(env)
  if (publicApiKeys.length === 0) {
    throw new Error('PUBLIC_API_KEYS must include at least one API key')
  }

  const corsAllowOrigins = parseCorsAllowOrigins(env)
  const httpAddr = env.HTTP_ADDR?.trim()
  if (httpAddr) {
    return {
      httpAddr,
      port: parsePort(httpAddr),
      corsAllowOrigins,
      publicApiKeys,
    }
  }

  const rawPort = env.PORT?.trim() || `${DEFAULT_PORT}`
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

function parsePublicAPIKeys(env: NodeJS.ProcessEnv): string[] {
  const publicApiKeys = parseCSV(env.PUBLIC_API_KEYS)
  if (publicApiKeys.length > 0) {
    return publicApiKeys
  }

  if (env.NODE_ENV === 'production') {
    return []
  }

  return [DEFAULT_DEV_PUBLIC_API_KEY]
}

function parseCorsAllowOrigins(env: NodeJS.ProcessEnv): string[] {
  const corsAllowOrigins = parseCSV(env.CORS_ALLOW_ORIGINS)
  if (corsAllowOrigins.length > 0) {
    return corsAllowOrigins
  }

  if (env.NODE_ENV === 'production') {
    return []
  }

  return [...DEFAULT_DEV_CORS_ALLOW_ORIGINS]
}

function loadEnv(options: LoadConfigOptions): NodeJS.ProcessEnv {
  const env: NodeJS.ProcessEnv = { ...(options.env ?? process.env) }
  const externallyDefinedKeys = new Set(
    Object.entries(env)
      .filter(([, value]) => value !== undefined)
      .map(([key]) => key),
  )

  for (const directory of resolveEnvFileDirectories(options.envFileDirectories)) {
    for (const fileName of DEFAULT_ENV_FILE_NAMES) {
      const filePath = join(directory, fileName)
      if (!existsSync(filePath)) {
        continue
      }

      const fileValues = parseDotEnv(readFileSync(filePath, 'utf8'))
      for (const [key, value] of Object.entries(fileValues)) {
        if (externallyDefinedKeys.has(key)) {
          continue
        }
        env[key] = value
      }
    }
  }

  return env
}

function resolveEnvFileDirectories(customDirectories?: readonly string[]): string[] {
  if (customDirectories && customDirectories.length > 0) {
    return [...new Set(customDirectories)]
  }

  return [BACKEND_ROOT_DIR]
}

function parseDotEnv(raw: string): Record<string, string> {
  const values: Record<string, string> = {}

  for (const line of raw.split(/\r?\n/)) {
    const trimmedLine = line.trim()
    if (trimmedLine === '' || trimmedLine.startsWith('#')) {
      continue
    }

    const normalizedLine = trimmedLine.startsWith('export ')
      ? trimmedLine.slice('export '.length).trim()
      : trimmedLine
    const separatorIndex = normalizedLine.indexOf('=')
    if (separatorIndex <= 0) {
      continue
    }

    const key = normalizedLine.slice(0, separatorIndex).trim()
    if (key === '') {
      continue
    }

    const rawValue = normalizedLine.slice(separatorIndex + 1).trim()
    values[key] = parseDotEnvValue(rawValue)
  }

  return values
}

function parseDotEnvValue(rawValue: string): string {
  if (rawValue.startsWith('"') && rawValue.endsWith('"')) {
    return rawValue
      .slice(1, -1)
      .replace(/\\n/g, '\n')
      .replace(/\\"/g, '"')
      .replace(/\\\\/g, '\\')
  }

  if (rawValue.startsWith("'") && rawValue.endsWith("'")) {
    return rawValue.slice(1, -1)
  }

  return rawValue.replace(/\s+#.*$/, '').trim()
}
