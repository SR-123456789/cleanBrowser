import type { AdMobPlacementRepositoryInterface } from '../../port/admob/adMobPlacementRepositoryInterface.ts'
import { isNotFoundError, ValidationError } from '../../../domain/shared/errors.ts'
import { validateVersion } from '../../../domain/shared/version.ts'

export interface Input {
  adId: string
  appVersion: string
}

export interface AdVisibilityResult {
  isShow: boolean
}

export interface AdVisibilityUseCase {
  execute(input: Input): Promise<AdVisibilityResult>
}

export class AdVisibilityInteractor implements AdVisibilityUseCase {
  readonly #repo: AdMobPlacementRepositoryInterface
  readonly #now: () => Date

  constructor(repo: AdMobPlacementRepositoryInterface, now: () => Date = () => new Date()) {
    this.#repo = repo
    this.#now = now
  }

  async execute(input: Input): Promise<AdVisibilityResult> {
    const adId = input.adId.trim()
    if (adId === '') {
      throw new ValidationError('adID is required')
    }

    const appVersion = input.appVersion.trim()
    if (appVersion === '') {
      throw new ValidationError('appVersion is required')
    }

    validateVersion(appVersion)

    try {
      const placement = await this.#repo.findById(adId)
      return { isShow: placement.isVisibleAt(this.#now(), appVersion) }
    } catch (error) {
      if (isNotFoundError(error)) {
        return { isShow: false }
      }
      throw error
    }
  }
}
