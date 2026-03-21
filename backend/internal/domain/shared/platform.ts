import { ValidationError } from './errors.ts'

export const PLATFORM_IOS = 'ios'
export const PLATFORM_ANDROID = 'android'

export type Platform = typeof PLATFORM_IOS | typeof PLATFORM_ANDROID

export function validatePlatform(platform: Platform): void {
  if (platform === PLATFORM_IOS || platform === PLATFORM_ANDROID) {
    return
  }

  throw new ValidationError('platform must be one of ios or android')
}
