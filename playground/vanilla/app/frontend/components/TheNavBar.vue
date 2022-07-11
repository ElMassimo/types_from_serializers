<script setup lang="ts">
import { composers, songs, videos } from '~/api'
</script>

<template>
  <nav class="bg-teal-500">
    <div class="flex flex-col md:container md:flex-row md:mx-auto items-center justify-between flex-wrap p-6 gap-4">
      <div class="flex items-center flex-shrink-0 text-white mr-6">
        <a href="https://github.com/ElMassimo/types_from_serializers" target="_blank" class="font-semibold text-xl tracking-tight">Types from Serializers</a>
      </div>
      <div class="text-sm flex-grow space-x-8 font-semibold">
        <Link :href="videos.index.path()" light>
          Videos
        </Link>
        <Link :href="songs.index.path()" light>
          Songs
        </Link>
        <Link :href="composers.index.path()" light>
          Composers
        </Link>
      </div>
    </div>
  </nav>
</template>
