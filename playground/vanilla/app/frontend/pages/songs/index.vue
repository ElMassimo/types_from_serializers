<script setup lang="ts">
import type { Song } from '~/types/serializers'
import api from '~/api'

defineProps<{ songs: Song[] }>()
</script>

<template>
  <PageTitle>Songs</PageTitle>
  <PageList disc>
    <li v-for="song in songs" :key="song.id">
      <Link class="text-lg" :href="api.songs.show.path(song)">
        {{ song.title }}
      </Link>
      <span class="text-sm">
        by
        <Link :href="api.composers.show.path(song.composer)">{{ song.composer.name }}</Link>
      </span>
    </li>
  </PageList>
</template>
