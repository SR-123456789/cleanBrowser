import assert from 'node:assert/strict'
import test from 'node:test'

import type { Config } from '../../../../internal/bootstrap/config.ts'
import { createApp } from '../../../../internal/bootstrap/container.ts'
import { PUBLIC_API_KEY_HEADER } from '../../../../internal/interface/http/middleware/publicApiAuth.ts'
import type { AdVisibilityResponseBody } from '../../../../internal/interface/http/response/adVisibilityResponse.ts'
import type { StartupResponseBody } from '../../../../internal/interface/http/response/startupResponse.ts'

interface HealthResponseBody {
  status: string
}

interface ErrorResponseBody {
  error: string
}

function testConfig(overrides: Partial<Config> = {}): Config {
  return {
    httpAddr: ':4782',
    port: 4782,
    corsAllowOrigins: ['http://localhost:3000'],
    publicApiKeys: ['test-public-api-key'],
    ...overrides,
  }
}

async function parseResponseBody<T>(response: Response): Promise<T> {
  const body: unknown = JSON.parse(await response.text())
  return body as T
}

test('router serves startup endpoint', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/api/v1/public/startup?appVersion=0.9.0', {
    headers: {
      [PUBLIC_API_KEY_HEADER]: 'test-public-api-key',
    },
  })
  const payload = await parseResponseBody<StartupResponseBody>(response)

  assert.equal(response.status, 200)
  assert.equal(payload.update.mustUpdate, true)
  assert.equal(payload.update.repeatUpdatePrompt, true)
  assert.equal(Array.isArray(payload.ads), true)
  assert.equal(payload.ads.length, 1)
  assert.equal(payload.ads[0].adID, 'daily_interstitial')
  assert.equal(payload.ads[0].isShow, true)
})

test('router serves ad visibility endpoint', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/api/v1/public/ads/daily_interstitial/visibility', {
    headers: {
      [PUBLIC_API_KEY_HEADER]: 'test-public-api-key',
    },
  })
  const payload = await parseResponseBody<AdVisibilityResponseBody>(response)

  assert.equal(response.status, 200)
  assert.equal(payload.isShow, true)
})

test('router serves health endpoint', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/healthz')
  const payload = await parseResponseBody<HealthResponseBody>(response)

  assert.equal(response.status, 200)
  assert.equal(payload.status, 'ok')
})

test('router rejects public requests without api key', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/api/v1/public/startup?appVersion=1.0.0')
  const payload = await parseResponseBody<ErrorResponseBody>(response)

  assert.equal(response.status, 401)
  assert.equal(payload.error, 'invalid api key')
})

test('router includes CORS header for allowed origins', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/api/v1/public/startup?appVersion=1.0.0', {
    headers: {
      Origin: 'http://localhost:3000',
      [PUBLIC_API_KEY_HEADER]: 'test-public-api-key',
    },
  })

  assert.equal(response.status, 200)
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:3000')
})

test('router includes CORS header for VS Code webview origins when wildcard is configured', async () => {
  const app = createApp(
    testConfig({
      corsAllowOrigins: ['vscode-webview://*'],
    }),
  )

  const response = await app.request('/api/v1/public/startup?appVersion=1.0.0', {
    headers: {
      Origin: 'vscode-webview://12345abcdef',
      [PUBLIC_API_KEY_HEADER]: 'test-public-api-key',
    },
  })

  assert.equal(response.status, 200)
  assert.equal(response.headers.get('access-control-allow-origin'), 'vscode-webview://12345abcdef')
})

test('router handles CORS preflight for public endpoints', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/api/v1/public/startup', {
    method: 'OPTIONS',
    headers: {
      Origin: 'http://localhost:3000',
      'Access-Control-Request-Method': 'GET',
    },
  })

  assert.equal(response.status, 204)
  assert.equal(response.headers.get('access-control-allow-origin'), 'http://localhost:3000')
  assert.match(response.headers.get('access-control-allow-methods') ?? '', /GET/)
})

test('router omits CORS header for disallowed origins', async () => {
  const app = createApp(testConfig())

  const response = await app.request('/api/v1/public/startup?appVersion=1.0.0', {
    headers: {
      Origin: 'http://evil.example',
      [PUBLIC_API_KEY_HEADER]: 'test-public-api-key',
    },
  })

  assert.equal(response.status, 200)
  assert.equal(response.headers.get('access-control-allow-origin'), null)
})
