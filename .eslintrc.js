module.exports = {
  env: {
    browser: true,
    jest: true,
  },
  extends: ['@mussi/eslint-config'],
  plugins: ['jest'],
  rules: {
    '@typescript-eslint/no-var-requires': 'off',
  },
}
