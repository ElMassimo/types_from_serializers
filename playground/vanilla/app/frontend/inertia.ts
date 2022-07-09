import { Inertia, type Page } from '@inertiajs/inertia'
import { deepCamelizeKeys } from '~/helpers/object'
export { createInertiaApp, type CreateInertiaAppProps } from '@inertiajs/inertia-vue3'

const router = Inertia as any
router._handleInitialPageVisit = router.handleInitialPageVisit
router.handleInitialPageVisit = function (page: Page) {
  page.props = deepCamelizeKeys(page.props)
  return this._handleInitialPageVisit(page)
}
