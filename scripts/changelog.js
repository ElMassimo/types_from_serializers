const path = require('path')
const fs = require('fs')
const args = require('minimist')(process.argv.slice(2))
const execa = require('execa')
const chalk = require('chalk')

const name = args._[0]?.trim() || 'types_from_serializers'

if (!name) {
  console.error(chalk.red(`Expected library name as an argument, received ${name}`))
  process.exit(1)
}

const isRubyPackage = name === 'types_from_serializers'
const packagePath = isRubyPackage ? name : `packages/${name}`

/**
 * @param {string} bin
 * @param {string[]} args
 * @param {object} opts
 */
const run = (bin, args, opts = {}) =>
  execa(bin, args, { stdio: 'inherit', ...opts })

/**
 * @param {string} paths
 */
const resolve = paths => path.resolve(__dirname, `../${packagePath}/${paths}`)

/**
 * @param {string} name
 */
function writePackageJson (name) {
  const versionRegex = /VERSION = "([\d.]+)"/
  const versionFile = fs.readFileSync(resolve(`lib/${name}/version.rb`), 'utf-8')
  const versionCaptures = versionFile.match(versionRegex)
  const version = versionCaptures && versionCaptures[1]
  if (!version) {
    console.error(chalk.red(`Could not infer version for ${name}.`))
    process.exit(1)
  }
  fs.writeFileSync(resolve('package.json'), `{ "version": "${version}" }`)
}

async function main () {
  if (isRubyPackage)
    writePackageJson(name)

  await run('npx', [
    'conventional-changelog',
    '-p', 'angular',
    '-i', `${packagePath}/CHANGELOG.md`,
    '-s',
    '-t', `${name}@`,
    '--pkg', `./${packagePath}/package.json`,
    '--commit-path', `./${packagePath}`,
  ])

  if (isRubyPackage)
    fs.rmSync(resolve('package.json'))
}

main().catch((err) => {
  console.error(err)
})
