<script setup lang="ts">
import { useAppStore } from '../../stores/app'
import LoadingOverlay from '~/components/LoadingOverlay.vue'

const store = useAppStore()
const router = useRouter()

definePageMeta({
  middleware: 'auth' 
})

onMounted(async () => {
    // Artificial delay to show the nice loader (optional, but good for UX transition)
    // In a real app, you might wait for specific data or promises here.
    setTimeout(() => {
        router.push('/inicio')
    }, 1500)
    
    // If not authenticated, middleware handles it.
    // If authenticated, we redirect to /inicio (The real Home)
})
</script>

<template>
  <div>
      <LoadingOverlay :show="true" />
  </div>
</template>
