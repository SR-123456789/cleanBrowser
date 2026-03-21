import type { AdVisibilityResult } from '../../../application/usecase/advisibility/adVisibilityInteractor.ts'

export interface AdVisibilityResponseBody {
  isShow: boolean
}

export function buildAdVisibilityResponseBody(result: AdVisibilityResult): AdVisibilityResponseBody {
  return {
    isShow: result.isShow,
  }
}
