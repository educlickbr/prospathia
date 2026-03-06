<script setup lang="ts">
import './assets/css/style.css'
</script>

<template>
  <div>
    <NuxtLayout>
        <NuxtPage />
    </NuxtLayout>
    <!-- Overlay Root for Teleports -->
    <div id="teleport-overlays"></div>
  </div>
</template>
