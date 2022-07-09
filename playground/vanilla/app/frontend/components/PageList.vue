<script setup lang="ts">
defineProps<{ disc?: boolean; decimal?: boolean }>()
</script>

<template>
  <ul class="text-base text-sm mx-auto tracking-wide" :class="{ 'list-decimal': decimal, 'list-disc': disc }">
    <slot/>
  </ul>
</template>

<style scoped>
ul > :slotted(li) {
  @apply my-1;
}
</style>
