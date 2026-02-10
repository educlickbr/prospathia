<script setup lang="ts">
import { useToast } from "../../../composables/useToast";
import ConfirmationModal from '../../components/ConfirmationModal.vue';
import ModalSala from '../../components/producao/ModalSala.vue';

const { showToast } = useToast();

const salas = ref<any[]>([]);
const isLoading = ref(false);
const search = ref('');

// Delete State
const isDeleting = ref(false);
const showDeleteConfirm = ref(false);
const itemToDelete = ref<any>(null);

// Modal State
const showModal = ref(false);
const selectedSala = ref<any>(null); // Null for create, Object for edit

onMounted(() => {
    fetchSalas();
});

const fetchSalas = async () => {
    isLoading.value = true;
    try {
        const data = await $fetch('/api/producao/salas/get');
        salas.value = data || [];
    } catch (e: any) {
        showToast('Erro ao carregar salas: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const handleCreate = () => {
    selectedSala.value = null;
    showModal.value = true;
};

const handleEdit = (sala: any) => {
    selectedSala.value = sala;
    showModal.value = true;
};

const handleDelete = (sala: any) => {
    itemToDelete.value = sala;
    showDeleteConfirm.value = true;
};

const confirmDelete = async () => {
    if (!itemToDelete.value) return;

    isDeleting.value = true;
    try {
        await $fetch('/api/producao/salas/delete', {
            method: 'POST',
            body: { id: itemToDelete.value.id }
        });
        showToast('Sala excluída com sucesso!', { type: 'success' });
        fetchSalas();
        showDeleteConfirm.value = false;
        itemToDelete.value = null;
    } catch (e: any) {
        showToast('Erro ao excluir sala: ' + e.message, { type: 'error' });
    } finally {
        isDeleting.value = false;
    }
};

const handleSaved = () => {
    fetchSalas();
};

const filteredSalas = computed(() => {
    if (!search.value) return salas.value;
    return salas.value.filter(s => s.nome.toLowerCase().includes(search.value.toLowerCase()));
});
</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-transparent md:bg-div-15 rounded-none md:rounded-xl p-0 md:p-8 flex-1 w-full relative">
            
            <!-- HEADER -->
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <div>
                    <h1 class="text-2xl font-bold text-white mb-2">Salas</h1>
                    <p class="text-secondary text-sm">Gerencie as salas disponíveis para reservas.</p>
                </div>
                
                 <div class="flex items-center gap-3 w-full md:w-auto">
                    <button 
                        @click="handleCreate"
                        class="bg-primary hover:bg-primary-dark text-white rounded-lg px-3 py-1.5 text-xs font-bold flex items-center gap-2 transition-colors h-[32px]"
                    >
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                        Nova Sala
                    </button>
                 </div>
            </div>

            <!-- SEARCH -->
            <div class="mb-6">
                <div class="relative">
                    <input 
                        v-model="search"
                        type="text" 
                        placeholder="Buscar salas..." 
                        class="w-full bg-[#16161E] border border-white/10 rounded-xl px-4 py-3 pl-11 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/50 transition-colors"
                    >
                    <div class="absolute left-4 top-3.5 text-secondary/50">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                    </div>
                </div>
            </div>

            <!-- CONTENT -->
            <div v-if="isLoading && salas.length === 0" class="py-20 flex justify-center">
                 <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
            </div>

            <div v-else-if="filteredSalas.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 border border-dashed border-white/10 rounded-xl">
                <div class="text-4xl mb-4 text-secondary/50">
                    <svg class="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                </div>
                <p class="text-white font-medium">Nenhuma sala encontrada</p>
            </div>

            <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <div 
                    v-for="sala in filteredSalas" 
                    :key="sala.id" 
                    class="bg-[#16161E] border border-white/5 rounded-xl p-5 relative overflow-hidden group hover:border-primary/50 transition-colors"
                >
                    <!-- Color Strip -->
                    <div 
                        class="absolute left-0 top-0 bottom-0 w-1.5"
                        :style="{ backgroundColor: sala.cor }"
                    ></div>

                    <div class="pl-3">
                        <div class="flex items-start justify-between">
                            <div>
                                <h3 class="font-bold text-white text-lg">{{ sala.nome }}</h3>
                            </div>
                            <!-- Actions -->
                            <div class="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                <button 
                                    @click="handleEdit(sala)"
                                    class="text-secondary hover:text-white p-1"
                                    title="Editar"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                                </button>
                                <button 
                                    @click="handleDelete(sala)"
                                    class="text-secondary hover:text-danger p-1"
                                    title="Excluir"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Confirmation Modal -->
            <ConfirmationModal
                :isOpen="showDeleteConfirm"
                title="Excluir Sala"
                :message="`Tem certeza que deseja excluir a sala '${itemToDelete?.nome}'? Esta ação não pode ser desfeita.`"
                confirmText="Excluir"
                cancelText="Cancelar"
                type="danger"
                :loading="isDeleting"
                @close="showDeleteConfirm = false"
                @confirm="confirmDelete"
            />

            <!-- Create/Edit Modal -->
            <ModalSala 
                :isOpen="showModal" 
                :sala="selectedSala"
                @close="showModal = false"
                @saved="handleSaved"
            />

        </div>

        <template #sidebar>
             <!-- Sidebar Content (Visible on Desktop) -->
             <div class="space-y-6">
                 <!-- Instructions -->
                 <div class="bg-[#16161E] border border-white/5 rounded-xl p-4">
                     <h3 class="text-xs font-bold text-secondary uppercase tracking-wider mb-2">Instruções</h3>
                     <p class="text-xs text-secondary/80 leading-relaxed">
                         Gerencie as salas da unidade.
                     </p>
                     <ul class="mt-4 text-xs text-secondary/70 space-y-2 list-disc pl-4">
                         <li>Crie sua sala e escolha a cor de identificação.</li>
                         <li>A cor da sala irá refletir no calendário de salas.</li>
                         <li>
                            <span class="text-amber-500 font-bold">Atenção:</span> 
                            Quando apagar uma sala, todas as reservas feitas ficarão órfãs e não serão mais vistas, cuidado com este procedimento.
                         </li>
                     </ul>
                 </div>
             </div>
        </template>
    </NuxtLayout>
</template>
