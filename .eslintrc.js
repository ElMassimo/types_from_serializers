module.exports = {
  env: {
    browser: true,
  },
  extends: ['@antfu/eslint-config'],
  rules: {
    '@typescript-eslint/space-before-function-paren': ['warn', 'always'],
    'vue/attribute-hyphenation': ['warn', 'never'],
    'vue/html-closing-bracket-spacing': ['warn', {
      startTag: 'never',
      endTag: 'never',
      selfClosingTag: 'never',
    }],
  },
  globals: {
    defineProps: 'readonly',
    defineEmits: 'readonly',
    defineExpose: 'readonly',
    withDefaults: 'readonly',
    $: 'readonly',
    $$: 'readonly',
    $ref: 'readonly',
    $computed: 'readonly',
  },
}
