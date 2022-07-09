import DefaultLayout from '~/layouts/DefaultLayout.vue'

// NOTE: Split the client bundle by page to make the initial load faster.
const pages = import.meta.env.SSR
  ? import.meta.globEagerDefault('./pages/**/*.vue')
  : import.meta.glob('./pages/**/*.vue')

export async function resolvePage (name: string) {
  const pageOrFn = pages[`./pages/${name}.vue`]

  if (!pageOrFn)
    throw new Error(`Unknown page ${name}. Is it located under app/frontend/pages with a .vue extension?`)

  const page = import.meta.env.SSR ? pageOrFn : (await pageOrFn()).default
  page.layout = DefaultLayout
  return page
}
