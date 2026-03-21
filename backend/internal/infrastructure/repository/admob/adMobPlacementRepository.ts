import type { AdMobPlacementRepositoryInterface } from '../../../application/port/admob/adMobPlacementRepositoryInterface.ts'
import { AdMobPlacement, type AdMobPlacementProps } from '../../../domain/admob/adMobPlacement.ts'
import { NotFoundError } from '../../../domain/shared/errors.ts'
import { PLATFORM_IOS } from '../../../domain/shared/platform.ts'

type AdMobPlacementRecord = AdMobPlacementProps

export class AdMobPlacementRepository implements AdMobPlacementRepositoryInterface {
  readonly #records: AdMobPlacementRecord[]

  constructor(records = defaultRecords()) {
    records.forEach((record) => {
      AdMobPlacement.reconstruct(record)
    })
    this.#records = records.map(cloneRecord)
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

function defaultRecords(): AdMobPlacementRecord[] {
  return [
    {
      id: 'daily_interstitial',
      name: 'Daily Interstitial',
      platform: PLATFORM_IOS,
      status: 'active',
      createdAt: new Date('2026-03-18T00:00:00Z'),
      updatedAt: new Date('2026-03-18T00:00:00Z'),
    },
    {
      id: 'settings_banner',
      name: 'Settings Banner',
      platform: PLATFORM_IOS,
      status: 'inactive',
      createdAt: new Date('2026-03-18T00:00:00Z'),
      updatedAt: new Date('2026-03-18T00:00:00Z'),
    },
  ]
}

function cloneDate(value?: Date): Date | undefined {
  return value ? new Date(value) : undefined
}
