import { PLATFORM_IOS } from '../../../domain/shared/platform.ts'
import type { AppUpdateRuleRepositoryInterface } from '../../port/appversion/appUpdateRuleRepositoryInterface.ts'
import { NotFoundError, ValidationError } from '../../../domain/shared/errors.ts'
import { validateVersion } from '../../../domain/shared/version.ts'

export interface Input {
  appVersion: string
}

export interface UpdateCheckResult {
  mustUpdate: boolean
  shouldUpdate: boolean
  repeatUpdatePrompt: boolean
  updateLink: string
  message: string
}

export interface UpdateCheckUseCase {
  execute(input: Input): Promise<UpdateCheckResult>
}

export class UpdateCheckInteractor implements UpdateCheckUseCase {
  readonly #repo: AppUpdateRuleRepositoryInterface

  constructor(repo: AppUpdateRuleRepositoryInterface) {
    this.#repo = repo
  }

  async execute(input: Input): Promise<UpdateCheckResult> {
    const currentVersion = input.appVersion.trim()
    if (currentVersion === '') {
      throw new ValidationError('appVersion is required')
    }
    validateVersion(currentVersion)

    const matchedRule = await this.#repo.findMatchedPublishedRule(PLATFORM_IOS, currentVersion)
    if (!matchedRule) {
      throw new NotFoundError()
    }

    return {
      mustUpdate: matchedRule.mustUpdate,
      shouldUpdate: matchedRule.shouldUpdate,
      repeatUpdatePrompt: matchedRule.repeatUpdatePrompt,
      updateLink: matchedRule.storeUrl ?? '',
      message: matchedRule.message,
    }
  }
}
