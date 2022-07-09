<script setup lang="ts">
import { usePage } from '~/composables/page'

const { component } = $(usePage())
</script>

<template>
  <div class="flex flex-col min-h-full grow text-xs text-gray-600">
    <TheNavBar/>
    <transition name="fade" mode="out-in">
      <main :key="component" class="flex flex-col w-full grow bg-gray-100 container mx-auto">
        <slot/>
      </main>
    </transition>
  </div>
</template>

<style>
html, body {
  height: 100%;
}

#app {
  @apply flex flex-col bg-gray-100 min-h-full;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 200ms ease;
}
</style>
