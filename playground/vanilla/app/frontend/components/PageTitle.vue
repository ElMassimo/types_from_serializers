<script setup lang="ts">
defineProps<{ backTo?: string }>()
</script>

<template>
  <h1 class="title text-3xl mt-8 mb-4 font-bold text-center text-gray-800"><slot/></h1>
</template>
