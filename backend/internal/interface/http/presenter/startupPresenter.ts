import type { Context } from 'hono'

import type { AdVisibilityResult } from '../../../application/usecase/advisibility/adVisibilityInteractor.ts'
import type { UpdateCheckResult } from '../../../application/usecase/updatecheck/updateCheckInteractor.ts'
import { writeJSON } from '../response/json.ts'
import { buildStartupResponseBody } from '../response/startupResponse.ts'

export class StartupPresenter {
  present(
    c: Context,
    updateResult: UpdateCheckResult,
    adVisibilityChecks: ReadonlyArray<{ adID: string; visibility: AdVisibilityResult }>,
  ) {
    return writeJSON(c, 200, buildStartupResponseBody(updateResult, adVisibilityChecks))
  }
}
