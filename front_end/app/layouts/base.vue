<script setup lang="ts">
import { useAppStore } from '../../stores/app'

const store = useAppStore()
const isMenuOpen = useState('menu-open', () => false)

onMounted(() => {
   // store.initTheme() // Theme logic might be in App.vue or store init
   if (!store.user) {
       store.initSession()
   }
})

const route = useRoute()
const pageTitle = computed(() => {
   // Simple logic for now, can be expanded
   if (route.path.includes('/admin/usuarios')) return 'Gestão de Usuários'
   if (route.path.includes('/admin/planos')) return 'Planos e Assinaturas'
   return 'Prospathia System'
})
</script>

<template>
  <div class="h-screen bg-background flex flex-col md:flex-row gap-4 p-2 md:p-5 overflow-hidden font-sans text-text transition-colors duration-300">
    
    <!-- Full Page Menu Overlay (Controlled by state) -->
    <FullPageMenu :isOpen="isMenuOpen" @close="isMenuOpen = false" v-if="isMenuOpen" />

    <!-- Main Content Panel (Contains Header + Content) -->
    <main class="flex-1 flex flex-col gap-4 h-full overflow-hidden relative">
      
         <!-- Detached Header (Inside Main) -->
         <header class="bg-transparent md:bg-div-15 px-2 py-1 md:px-4 md:py-3 rounded-lg shrink-0 flex items-center justify-between shadow-none md:shadow-sm border-0 md:border border-secondary/5 transition-all">
         
         <!-- Brand / User Avatar -->
         <div class="flex items-center gap-3">
               <!-- Desktop Avatar -->
               <div class="hidden md:flex w-8 h-8 rounded bg-primary/10 text-primary items-center justify-center font-bold text-sm shadow-sm border border-primary/10 overflow-hidden relative">
                  <img 
                     v-if="store.user && store.imagem_user" 
                     :src="store.getSignedUrl(store.imagem_user)" 
                     class="w-full h-full object-cover absolute inset-0"
                     alt="Foto"
                  />
                  <span v-else>{{ store.user?.email?.charAt(0).toUpperCase() || 'U' }}</span>
               </div>
               
               <div class="flex flex-col leading-none gap-0.5">
                  <h1 class="text-[12px] md:text-xs font-black text-primary uppercase tracking-[0.2em]">{{ pageTitle }}</h1>
                  <p class="text-[10px] md:text-[10px] text-secondary font-bold opacity-80">Prospathia System</p>
               </div>
         </div>

        <!-- Right Controls: Only Menu Button -->
        <div class="flex items-center">

           <!-- Auth State Buttons -->
           <div v-if="store.user" class="flex items-center gap-4">
               
               <!-- Menu Trigger (Far Right) -->
               <button 
                  @click="isMenuOpen = true"
                  class="w-10 h-10 flex flex-col items-center justify-center gap-1.5 rounded-lg text-secondary hover:text-primary hover:bg-div-30 transition-all group"
                  title="Menu"
               >
                  <span class="w-5 h-0.5 bg-current rounded-full transition-all group-hover:w-6"></span>
                  <span class="w-5 h-0.5 bg-current rounded-full transition-all group-hover:w-4"></span>
                  <span class="w-5 h-0.5 bg-current rounded-full transition-all group-hover:w-6"></span>
               </button>
           </div>
        </div>
      </header>

      <!-- Main Scrollable Content -->
      <div class="flex-1 overflow-y-auto rounded-lg custom-scrollbar flex flex-col gap-4 px-1">
         <slot />
         
         <footer class="py-6 text-center text-[9px] uppercase tracking-widest text-secondary/30 font-bold border-t border-secondary/5 mt-auto">
            © {{ new Date().getFullYear() }} Prospathia
         </footer>
      </div>

    </main>

    <!-- Sidebar (Right Side) -->
    <!-- Only visible on LG screens and up, as per reference -->
    <aside class="w-full md:w-[320px] lg:w-[380px] shrink-0 hidden lg:flex flex-col gap-4 h-full">
       <div class="bg-div-15 h-full rounded-lg border border-secondary/5 p-5 shadow-sm overflow-y-auto flex flex-col gap-6">
          <slot name="sidebar">
              <!-- Default Content / Skeleton can go here if needed -->
              <div class="flex flex-col items-center justify-center h-full opacity-30">
                  <p class="text-xs font-bold uppercase tracking-widest">Sidebar</p>
              </div>
          </slot>
       </div>
    </aside>

  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--color-secondary-rgb), 0.1);
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
</style>
