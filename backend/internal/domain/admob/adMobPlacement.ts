import { ValidationError } from '../shared/errors.ts'
import { type Platform, validatePlatform } from '../shared/platform.ts'

export type AdMobPlacementStatus = 'draft' | 'active' | 'inactive'

export interface AdMobPlacementProps {
  id: string
  name: string
  platform: Platform
  status: AdMobPlacementStatus
  startAt?: Date
  endAt?: Date
  createdAt: Date
  updatedAt: Date
}

export class AdMobPlacement {
  readonly id: string
  readonly name: string
  readonly platform: Platform
  readonly status: AdMobPlacementStatus
  readonly startAt?: Date
  readonly endAt?: Date
  readonly createdAt: Date
  readonly updatedAt: Date

  private constructor(props: AdMobPlacementProps) {
    this.id = props.id
    this.name = props.name
    this.platform = props.platform
    this.status = props.status
    this.startAt = cloneDate(props.startAt)
    this.endAt = cloneDate(props.endAt)
    this.createdAt = new Date(props.createdAt)
    this.updatedAt = new Date(props.updatedAt)
  }

  static reconstruct(props: AdMobPlacementProps): AdMobPlacement {
    validateAdMobPlacement(props)
    return new AdMobPlacement(props)
  }

  isVisibleAt(now: Date): boolean {
    if (this.status !== 'active') {
      return false
    }

    if (this.startAt && now < this.startAt) {
      return false
    }

    if (this.endAt && now > this.endAt) {
      return false
    }

    return true
  }
}

export function validateAdMobPlacement(placement: AdMobPlacementProps): void {
  if (placement.id.trim() === '') {
    throw new ValidationError('id is required')
  }

  if (placement.name.trim() === '') {
    throw new ValidationError('name is required')
  }

  validatePlatform(placement.platform)

  if (
    placement.status !== 'draft' &&
    placement.status !== 'active' &&
    placement.status !== 'inactive'
  ) {
    throw new ValidationError('status must be one of draft, active, inactive')
  }

  if (placement.startAt && placement.endAt && placement.startAt > placement.endAt) {
    throw new ValidationError('startAt must be before or equal to endAt')
  }
}

function cloneDate(value?: Date): Date | undefined {
  return value ? new Date(value) : undefined
}
