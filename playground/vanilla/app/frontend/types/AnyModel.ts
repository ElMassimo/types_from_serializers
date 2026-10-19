import type Song from '~/types/serializers/Song'
import type Video from '~/types/serializers/Video'

type AnyModel = Video | Song
export type { AnyModel as default }
