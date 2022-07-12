<script setup lang="ts">
import { useWindowSize } from '@vueuse/core'
import type { Video } from '~/types/serializers'

const { video } = defineProps<{ video: Video }>()

const { width } = $(useWindowSize())

const videoWidth = $computed(() => Math.min(width, 600) - 32)
const videoHeight = $computed(() => 315 / 560 * videoWidth)

const embedUrl = $computed(() => `https://www.youtube.com/embed/${video.youtubeId}`)

const display = $ref(false)
</script>

<template>
  <transition name="fade" appear>
    <iframe
      v-show="display"
      ref="youtubeEmbed"
      :width="videoWidth"
      :height="videoHeight"
      :src="embedUrl"
      :title="video.title"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen
      @load="display = true"
    />
  </transition>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition-duration: 700ms;
}
</style>
