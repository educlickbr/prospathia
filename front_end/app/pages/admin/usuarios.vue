<script setup lang="ts">
definePageMeta({
  layout: 'base',
  middleware: 'auth'
})

const activeTab = ref('admins') // admins | clientes

const currentRole = computed(() => activeTab.value === 'admins' ? ROLES.ADMIN : ROLES.CLIENTE)
const roleLabel = computed(() => activeTab.value === 'admins' ? 'Administradores' : 'Clientes')
const singleRoleLabel = computed(() => activeTab.value === 'admins' ? 'Administrador' : 'Cliente')

watch(activeTab, () => {
    // Clear data when switching tabs
    users.value = []
    questions.value = [] // Force re-fetch of questions for new role
    fetchUsers()
})

import { useAppStore, ROLES } from '../../../stores/app'

const store = useAppStore()
const loading = ref(true)
const users = ref<any[]>([])

// Fetch Users Logic
const fetchUsers = async () => {
    loading.value = true
    try {
        // Always refresh hash to ensure fresh signed URLs for images
        await store.refreshHash()

        const data = await $fetch('/api/admin/users/list', {
            params: {
                papel_id: currentRole.value, // Dynamic Role
                produto_id: store.produto?.id,
                // empresa_id: store.company?.id // Optional if we are filtering by clinic
            }
        })
        users.value = data || []
    } catch (error) {
        console.error('Erro ao buscar usuários:', error)
    } finally {
        loading.value = false
    }
}

onMounted(() => {
    if (store.produto?.id) {
        fetchUsers()
    } else {
        // Watch for product to be ready if not yet loaded
        const unwatch = watch(() => store.produto, (newVal) => {
            if (newVal?.id) {
                fetchUsers()
                unwatch()
            }
        })
    }
})

// Helper for Image URL
// Helper for Image URL (R2 Worker)
const getImageUrl = (url: string | null) => {
    if (!url) return 'https://ui-avatars.com/api/?background=random&name=User'
    if (url.startsWith('http')) return url
    
    // Construct Signed URL if Auth is available
    if (store.hash_base && store.auth_token) {
        // Ensure base ends with slash
        const base = store.hash_base.endsWith('/') ? store.hash_base : store.hash_base + '/'
        // Ensure url doesn't start with slash
        const cleanPath = url.startsWith('/') ? url.slice(1) : url
        
        // Final URL: WORKER/path?token=...
        return `${base}${cleanPath}?token=${encodeURIComponent(store.auth_token)}&expires=${store.auth_expires}&scope=${encodeURIComponent(store.auth_scope || '/')}`
    }
    
    return url 
}

// --- MODAL LOGIC ---
const isModalOpen = ref(false)
const currentUser = ref<any>(null) // null if create mode
const questions = ref<any[]>([])

// Open Modal (Edit or Create)
const openModal = async (user: any | null = null) => {
    loading.value = true // Show loading indicator on list (or could be local)
    
    try {
        // 1. Ensure Questions are loaded
        if (questions.value.length === 0) {
            const qs = await $fetch('/api/admin/users/questions', {
                params: { papel_id: currentRole.value }
            })
            questions.value = (qs as any[]) || []
        }

        // 2. Prepare User Data
        if (user) {
             // Edit Mode: Fetch full details first
             const details: any = await $fetch(`/api/admin/users/${user.id}`)
             // Merge details
             currentUser.value = { ...user, ...details.user, respostas: details.respostas } 
        } else {
             // Create Mode
             currentUser.value = null
        }
        
        // 3. Open Modal only after data is ready
        isModalOpen.value = true

    } catch (e) {
        console.error('Erro ao abrir modal:', e)
        alert('Erro ao carregar dados do usuário.')
    } finally {
        loading.value = false
    }
}

const handleModalSave = async () => {
    // Refresh list on save
    await fetchUsers()
}
</script>

<style scoped>
.animate-slide-in {
    animation: slideIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
@keyframes slideIn {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
}
.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
}
</style>

