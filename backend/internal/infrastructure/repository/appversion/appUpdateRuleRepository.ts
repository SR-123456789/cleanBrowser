import type { AppUpdateRuleRepositoryInterface } from '../../../application/port/appversion/appUpdateRuleRepositoryInterface.ts'
import { AppUpdateRule, type AppUpdateRuleProps } from '../../../domain/appversion/updateRule.ts'
import { PLATFORM_IOS, type Platform } from '../../../domain/shared/platform.ts'
import { compareVersions } from '../../../domain/shared/version.ts'

type AppUpdateRuleRecord = AppUpdateRuleProps

export class AppUpdateRuleRepository implements AppUpdateRuleRepositoryInterface {
  readonly #records: AppUpdateRuleRecord[]

  constructor(records?: AppUpdateRuleRecord[]) {
    const sourceRecords = records ?? [
      {
        id: 'ios-2-1-4',
        platform: PLATFORM_IOS,
        minVersion: '2.1.3',
        maxVersion: '2.1.3',
        mustUpdate: false,
        shouldUpdate: false,
        repeatUpdatePrompt: true,
        storeUrl: 'https://apps.apple.com/jp/app/nopeek-%E6%9C%80%E5%BC%B7%E3%83%97%E3%83%A9%E3%82%A4%E3%83%99%E3%83%BC%E3%83%88%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6-%E3%82%B7%E3%83%BC%E3%82%AF%E3%83%AC%E3%83%83%E3%83%88%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6/id6749825483',
        message: 'アップデートする事で広告の表示が減少します',
        status: 'published',
        createdAt: new Date('2026-03-18T00:00:00Z'),
        updatedAt: new Date('2026-03-18T00:00:00Z'),
      },
      {
        id: 'ios-2-1-4',
        platform: PLATFORM_IOS,
        minVersion: '2.1.4',
        maxVersion: '2.1.4',
        mustUpdate: true,
        shouldUpdate: false,
        repeatUpdatePrompt: false,
        storeUrl: 'https://apps.apple.com/jp/app/nopeek-%E6%9C%80%E5%BC%B7%E3%83%97%E3%83%A9%E3%82%A4%E3%83%99%E3%83%BC%E3%83%88%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6-%E3%82%B7%E3%83%BC%E3%82%AF%E3%83%AC%E3%83%83%E3%83%88%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6/id6749825483',
        message: '現在のバージョンは最新です。',
        status: 'published',
        createdAt: new Date('2026-03-18T00:00:00Z'),
        updatedAt: new Date('2026-03-18T00:00:00Z'),
      },
    ]

    sourceRecords.forEach((record) => {
      AppUpdateRule.reconstruct(record)
    })
    this.#records = sourceRecords.map(cloneRecord)
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
