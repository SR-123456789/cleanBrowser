import { Hono } from 'hono'

import type { AdVisibilityController } from '../controller/adVisibilityController.ts'
import type { HealthController } from '../controller/healthController.ts'
import type { StartupController } from '../controller/startupController.ts'
import { publicApiAuth } from '../middleware/publicApiAuth.ts'
import { publicApiCors } from '../middleware/publicApiCors.ts'
import type { ErrorPresenter } from '../presenter/errorPresenter.ts'

export interface RouterHandlers {
  errorPresenter: ErrorPresenter
  healthController: HealthController
  adVisibilityController: AdVisibilityController
  startupController: StartupController
  security: PublicApiSecurity
}

export interface PublicApiSecurity {
  corsAllowOrigins: readonly string[]
  publicApiKeys: readonly string[]
}

export function buildRouter(handlers: RouterHandlers) {
  const app = new Hono()
  app.onError((error, c) => handlers.errorPresenter.present(c, error))

  app.get('/healthz', (c) => handlers.healthController.handle(c))

  const publicRoutes = new Hono()
  publicRoutes.use('*', publicApiCors({ allowedOrigins: handlers.security.corsAllowOrigins }))
  publicRoutes.use('*', publicApiAuth({ apiKeys: new Set(handlers.security.publicApiKeys) }))
  publicRoutes.get('/startup', (c) => handlers.startupController.handle(c))
  publicRoutes.get('/ads/:adID/visibility', (c) => handlers.adVisibilityController.handle(c))

  app.route('/api/v1/public', publicRoutes)

  return app
}
