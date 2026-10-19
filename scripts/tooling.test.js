import { spawnSync } from 'node:child_process'
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import process from 'node:process'
import { afterEach, expect, it } from 'vitest'

const directories = []

afterEach(() => {
  for (const directory of directories.splice(0))
    rmSync(directory, { recursive: true, force: true })
})

function verifyCommit (message) {
  const directory = mkdtempSync(join(tmpdir(), 'tfs-commit-'))
  directories.push(directory)
  const path = join(directory, 'COMMIT_EDITMSG')
  writeFileSync(path, message)
  return spawnSync(process.execPath, ['scripts/verifyCommit.js', path], { encoding: 'utf8' })
}

it('accepts conventional commit messages', () => {
  expect(verifyCommit('deps: upgrade development tooling').status).toBe(0)
})

it('rejects invalid commit messages with a readable error', () => {
  const result = verifyCommit('invalid commit message')
  expect(result.status).toBe(1)
  expect(result.stderr).toContain('invalid commit message format')
})

it('loads release tooling and validates versions before prompting', () => {
  const result = spawnSync(process.execPath, ['scripts/release.js', 'types_from_serializers', 'invalid'], { encoding: 'utf8' })
  expect(result.stderr).toContain('invalid target version: invalid')
  expect(result.stderr).not.toContain('TypeError')
})
