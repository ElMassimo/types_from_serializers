<script setup lang="ts">
import type { VideoClipWithSong } from '~/types/serializers'
import api from '~/api'

defineProps<{ videos: VideoClipWithSong[] }>()
</script>

<template>
  <h1 class="title text-3xl mt-8 mb-4 font-bold text-center text-gray-800">Latest Videos</h1>
  <PageList decimal>
    <li v-for="video in videos" :key="video.id" class="my-1">
      <Link class="text-lg" :href="api.songs.show.path(video.song)">
        {{ video.song.title }}
      </Link>
      <span class="text-sm">
        by
        <Link :href="api.composers.show.path(video.song.composer)">{{ video.song.composer.name }}</Link>
      </span>
    </li>
  </PageList>
</template>
