import { serve } from '@hono/node-server'

import { createApp } from '../../internal/bootstrap/container.ts'
import { loadConfig } from '../../internal/bootstrap/config.ts'

const config = loadConfig()
const app = createApp(config)

console.log(`backend listening on ${config.httpAddr}`)

serve({
  fetch: app.fetch,
  port: config.port,
})
