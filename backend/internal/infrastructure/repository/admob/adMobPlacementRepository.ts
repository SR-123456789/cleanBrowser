import type { AdMobPlacementRepositoryInterface } from '../../../application/port/admob/adMobPlacementRepositoryInterface.ts'
import { AdMobPlacement, type AdMobPlacementProps } from '../../../domain/admob/adMobPlacement.ts'
import { NotFoundError } from '../../../domain/shared/errors.ts'
import { PLATFORM_IOS } from '../../../domain/shared/platform.ts'

type AdMobPlacementRecord = AdMobPlacementProps

export class AdMobPlacementRepository implements AdMobPlacementRepositoryInterface {
  readonly #records: AdMobPlacementRecord[]

  constructor(records?: AdMobPlacementRecord[]) {
    const sourceRecords = records ?? [
      {
        id: 'daily_interstitial',
        name: 'Daily Interstitial',
        platform: PLATFORM_IOS,
        status: 'active',
        minAppVersion: '2.1.3',
        maxAppVersion: '2.1.3',
        createdAt: new Date('2026-03-18T00:00:00Z'),
        updatedAt: new Date('2026-03-18T00:00:00Z'),
      },
    ]

    sourceRecords.forEach((record) => {
      AdMobPlacement.reconstruct(record)
    })
    this.#records = sourceRecords.map(cloneRecord)
  }

  async findById(id: string): Promise<AdMobPlacement> {
    const record = this.#records.find((candidate) => candidate.id === id)
    if (!record) {
      throw new NotFoundError()
    }

    return AdMobPlacement.reconstruct(record)
  }
}

function cloneRecord(record: AdMobPlacementRecord): AdMobPlacementRecord {
  return {
    ...record,
    startAt: cloneDate(record.startAt),
    endAt: cloneDate(record.endAt),
    createdAt: new Date(record.createdAt),
    updatedAt: new Date(record.updatedAt),
  }
}

function cloneDate(value?: Date): Date | undefined {
  return value ? new Date(value) : undefined
}
