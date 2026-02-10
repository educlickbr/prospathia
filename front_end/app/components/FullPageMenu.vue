<script setup lang="ts">
import { useAppStore } from '../../stores/app'

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: true, // Always visible on /inicio
  },
})

// Since this is a full page menu acting as a dashboard, we don't necessarily need close/emit unless used as a modal
// But keeping structure similar to reference for flexibility
const emit = defineEmits(["close"])
const router = useRouter()
const store = useAppStore()
const route = useRoute()

// Active Route Helper
const isActive = (path: string) => {
    return route.path === path || route.path.startsWith(path + '/')
}

// Navigation Helper
const handleNavigation = (path: string) => {
  if (!path) return
  router.push(path)
  // emit("close") // Only if we want to close it (if it was a modal)
}

// User Info Helpers
const userName = computed(() => {
  if (store.nome_completo) return store.nome_completo
  if (store.user && store.user.email) return store.user.email.split('@')[0]
  return 'Convidado'
})

const userInitial = computed(() => {
  return userName.value ? userName.value.charAt(0).toUpperCase() : 'C'
})

const handleLogout = async () => {
    await store.logout()
    router.push('/login')
}
</script>

<template>
  <div
    class="min-h-screen bg-background flex flex-col font-sans p-4 gap-4 w-full"
  >
    <!-- 1. Header -->
    <header class="bg-div-15 px-4 py-3 rounded-lg flex items-center justify-between shadow-sm border border-secondary/5 shrink-0">
      <div class="flex items-center gap-3">
        <div class="flex w-10 h-10 rounded-lg bg-primary/10 text-primary items-center justify-center font-bold text-lg border border-primary/10 shadow-sm overflow-hidden relative">
           <img 
              v-if="store.imagem_user" 
              :src="store.getSignedUrl(store.imagem_user)" 
              class="w-full h-full object-cover absolute inset-0"
              alt="Foto"
           />
           <span v-else>{{ userInitial }}</span>
        </div>
        <div class="flex flex-col leading-none gap-1">
          <h2 class="text-sm font-black text-white uppercase tracking-[0.2em] leading-none">
            {{ userName }}
          </h2>
          <p class="text-[10px] text-secondary font-bold opacity-80 leading-none overflow-hidden text-ellipsis whitespace-nowrap max-w-[150px]">
              {{ store.email }}
          </p>
        </div>
      </div>

      <button
          @click="handleLogout"
          class="flex items-center gap-2 px-3 py-2 text-danger bg-danger/5 hover:bg-danger/10 border border-danger/10 rounded-lg transition-all text-[10px] font-black uppercase tracking-widest"
      >
          <span>Sair</span>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
      </button>
    </header>

    <!-- 2. Content Area -->
    <main class="flex-1 overflow-y-auto space-y-8 w-full custom-scrollbar">
      
      <!-- Menu Grid Structure -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        <!-- ISLAND: Admin -->
        <!-- Theme: Primary (Pink/Red) -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 px-1">
             <div class="w-1.5 h-1.5 rounded-full bg-primary/60"></div>
             <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase">Admin</h3>
          </div>
          
          <div class="bg-div-15 border border-secondary/10 rounded-xl overflow-hidden shadow-sm">
            
            <!-- Usuários -->
            <button @click="handleNavigation('/admin/usuarios')" class="menu-item group" :class="isActive('/admin/usuarios') ? 'bg-primary/5' : ''">
              <div class="menu-icon bg-primary/10 text-primary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/admin/usuarios') ? 'text-primary' : 'text-text group-hover:text-primary'">Usuários</span>
                <span class="text-[10px] text-secondary font-medium">Gestão de acesso</span>
              </div>
            </button>

            <!-- Planos -->
            <button @click="handleNavigation('/admin/planos')" class="menu-item group border-t border-secondary/5" :class="isActive('/admin/planos') ? 'bg-primary/5' : ''">
              <div class="menu-icon bg-primary/10 text-primary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/admin/planos') ? 'text-primary' : 'text-text group-hover:text-primary'">Planos</span>
                <span class="text-[10px] text-secondary font-medium">Planos e Assinaturas</span>
              </div>
            </button>

            <!-- Gestão de Modelos -->
            <button @click="handleNavigation('/admin/modelos')" class="menu-item group border-t border-secondary/5" :class="isActive('/admin/modelos') ? 'bg-primary/5' : ''">
              <div class="menu-icon bg-primary/10 text-primary">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/admin/modelos') ? 'text-primary' : 'text-text group-hover:text-primary'">Gestão de Modelos</span>
                <span class="text-[10px] text-secondary font-medium">Modelos do Sistema</span>
              </div>
            </button>

          </div>
        </div>

        <!-- ISLAND: Clínica -->
        <!-- Theme: Emerald/Teal -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 px-1">
             <div class="w-1.5 h-1.5 rounded-full bg-emerald-500/60"></div>
             <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase">Clínica</h3>
          </div>
          
          <div class="bg-div-15 border border-secondary/10 rounded-xl overflow-hidden shadow-sm">
            <!-- Cadastro Usuários -->
            <button @click="handleNavigation('/clinica/usuarios')" class="menu-item group" :class="isActive('/clinica/usuarios') ? 'bg-emerald-500/5' : ''">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="8.5" cy="7" r="4"></circle><line x1="20" y1="8" x2="20" y2="14"></line><line x1="23" y1="11" x2="17" y2="11"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/clinica/usuarios') ? 'text-emerald-500' : 'text-text group-hover:text-emerald-500'">Cadastro Usuários</span>
                <span class="text-[10px] text-secondary font-medium">Adicionar colaboradores</span>
              </div>
            </button>

            <!-- Pacientes -->
             <button @click="handleNavigation('/clinica/pacientes')" class="menu-item group border-t border-secondary/5" :class="isActive('/clinica/pacientes') ? 'bg-emerald-500/5' : ''">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/clinica/pacientes') ? 'text-emerald-500' : 'text-text group-hover:text-emerald-500'">Pacientes</span>
                <span class="text-[10px] text-secondary font-medium">Gestão de pacientes</span>
              </div>
            </button>

            <!-- Avaliação -->
             <button @click="handleNavigation('/clinica/avaliacao')" class="menu-item group border-t border-secondary/5" :class="isActive('/clinica/avaliacao') ? 'bg-emerald-500/5' : ''">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/clinica/avaliacao') ? 'text-emerald-500' : 'text-text group-hover:text-emerald-500'">Avaliação</span>
                <span class="text-[10px] text-secondary font-medium">Realizar avaliações</span>
              </div>
            </button>

            <!-- Questionário -->
             <button @click="handleNavigation('/clinica/questionario')" class="menu-item group border-t border-secondary/5" :class="isActive('/clinica/questionario') ? 'bg-emerald-500/5' : ''">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/clinica/questionario') ? 'text-emerald-500' : 'text-text group-hover:text-emerald-500'">Questionário</span>
                <span class="text-[10px] text-secondary font-medium">Formulários e pesquisas</span>
              </div>
            </button>

            <!-- Gestão de Modelos (Clínica) -->
             <button @click="handleNavigation('/clinica/modelos')" class="menu-item group border-t border-secondary/5" :class="isActive('/clinica/modelos') ? 'bg-emerald-500/5' : ''">
              <div class="menu-icon bg-emerald-500/10 text-emerald-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><line x1="9" y1="3" x2="9" y2="21"></line></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/clinica/modelos') ? 'text-emerald-500' : 'text-text group-hover:text-emerald-500'">Gestão de Modelos</span>
                <span class="text-[10px] text-secondary font-medium">Templates clínicos</span>
              </div>
            </button>

          </div>
        </div>

        <!-- ISLAND: Exames -->
        <!-- Theme: Violet/Purple -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 px-1">
             <div class="w-1.5 h-1.5 rounded-full bg-violet-500/60"></div>
             <h3 class="text-xs font-black text-secondary tracking-[0.2em] uppercase">Exames</h3>
          </div>
          
          <div class="bg-div-15 border border-secondary/10 rounded-xl overflow-hidden shadow-sm">
            <!-- Otolithics -->
             <button @click="handleNavigation('/exames/otolithics')" class="menu-item group" :class="isActive('/exames/otolithics') ? 'bg-violet-500/5' : ''">
              <div class="menu-icon bg-violet-500/10 text-violet-500">
                  <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"></path></svg>
              </div>
              <div class="flex flex-col text-left">
                <span class="text-sm font-bold transition-colors" :class="isActive('/exames/otolithics') ? 'text-violet-500' : 'text-text group-hover:text-violet-500'">Otolithics</span>
                <span class="text-[10px] text-secondary font-medium">VVS Vertical Visual Subjetiva</span>
              </div>
            </button>

          </div>
        </div>

      </div>
    </main>
    
    <!-- Footer -->
    <footer class="p-6 text-center border-t border-secondary/5 mt-auto">
      <p class="text-[10px] text-secondary/30 font-black tracking-[0.3em] uppercase">PROSPATHIA SYSTEM</p>
    </footer>

  </div>
</template>

<style scoped>
.menu-item {
  @apply w-full flex items-center gap-3 p-3 transition-all duration-200 hover:bg-div-30 active:scale-[0.99];
}

.menu-icon {
  @apply w-10 h-10 rounded-lg flex items-center justify-center shrink-0 transition-transform duration-300 group-hover:scale-110 group-hover:rotate-1;
}

.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--color-secondary-rgb), 0.1);
  border-radius: 10px;
}
</style>
