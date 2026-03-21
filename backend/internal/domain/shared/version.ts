import { ValidationError } from './errors.ts'

export function validateVersion(value: string): void {
  parseVersion(value)
}

export function compareVersions(left: string, right: string): number {
  const leftParts = parseVersion(left)
  const rightParts = parseVersion(right)
  const maxLength = Math.max(leftParts.length, rightParts.length)

  for (let index = 0; index < maxLength; index += 1) {
    const leftValue = leftParts[index] ?? 0
    const rightValue = rightParts[index] ?? 0

    if (leftValue < rightValue) {
      return -1
    }

    if (leftValue > rightValue) {
      return 1
    }
  }

  return 0
}

function parseVersion(value: string): number[] {
  let trimmed = value.trim()
  trimmed = trimmed.startsWith('v') ? trimmed.slice(1) : trimmed
  if (trimmed === '') {
    throw new ValidationError('version must not be empty')
  }

  const separatorIndex = trimmed.search(/[+-]/)
  if (separatorIndex >= 0) {
    trimmed = trimmed.slice(0, separatorIndex)
  }

  return trimmed.split('.').map((segment) => {
    if (segment === '') {
      throw new ValidationError('version must be a dotted numeric string like 1.2.3')
    }

    const parsed = Number.parseInt(segment, 10)
    if (!Number.isInteger(parsed) || parsed < 0) {
      throw new ValidationError('version must be a dotted numeric string like 1.2.3')
    }

    return parsed
  })
}
