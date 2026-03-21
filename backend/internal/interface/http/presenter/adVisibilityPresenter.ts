import type { Context } from 'hono'

import type { AdVisibilityResult } from '../../../application/usecase/advisibility/adVisibilityInteractor.ts'
import { buildAdVisibilityResponseBody } from '../response/adVisibilityResponse.ts'
import { writeJSON } from '../response/json.ts'

export class AdVisibilityPresenter {
  present(c: Context, result: AdVisibilityResult) {
    return writeJSON(c, 200, buildAdVisibilityResponseBody(result))
  }
}
