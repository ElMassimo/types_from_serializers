<script setup lang="ts">
import type { ComposerWithSongs } from '~/types/serializers'
import api from '~/api'

defineProps<{ composer: ComposerWithSongs }>()
</script>

<template>
  <PageTitle :backTo="api.composers.index.path()">{{ composer.name }}</PageTitle>

  <PageSubtitle>Songs in Library</PageSubtitle>
  <PageList>
    <li v-for="song in composer.songs" :key="song.id">
      <Link :href="api.songs.show.path(song)">{{ song.title }}</Link>
    </li>
  </PageList>
</template>
