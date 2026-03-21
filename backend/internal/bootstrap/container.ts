import type { Config } from './config.ts'
import { AdVisibilityInteractor } from '../application/usecase/advisibility/adVisibilityInteractor.ts'
import { AdMobPlacementRepository } from '../infrastructure/repository/admob/adMobPlacementRepository.ts'
import { AppUpdateRuleRepository } from '../infrastructure/repository/appversion/appUpdateRuleRepository.ts'
import { AdVisibilityController } from '../interface/http/controller/adVisibilityController.ts'
import { HealthController } from '../interface/http/controller/healthController.ts'
import { StartupController } from '../interface/http/controller/startupController.ts'
import { AdVisibilityPresenter } from '../interface/http/presenter/adVisibilityPresenter.ts'
import { ErrorPresenter } from '../interface/http/presenter/errorPresenter.ts'
import { HealthPresenter } from '../interface/http/presenter/healthPresenter.ts'
import { StartupPresenter } from '../interface/http/presenter/startupPresenter.ts'
import { buildRouter } from '../interface/http/router/router.ts'
import { UpdateCheckInteractor } from '../application/usecase/updatecheck/updateCheckInteractor.ts'

export function createApp(config: Config) {
  const adMobPlacementRepository = new AdMobPlacementRepository()
  const appUpdateRuleRepository = new AppUpdateRuleRepository()

  const adVisibilityUseCase = new AdVisibilityInteractor(adMobPlacementRepository)
  const updateCheckUseCase = new UpdateCheckInteractor(appUpdateRuleRepository)

  const errorPresenter = new ErrorPresenter()
  const healthPresenter = new HealthPresenter()
  const adVisibilityPresenter = new AdVisibilityPresenter()
  const startupPresenter = new StartupPresenter()

  const healthController = new HealthController(healthPresenter)
  const adVisibilityController = new AdVisibilityController(adVisibilityUseCase, adVisibilityPresenter)
  const startupController = new StartupController(updateCheckUseCase, adVisibilityUseCase, startupPresenter)

  return buildRouter({
    errorPresenter,
    healthController,
    adVisibilityController,
    startupController,
    security: {
      corsAllowOrigins: config.corsAllowOrigins,
      publicApiKeys: config.publicApiKeys,
    },
  })
}
