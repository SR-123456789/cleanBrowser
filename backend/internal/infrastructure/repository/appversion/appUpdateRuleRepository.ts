import type { AppUpdateRuleRepositoryInterface } from '../../../application/port/appversion/appUpdateRuleRepositoryInterface.ts'
import { AppUpdateRule, type AppUpdateRuleProps } from '../../../domain/appversion/updateRule.ts'
import { PLATFORM_IOS, type Platform } from '../../../domain/shared/platform.ts'
import { compareVersions } from '../../../domain/shared/version.ts'

type AppUpdateRuleRecord = AppUpdateRuleProps

export class AppUpdateRuleRepository implements AppUpdateRuleRepositoryInterface {
  readonly #records: AppUpdateRuleRecord[]

  constructor(records = defaultRecords()) {
    records.forEach((record) => {
      AppUpdateRule.reconstruct(record)
    })
    this.#records = records.map(cloneRecord)
  }

  async findMatchedPublishedRule(platform: Platform, currentVersion: string): Promise<AppUpdateRule | null> {
    const matchedRule = this.#records
      .map((record) => AppUpdateRule.reconstruct(record))
      .filter((rule) => rule.platform === platform && rule.isPublished() && rule.matchesVersion(currentVersion))
      .sort((left, right) => {
        const minComparison = compareBound(right.minVersion, left.minVersion, 'low')
        if (minComparison !== 0) {
          return minComparison
        }

        const maxComparison = compareBound(left.maxVersion, right.maxVersion, 'high')
        if (maxComparison !== 0) {
          return maxComparison
        }

        return right.updatedAt.getTime() - left.updatedAt.getTime()
      })[0]

    return matchedRule ?? null
  }
}

function compareBound(left: string | undefined, right: string | undefined, mode: 'low' | 'high'): number {
  if (left === right) {
    return 0
  }

  if (!left) {
    return mode === 'low' ? -1 : 1
  }

  if (!right) {
    return mode === 'low' ? 1 : -1
  }

  return compareVersions(left, right)
}

function cloneRecord(record: AppUpdateRuleRecord): AppUpdateRuleRecord {
  return {
    ...record,
    createdAt: new Date(record.createdAt),
    updatedAt: new Date(record.updatedAt),
  }
}

function defaultRecords(): AppUpdateRuleRecord[] {
  return [
    {
      id: 'ios-force-update',
      platform: PLATFORM_IOS,
      maxVersion: '1.0.0',
      mustUpdate: true,
      shouldUpdate: true,
      repeatUpdatePrompt: true,
      storeUrl: 'https://apps.apple.com/app/id1234567890',
      message: 'このバージョンはサポート対象外です。App Storeから最新版へ更新してください。',
      status: 'published',
      createdAt: new Date('2026-03-01T00:00:00Z'),
      updatedAt: new Date('2026-03-01T00:00:00Z'),
    },
    {
      id: 'ios-recommend-update',
      platform: PLATFORM_IOS,
      minVersion: '1.0.1',
      maxVersion: '1.1.9',
      mustUpdate: false,
      shouldUpdate: true,
      repeatUpdatePrompt: false,
      storeUrl: 'https://apps.apple.com/app/id1234567890',
      message: '新しいバージョンがあります。App Storeから更新できます。',
      status: 'published',
      createdAt: new Date('2026-03-18T00:00:00Z'),
      updatedAt: new Date('2026-03-18T00:00:00Z'),
    },
    {
      id: 'ios-latest',
      platform: PLATFORM_IOS,
      minVersion: '1.2.0',
      mustUpdate: false,
      shouldUpdate: false,
      repeatUpdatePrompt: false,
      storeUrl: 'https://apps.apple.com/app/id1234567890',
      message: '現在のバージョンは最新です。',
      status: 'published',
      createdAt: new Date('2026-03-18T00:00:00Z'),
      updatedAt: new Date('2026-03-18T00:00:00Z'),
    },
  ]
}
