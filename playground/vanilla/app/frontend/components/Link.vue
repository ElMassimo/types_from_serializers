<script setup lang="ts">
import { usePage } from '~/composables/page'

const { href } = defineProps<{ href: string; light?: boolean }>()

const { url } = $(usePage())

const active = $computed(() => url === href)
</script>

<template>
  <InertiaLink
    :class="[light ? 'text-teal-200 hover:text-teal-100' : 'text-cyan-600 hover:underline', { active, light }]"
    :href="href"
  >
    <slot/>
  </InertiaLink>
</template>

<style scoped>
.light.active {
  @apply text-teal-50;
}
</style>
