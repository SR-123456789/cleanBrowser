import { ValidationError } from '../shared/errors.ts'
import { type Platform, validatePlatform } from '../shared/platform.ts'
import { compareVersions, validateVersion } from '../shared/version.ts'

export type AppUpdateRuleStatus = 'draft' | 'published' | 'retired'

export interface AppUpdateRuleProps {
  id: string
  platform: Platform
  minVersion?: string
  maxVersion?: string
  mustUpdate: boolean
  shouldUpdate: boolean
  repeatUpdatePrompt: boolean
  storeUrl?: string
  message: string
  status: AppUpdateRuleStatus
  createdAt: Date
  updatedAt: Date
}

export class AppUpdateRule {
  readonly id: string
  readonly platform: Platform
  readonly minVersion?: string
  readonly maxVersion?: string
  readonly mustUpdate: boolean
  readonly shouldUpdate: boolean
  readonly repeatUpdatePrompt: boolean
  readonly storeUrl?: string
  readonly message: string
  readonly status: AppUpdateRuleStatus
  readonly createdAt: Date
  readonly updatedAt: Date

  private constructor(props: AppUpdateRuleProps) {
    this.id = props.id
    this.platform = props.platform
    this.minVersion = props.minVersion
    this.maxVersion = props.maxVersion
    this.mustUpdate = props.mustUpdate
    this.shouldUpdate = props.shouldUpdate
    this.repeatUpdatePrompt = props.repeatUpdatePrompt
    this.storeUrl = props.storeUrl
    this.message = props.message
    this.status = props.status
    this.createdAt = new Date(props.createdAt)
    this.updatedAt = new Date(props.updatedAt)
  }

  static reconstruct(props: AppUpdateRuleProps): AppUpdateRule {
    validateAppUpdateRule(props)
    return new AppUpdateRule(props)
  }

  isPublished(): boolean {
    return this.status === 'published'
  }

  matchesVersion(currentVersion: string): boolean {
    if (this.minVersion && compareVersions(currentVersion, this.minVersion) < 0) {
      return false
    }

    if (this.maxVersion && compareVersions(currentVersion, this.maxVersion) > 0) {
      return false
    }

    return true
  }
}

export function validateAppUpdateRule(rule: AppUpdateRuleProps): void {
  if (rule.id.trim() === '') {
    throw new ValidationError('id is required')
  }

  validatePlatform(rule.platform)

  if (rule.minVersion) {
    validateVersion(rule.minVersion)
  }

  if (rule.maxVersion) {
    validateVersion(rule.maxVersion)
  }

  if (rule.minVersion && rule.maxVersion && compareVersions(rule.minVersion, rule.maxVersion) > 0) {
    throw new ValidationError('minVersion must be less than or equal to maxVersion')
  }

  if (rule.message.trim() === '') {
    throw new ValidationError('message is required')
  }

  if (rule.status !== 'draft' && rule.status !== 'published' && rule.status !== 'retired') {
    throw new ValidationError('status must be one of draft, published, retired')
  }
}
