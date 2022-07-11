import { resolve } from 'path'
import { defineConfig } from 'vite'
import ruby from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import components from 'unplugin-vue-components/vite'
import windicss from 'vite-plugin-windicss'
import reloadOnChange from 'vite-plugin-full-reload'

export default defineConfig({
  plugins: [
    ruby(),
    vue({
      template: {
        compilerOptions: {
          isCustomElement: name => name === 'lite-youtube',
        },
      },
      reactivityTransform: true,
    }),
    components({
      dirs: ['components'],
      extensions: ['vue', 'ts'],
    }),
    windicss({
      root: resolve(__dirname, 'app/frontend'),
    }),
    reloadOnChange([
      'config/routes.rb',
      'app/serializers/**/*.rb',
    ], { delay: 100 }),
  ],
})
