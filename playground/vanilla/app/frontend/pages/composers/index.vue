<script setup lang="ts">
import type { Composer } from '~/types/serializers'
import api from '~/api'

defineProps<{ composers: Composer[] }>()
</script>

<template>
  <PageTitle>Composers</PageTitle>
  <PageList disc>
    <li v-for="composer in composers" :key="composer.id">
      <Link class="text-lg" :href="api.composers.show.path(composer)">
        {{ composer.name }}
      </Link>
    </li>
  </PageList>
</template>
