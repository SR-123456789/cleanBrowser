import type { AdMobPlacement } from '../../../domain/admob/adMobPlacement.ts'

export interface AdMobPlacementRepositoryInterface {
  findById(id: string): Promise<AdMobPlacement>
}
