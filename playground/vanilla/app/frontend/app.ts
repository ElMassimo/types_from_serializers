import { createApp as createVueApp, h } from 'vue'
import { createInertiaApp, type CreateInertiaAppProps } from '~/inertia'
import { resolvePage } from '~/pages'
import '~/services/axios'

type InertiaOptions = Omit<CreateInertiaAppProps, 'resolve' | 'setup'>

export function createApp (options?: InertiaOptions) {
  return createInertiaApp({
    resolve: resolvePage,
    setup ({ plugin, app, props, el }) {
      const vueApp = createVueApp({ render: () => h(app, props) })
        .use(plugin)

      if (el)
        vueApp.mount(el)

      return vueApp
    },
    ...options,
  })
}