<template>
    <div class="space-y-6">
      
      <!-- Tabs Header -->
      <div class="border-b border-white/10">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <button 
            @click="activeTab = 'admins'"
            :class="[
              activeTab === 'admins'
                ? 'border-primary text-primary'
                : 'border-transparent text-secondary hover:border-white/20 hover:text-white',
              'whitespace-nowrap border-b-2 py-4 px-1 text-sm font-bold uppercase tracking-wider transition-colors'
            ]"
          >
            Admins
          </button>

          <button 
            @click="activeTab = 'clientes'"
            :class="[
              activeTab === 'clientes'
                ? 'border-primary text-primary'
                : 'border-transparent text-secondary hover:border-white/20 hover:text-white',
              'whitespace-nowrap border-b-2 py-4 px-1 text-sm font-bold uppercase tracking-wider transition-colors'
            ]"
          >
            Clientes
          </button>
        </nav>
      </div>

    <!-- CONTENT AREA -->
    <!-- Shared View for Both Tabs -->
    <div class="space-y-6 relative">

        <!-- Header / Filters -->
        <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold text-white">{{ roleLabel }}</h2>
            <button 
                @click="openModal(null)"
                class="px-4 py-2 bg-primary text-white text-xs font-bold uppercase tracking-wider rounded-lg hover:bg-primary-dark transition-colors"
            >
                Novo {{ singleRoleLabel }}
            </button>
        </div>

        <!-- Admins List Grid -->
        <div v-if="loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
             <div v-for="i in 3" :key="i" class="h-32 bg-white/5 rounded-xl animate-pulse"></div>
        </div>

        <div v-else-if="users.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div v-for="user in users" :key="user.id" class="bg-div-15 border border-white/5 rounded-xl p-4 flex items-center gap-4 hover:bg-white/10 transition-colors group relative">
                
                <!-- Avatar -->
                <div class="w-12 h-12 rounded-full overflow-hidden border border-white/10 shrink-0 bg-black/20">
                    <img 
                        :src="getImageUrl(user.imagem_user)" 
                        :alt="user.nome_completo"
                        class="w-full h-full object-cover"
                        @error="(e) => (e.target as HTMLImageElement).src = `https://ui-avatars.com/api/?name=${user.nome_completo}&background=random`"
                    >
                </div>

                <!-- Info -->
                <div class="flex-1 min-w-0">
                    <h3 class="text-sm font-bold text-white truncate max-w-full" :title="user.nome_completo">
                        {{ user.nome_completo }}
                    </h3>
                    <p class="text-xs text-secondary truncate max-w-full" :title="user.email">
                        {{ user.email }}
                    </p>
                    <div class="flex items-center gap-2 mt-1">
                         <span class="inline-block w-2 h-2 rounded-full" :class="user.status ? 'bg-emerald-500' : 'bg-red-500'"></span>
                         <span class="text-[10px] uppercase font-bold text-secondary/60">{{ user.status ? 'Ativo' : 'Inativo' }}</span>
                    </div>
                </div>

                <!-- Action Buttons (Hover) -->
                <div class="absolute right-2 top-2 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <!-- Edit Button -->
                    <button 
                        @click="openModal(user)"
                        class="p-2 bg-black/40 rounded-lg text-white/60 hover:text-primary hover:bg-black/60 backdrop-blur-sm transition-all"
                        title="Editar"
                    >
                        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                    </button>
                    <!-- Delete Button -->
                    <button 
                        class="p-2 bg-black/40 rounded-lg text-white/60 hover:text-red-500 hover:bg-black/60 backdrop-blur-sm transition-all"
                        title="Excluir"
                    >
                         <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                    </button>
                </div>

            </div>
        </div>

        <div v-else class="text-center py-12 text-secondary">
            Nenhum {{ singleRoleLabel.toLowerCase() }} encontrado.
        </div>

        <!-- MODAL -->
        <ModalUsuario 
            :is-open="isModalOpen"
            :user="currentUser"
            :role-id="currentRole"
            :questions="questions"
            @close="isModalOpen = false"
            @save="handleModalSave"
        />

    </div>

  </div>
</template>
