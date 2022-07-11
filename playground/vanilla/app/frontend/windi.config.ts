import { defineConfig } from 'vite-plugin-windicss'

export default defineConfig({
  preflight: {
    safelist: ['a'],
  },
  extract: {
    include: [
      '**/*.vue',
    ],
    exclude: [
      'windi.config.ts',
    ],
  },
  theme: {
    screens: {
      'sm': '450px',
      'md': '450px',
      'lg': '1024px',
      'xl': '1024px',
      '2xl': '1024px',
    },
  },
})
