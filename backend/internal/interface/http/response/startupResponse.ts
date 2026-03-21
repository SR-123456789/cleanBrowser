import type { AdVisibilityResult } from '../../../application/usecase/advisibility/adVisibilityInteractor.ts'
import type { UpdateCheckResult } from '../../../application/usecase/updatecheck/updateCheckInteractor.ts'
import {
  buildAdVisibilityResponseBody,
  type AdVisibilityResponseBody,
} from './adVisibilityResponse.ts'

export interface UpdateCheckResponseBody {
  mustUpdate: boolean
  shouldUpdate: boolean
  repeatUpdatePrompt: boolean
  updateLink: string
  message: string
}

export interface StartupAdResponseBody extends AdVisibilityResponseBody {
  adID: string
}

export interface StartupResponseBody {
  update: UpdateCheckResponseBody
  ads: StartupAdResponseBody[]
}

export function buildStartupResponseBody(
  updateResult: UpdateCheckResult,
  adVisibilityChecks: ReadonlyArray<{ adID: string; visibility: AdVisibilityResult }>,
): StartupResponseBody {
  return {
    update: buildUpdateCheckResponseBody(updateResult),
    ads: adVisibilityChecks.map(({ adID, visibility }) => ({
      adID,
      ...buildAdVisibilityResponseBody(visibility),
    })),
  }
}

function buildUpdateCheckResponseBody(result: UpdateCheckResult): UpdateCheckResponseBody {
  return {
    mustUpdate: result.mustUpdate,
    shouldUpdate: result.shouldUpdate,
    repeatUpdatePrompt: result.repeatUpdatePrompt,
    updateLink: result.updateLink,
    message: result.message,
  }
}
