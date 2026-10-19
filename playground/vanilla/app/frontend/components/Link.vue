<script setup lang="ts">
import { computed } from 'vue'
import { usePage } from '~/composables/page'

const { href } = defineProps<{ href: string; light?: boolean }>()

const page = usePage()

const active = computed(() => page.url.value === href)
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
