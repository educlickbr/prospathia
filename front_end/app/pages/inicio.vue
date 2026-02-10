<script setup lang="ts">
import FullPageMenu from '~/components/FullPageMenu.vue'

definePageMeta({
  middleware: 'auth'
})
</script>

<template>
  <div class="min-h-screen bg-background">
      <FullPageMenu :is-open="true" />
  </div>
</template>
