<script setup lang="ts">
defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  title: {
    type: String,
    default: 'Confirmação',
  },
  message: {
    type: String,
    default: 'Tem certeza que deseja realizar esta ação?',
  },
  confirmText: {
    type: String,
    default: 'Confirmar',
  },
  cancelText: {
    type: String,
    default: 'Cancelar',
  },
  type: {
    type: String as PropType<'danger' | 'info' | 'warning'>,
    default: 'danger',
  },
  loading: {
      type: Boolean,
      default: false
  }
});

const emit = defineEmits(['close', 'confirm']);
</script>

<template>
  <div v-if="isOpen" class="fixed inset-0 z-[300] flex items-center justify-center p-4">
    <!-- Backdrop -->
    <div 
        class="absolute inset-0 bg-black/80 backdrop-blur-sm transition-opacity" 
        @click="!loading ? emit('close') : null"
    ></div>

    <!-- Modal Content -->
    <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-sm p-6 relative z-10 shadow-2xl transform transition-all scale-100">
      
      <!-- Icon based on type -->
      <div class="mb-4 flex justify-center">
          <div v-if="type === 'danger'" class="w-12 h-12 rounded-full bg-red-500/10 text-red-500 flex items-center justify-center">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
          </div>
          <div v-else class="w-12 h-12 rounded-full bg-primary/10 text-primary flex items-center justify-center">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
          </div>
      </div>

      <h3 class="text-lg font-bold text-white text-center mb-2">{{ title }}</h3>
      <p class="text-sm text-secondary text-center mb-6 leading-relaxed">{{ message }}</p>

      <div class="flex items-center gap-3">
        <button 
          @click="emit('close')"
          :disabled="loading"
          class="flex-1 px-4 py-2.5 rounded-lg border border-white/10 text-xs font-bold uppercase tracking-wider text-secondary hover:bg-white/5 transition-colors disabled:opacity-50"
        >
          {{ cancelText }}
        </button>
        <button 
          @click="emit('confirm')"
          :disabled="loading"
          class="flex-1 px-4 py-2.5 rounded-lg text-xs font-bold uppercase tracking-wider text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
          :class="type === 'danger' ? 'bg-red-500 hover:bg-red-600' : 'bg-primary hover:bg-primary/90'"
        >
          <span v-if="loading" class="animate-spin w-3 h-3 border-2 border-white/20 border-t-white rounded-full"></span>
          {{ confirmText }}
        </button>
      </div>
    </div>
  </div>
</template>
