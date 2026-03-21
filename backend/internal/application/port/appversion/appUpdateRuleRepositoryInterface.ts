import type { AppUpdateRule } from '../../../domain/appversion/updateRule.ts'
import type { Platform } from '../../../domain/shared/platform.ts'

export interface AppUpdateRuleRepositoryInterface {
  findMatchedPublishedRule(platform: Platform, currentVersion: string): Promise<AppUpdateRule | null>
}
