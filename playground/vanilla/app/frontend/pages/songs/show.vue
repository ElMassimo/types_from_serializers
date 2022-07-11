<script setup lang="ts">
import type { SongWithVideos } from '~/types/serializers'
import api from '~/api'

defineProps<{ song: SongWithVideos }>()
</script>

<template>
  <PageTitle :backTo="api.songs.index.path()">
    {{ song.title }}
  </PageTitle>
  <span class="text-center text-sm italic -mt-2">
    composed by <Link :href="api.composers.show.path(song.composer)">{{ song.composer.name }}</Link>
  </span>

  <PageList class="mt-8">
    <li v-for="video in song.videos" :key="video.id">
      <YouTubePlayer :video="video"/>
    </li>
  </PageList>
</template>
