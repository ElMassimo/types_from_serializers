import antfu from '@antfu/eslint-config'

export default antfu({
  vue: true,
  stylistic: false,
  ignores: ['**/dist/**', '**/coverage/**', '**/public/**', '**/types/serializers/**', '**/api/**'],
  rules: {
    'vue/attribute-hyphenation': ['warn', 'never'],
    'vue/html-closing-bracket-spacing': ['warn', {
      startTag: 'never',
      endTag: 'never',
      selfClosingTag: 'never',
    }],
  },
})
