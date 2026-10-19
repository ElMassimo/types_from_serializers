<script setup lang="ts">
import type { Video } from '~/types/serializers'
import { useWindowSize } from '@vueuse/core'
import { computed } from 'vue'

const { video } = defineProps<{ video: Video }>()

const { width } = useWindowSize()

const videoWidth = computed(() => Math.min(width.value, 600) - 32)
const videoHeight = computed(() => 315 / 560 * videoWidth.value)

const embedUrl = computed(() => `https://www.youtube.com/embed/${video.youtubeId}`)
</script>

<template>
  <transition name="fade" appear>
    <iframe
      :width="videoWidth"
      :height="videoHeight"
      :src="embedUrl"
      :title="video.title"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen
    />
  </transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition-duration: 700ms;
}
</style>
