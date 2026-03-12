<script setup lang="ts">
import { useEstoqueStore } from '../../stores/estoque';
import { useToast } from "../../../composables/useToast";
import ConfirmationModal from '../../components/ConfirmationModal.vue';


const user = useSupabaseUser();
const estoqueStore = useEstoqueStore();
const { showToast } = useToast();

const isDeleting = ref(false);
const showDeleteConfirm = ref(false);
const itemToDelete = ref<any>(null);

// Reservas State
const reservas = ref<any[]>([]);
const reservasPagination = ref({ pagina_atual: 1, qtd_paginas: 1, qtd_itens: 0 });
const buscaReservas = ref('');
const filterStatus = ref('');
const showFilters = ref(false);
const expandedReservas = ref(new Set<string>());
const expandedItems = ref<Record<string, any[]>>({});
const loadingDetails = ref<Record<string, boolean>>({});
const isLoading = ref(false);

// Create Reserva Modal State
const showCreateModal = ref(false);
const loadingCreate = ref(false);
const createForm = ref({
    // No User Search needed, auto-assigned to logged user
    productSearch: '',
    quantidade: 1,
    data_retirada: '',
    data_devolucao: ''
});
const searchProductsResults = ref<any[]>([]);
const selectedProduct = ref<any>(null);

// Status Translation
const translateStatus = (status: string) => {
    const map: Record<string, string> = {
        'reservado': 'Reservado',
        'retirado': 'Retirado',
        'devolvido': 'Devolvido',
        'cancelado': 'Cancelado',
        'atrasado': 'Atrasado'
    };
    return map[status] || status;
};

const getStatusColor = (status: string) => {
    const map: Record<string, string> = {
        'reservado': 'bg-blue-500/10 text-blue-500 border-blue-500/20',
        'retirado': 'bg-orange-500/10 text-orange-500 border-orange-500/20',
        'devolvido': 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20',
        'cancelado': 'bg-red-500/10 text-red-500 border-red-500/20',
        'atrasado': 'bg-red-600/10 text-red-600 border-red-600/20'
    };
    return map[status] || 'bg-white/5 text-secondary border-white/5';
};

onMounted(() => {
    fetchReservas();
});

// Reservas Actions
const fetchReservas = async (page = 1) => {
    if (!user.value) return; 
    isLoading.value = true;
    try {
        const data = await estoqueStore.getReservas({ 
            page, 
            limit: 12,
            busca: buscaReservas.value || undefined,
            status: filterStatus.value || undefined,
            userId: user.value.id // Filter by logged in user
        });
        if (data) {
            reservas.value = data.itens || [];
            reservasPagination.value = {
                pagina_atual: data.pagina_atual,
                qtd_paginas: data.qtd_paginas,
                qtd_itens: data.qtd_itens
            };
        }
    } catch (e: any) {
        showToast('Erro ao carregar reservas: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const handleDeleteReserva = (reserva: any) => {
    itemToDelete.value = { ...reserva, type: 'reserva', nome: `Reserva de ${reserva.nome_usuario}` };
    showDeleteConfirm.value = true;
};

// Expansion Logic
const isExpanded = (reserva: any) => {
    return expandedReservas.value.has(reserva.ids[0]);
};

const toggleExpand = async (reserva: any) => {
    const id = reserva.ids[0];
    if (expandedReservas.value.has(id)) {
        expandedReservas.value.delete(id);
        return;
    }
    
    expandedReservas.value.add(id);
    if (!expandedItems.value[id]) {
        await fetchReservaDetails(reserva);
    }
};

const fetchReservaDetails = async (reserva: any) => {
    const id = reserva.ids[0];
    loadingDetails.value[id] = true;
    try {
        const details = await estoqueStore.getReservaItens(reserva.ids);
        expandedItems.value[id] = details;
    } catch (e: any) {
        showToast('Erro ao carregar detalhes: ' + e.message, { type: 'error' });
    } finally {
        loadingDetails.value[id] = false;
    }
};


// Create Modal Logic
const openCreateModal = () => {
    createForm.value = {
        productSearch: '',
        quantidade: 1,
        data_retirada: '',
        data_devolucao: ''
    };
    selectedProduct.value = null;
    searchProductsResults.value = [];
    showCreateModal.value = true;
};

const confirmDeleteReserva = async () => {
    if (!itemToDelete.value) return;
    
    isDeleting.value = true;
    try {
        await estoqueStore.deletarReserva(itemToDelete.value.ids);
        showToast('Reserva excluída com sucesso', { type: 'success' });
        showDeleteConfirm.value = false;
        fetchReservas(reservasPagination.value.pagina_atual);
    } catch (e: any) {
        showToast('Erro ao excluir: ' + e.message, { type: 'error' });
    } finally {
        isDeleting.value = false;
        itemToDelete.value = null;
    }
};

// --- Product Search ---
let productSearchTimer: any = null;
const handleProductSearch = async (e: Event) => {
    const query = (e.target as HTMLInputElement).value;
    createForm.value.productSearch = query;
    
    if (productSearchTimer) clearTimeout(productSearchTimer);
    
    if (query.length < 2) {
        searchProductsResults.value = [];
        return;
    }

    productSearchTimer = setTimeout(async () => {
        const results = await estoqueStore.searchProdutos(query);
        searchProductsResults.value = results || [];
    }, 300);
};

const selectProduct = (prod: any) => {
    selectedProduct.value = prod;
    createForm.value.productSearch = prod.nome;
    searchProductsResults.value = [];
};

// --- Create Submit ---
const submitCreateReserva = async () => {
    if (!user.value) {
        showToast('Usuário não autenticado', { type: 'error' });
        return;
    }
    if (!selectedProduct.value) {
        showToast('Selecione um produto', { type: 'info' });
        return;
    }
    if (!createForm.value.data_retirada || !createForm.value.data_devolucao) {
        showToast('Preencha as datas', { type: 'info' });
        return;
    }

    loadingCreate.value = true;
    try {
        await estoqueStore.createReserva({
            id_usuario: user.value.id, // Logged User
            id_produto: selectedProduct.value.id,
            quantidade: Number(createForm.value.quantidade),
            data_retirada: createForm.value.data_retirada,
            data_devolucao: createForm.value.data_devolucao
        });

        showToast('Reserva solicitada com sucesso!', { type: 'success' });
        showCreateModal.value = false;
        fetchReservas(); 
        
    } catch (e: any) {
        showToast('Erro ao criar reserva: ' + e.message, { type: 'error' });
    } finally {
        loadingCreate.value = false;
    }
};

// Pagination
const changePage = (p: number) => {
    if (p >= 1 && p <= reservasPagination.value.qtd_paginas) {
        fetchReservas(p);
    }
};
</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-transparent md:bg-div-15 rounded-none md:rounded-xl p-0 md:p-8 flex-1 w-full relative">
            
            <!-- HEADER -->
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <div>
                    <h2 class="text-xl font-bold text-white mb-1">Minhas Reservas</h2>
                    <p class="text-xs text-secondary font-medium">Acompanhe e gerencie seus equipamentos.</p>
                </div>
                
                 <!-- Actions -->
                 <div class="flex gap-2">
                     <button
                         @click="openCreateModal"
                         class="bg-primary hover:bg-primary-600 text-white text-xs font-bold py-2.5 px-4 rounded-lg shadow-lg shadow-primary/20 transition-all flex items-center gap-2 group"
                     >
                         <svg class="w-4 h-4 transition-transform group-hover:rotate-90" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                         Nova Reserva
                     </button>
                 </div>
            </div>

            <!-- Filters -->
            <div class="mb-6 flex flex-col md:flex-row gap-4 items-center">
                <div class="relative flex-1 w-full">
                    <input 
                        v-model="buscaReservas"
                        @input="fetchReservas(1)"
                        type="text" 
                        placeholder="Buscar produto..." 
                        class="w-full bg-[#16161E] border border-white/5 rounded-lg pl-10 pr-4 py-2.5 text-sm text-white focus:border-primary focus:outline-none transition-colors"
                    />
                    <svg class="w-4 h-4 text-secondary absolute left-3.5 top-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                </div>

                <div class="relative">
                     <button 
                        @click="showFilters = !showFilters"
                        class="px-4 py-2.5 bg-[#16161E] border border-white/5 rounded-lg text-xs font-bold text-secondary hover:text-white flex items-center gap-2 transition-colors"
                        :class="filterStatus ? 'text-primary border-primary/30 bg-primary/5' : ''"
                     >
                         <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path></svg>
                         {{ filterStatus ? translateStatus(filterStatus) : 'Filtrar Status' }}
                     </button>
                     
                     <!-- Filter Dropdown -->
                     <div v-if="showFilters" class="absolute right-0 top-full mt-2 w-48 bg-[#1E1E26] border border-white/10 rounded-lg shadow-xl z-20 py-2">
                         <button @click="filterStatus = ''; showFilters = false; fetchReservas(1)" class="w-full text-left px-4 py-2 text-xs font-medium text-secondary hover:text-white hover:bg-white/5">Todos</button>
                         <button @click="filterStatus = 'reservado'; showFilters = false; fetchReservas(1)" class="w-full text-left px-4 py-2 text-xs font-medium text-secondary hover:text-white hover:bg-white/5">Reservados</button>
                         <button @click="filterStatus = 'retirado'; showFilters = false; fetchReservas(1)" class="w-full text-left px-4 py-2 text-xs font-medium text-secondary hover:text-white hover:bg-white/5">Retirados</button>
                         <button @click="filterStatus = 'devolvido'; showFilters = false; fetchReservas(1)" class="w-full text-left px-4 py-2 text-xs font-medium text-secondary hover:text-white hover:bg-white/5">Devolvidos</button>
                         <button @click="filterStatus = 'atrasado'; showFilters = false; fetchReservas(1)" class="w-full text-left px-4 py-2 text-xs font-medium text-secondary hover:text-white hover:bg-white/5">Atrasados</button>
                         <button @click="filterStatus = 'cancelado'; showFilters = false; fetchReservas(1)" class="w-full text-left px-4 py-2 text-xs font-medium text-secondary hover:text-white hover:bg-white/5">Cancelados</button>
                     </div>
                </div>
            </div>

            <!-- List Content -->
            <div class="flex-1 overflow-y-auto custom-scrollbar">
                <div v-if="isLoading" class="flex justify-center py-20">
                    <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                </div>
                
                <div v-else-if="reservas.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50">
                    <svg class="w-12 h-12 mb-4 text-secondary/30" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                    <p class="text-secondary font-medium text-sm">Nenhuma reserva encontrada.</p>
                </div>

                <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    <div v-for="reserva in reservas" :key="reserva.ids[0]" class="bg-[#16161E] border border-white/5 rounded-xl p-0 hover:border-primary/20 transition-all group overflow-hidden flex flex-col">
                        
                        <!-- Card Header (Product Info) -->
                        <div class="p-4 flex items-start gap-4 border-b border-white/5 pb-4">
                             <div class="w-12 h-12 rounded-lg bg-div-30 shrink-0 overflow-hidden border border-white/5">
                                 <img v-if="reserva.imagem" :src="reserva.imagem" class="w-full h-full object-cover" />
                                 <div v-else class="w-full h-full flex items-center justify-center text-xs font-bold text-secondary">IMG</div>
                             </div>
                             <div>
                                 <h3 class="text-sm font-bold text-white leading-tight mb-1">{{ reserva.produto_nome }}</h3>
                                 <div class="flex items-center gap-2">
                                     <span class="text-[10px] font-bold px-1.5 py-0.5 rounded border" :class="getStatusColor(reserva.status)">
                                         {{ translateStatus(reserva.status) }}
                                     </span>
                                     <span class="text-[10px] text-secondary font-medium">{{ reserva.qtd_itens }} un.</span>
                                 </div>
                             </div>
                        </div>

                        <!-- Card Dates -->
                        <div class="p-4 space-y-2 flex-1">
                             <div class="flex justify-between items-center text-xs">
                                 <span class="text-secondary">Retirada</span>
                                 <span class="text-white font-medium">{{ reserva.data_retirada ? new Date(reserva.data_retirada).toLocaleDateString() : '-' }}</span>
                             </div>
                             <div class="flex justify-between items-center text-xs">
                                 <span class="text-secondary">Devolução</span>
                                 <span class="text-white font-medium">{{ reserva.data_devolucao ? new Date(reserva.data_devolucao).toLocaleDateString() : '-' }}</span>
                             </div>
                              <div v-if="reserva.data_devolvido" class="flex justify-between items-center text-xs text-emerald-500/80 mt-1">
                                 <span>Entregue em</span>
                                 <span class="font-medium">{{ new Date(reserva.data_devolvido).toLocaleDateString() }}</span>
                             </div>
                        </div>
                        
                        <!-- Card Footer (Actions) -->
                       <div class="p-3 bg-white/5 flex items-center justify-between gap-2">
                            <button 
                                @click="toggleExpand(reserva)"
                                class="text-[10px] font-bold text-secondary hover:text-white transition-colors flex items-center gap-1"
                            >
                                Detalhes
                                <svg class="w-3 h-3 transition-transform" :class="isExpanded(reserva) ? 'rotate-180' : ''" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                            </button>

                            <!-- Delete (Only allowed for user's own reservations that are usually pending/reservado, handled by backend policies mostly, but here we allow delete request) -->
                            <button 
                                @click="handleDeleteReserva(reserva)"
                                class="text-[10px] font-bold text-red-500/70 hover:text-red-500 transition-colors flex items-center gap-1"
                            >
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                Excluir
                            </button>
                        </div>
                         
                         <!-- Expanded Details -->
                         <div v-if="isExpanded(reserva)" class="border-t border-white/5 bg-[#0f0f15] p-4 text-xs">
                             <div v-if="loadingDetails[reserva.ids[0]]" class="flex justify-center p-2">
                                 <svg class="animate-spin h-4 w-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                             </div>
                             <div v-else class="space-y-2">
                                 <div v-for="item in expandedItems[reserva.ids[0]]" :key="item.id" class="flex justify-between items-center py-1 border-b border-white/5 last:border-0">
                                     <span class="text-secondary">{{ item.codigo_barras || 'S/N' }}</span>
                                     <span class="px-1.5 py-0.5 rounded text-[10px] border" :class="getStatusColor(item.status_item || item.status)">
                                         {{ translateStatus(item.status_item || item.status) }}
                                     </span>
                                 </div>
                                 <div v-if="reserva.ids.length > 3" class="text-center text-[10px] text-secondary/50 pt-1 italic">
                                     + {{ reserva.ids.length - 3 }} itens ocultos
                                 </div>
                             </div>
                         </div>

                    </div>
                </div>

                <!-- Load More / Pagination -->
                <div v-if="reservasPagination.qtd_paginas > 1" class="flex justify-between items-center mt-6 pt-4 border-t border-white/5">
                    <span class="text-xs text-secondary">
                        Página {{ reservasPagination.pagina_atual }} de {{ reservasPagination.qtd_paginas }}
                    </span>
                    <div class="flex gap-2">
                        <button 
                            @click="changePage(reservasPagination.pagina_atual - 1)"
                            :disabled="reservasPagination.pagina_atual === 1"
                            class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                            Anterior
                        </button>
                        <button 
                            @click="changePage(reservasPagination.pagina_atual + 1)"
                            :disabled="reservasPagination.pagina_atual >= reservasPagination.qtd_paginas"
                            class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                            Próxima
                        </button>
                    </div>
                </div>
            </div>

            <!-- Delete Modal -->
            <ConfirmationModal
                :isOpen="showDeleteConfirm"
                title="Excluir Item"
                :message="`Tem certeza que deseja excluir '${itemToDelete?.nome}'? Esta ação não pode ser desfeita.`"
                confirmText="Excluir"
                cancelText="Cancelar"
                type="danger"
                :loading="isDeleting"
                @close="showDeleteConfirm = false"
                @confirm="confirmDeleteReserva"
             />

        </div>

    <!-- CREATE MODAL (Standard, but simplified without User Selection) -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 overflow-y-auto">
        <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity" @click="showCreateModal = false"></div>
        <div class="flex min-h-full items-center justify-center p-4">
            <div class="relative w-full max-w-lg transform rounded-2xl bg-[#16161E] border border-white/10 p-6 text-left shadow-xl transition-all">
                <h3 class="text-lg font-bold text-white mb-6">Nova Reserva</h3>
                
                <div class="space-y-4">
                    <!-- Produto Search -->
                    <div>
                         <label class="block text-xs font-bold text-secondary mb-1">PRODUTO</label>
                         <div class="relative">
                             <input 
                                 type="text" 
                                 :value="createForm.productSearch"
                                 @input="handleProductSearch"
                                 placeholder="Buscar equipamento..." 
                                 class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-white focus:border-primary focus:outline-none text-sm"
                             />
                             <!-- Results Dropdown -->
                             <div v-if="searchProductsResults.length > 0" class="absolute left-0 right-0 top-full mt-1 bg-[#23232d] border border-white/10 rounded-lg shadow-xl z-20 max-h-48 overflow-y-auto">
                                 <div 
                                     v-for="prod in searchProductsResults" 
                                     :key="prod.id"
                                     @click="selectProduct(prod)"
                                     class="px-3 py-2 hover:bg-white/5 cursor-pointer flex items-center gap-3 border-b border-white/5 last:border-0"
                                 >
                                     <img v-if="prod.imagem_produto" :src="prod.imagem_produto" class="w-8 h-8 rounded bg-white/5 object-cover" />
                                     <div v-else class="w-8 h-8 rounded bg-white/5 flex items-center justify-center text-[8px]">IMG</div>
                                     <div>
                                         <p class="text-xs font-bold text-white">{{ prod.nome }}</p>
                                         <p class="text-[10px] text-secondary">{{ prod.quantidade_disponivel }} disp.</p>
                                     </div>
                                 </div>
                             </div>
                         </div>
                    </div>

                    <!-- Quantidade -->
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-1">QUANTIDADE</label>
                        <input 
                            v-model="createForm.quantidade" 
                            type="number" 
                            min="1"
                            class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-white focus:border-primary focus:outline-none text-sm"
                        />
                    </div>

                    <!-- Datas -->
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-bold text-secondary mb-1">RETIRADA</label>
                            <input 
                                v-model="createForm.data_retirada" 
                                type="datetime-local" 
                                class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-white focus:border-primary focus:outline-none text-sm"
                            />
                        </div>
                        <div>
                            <label class="block text-xs font-bold text-secondary mb-1">DEVOLUÇÃO</label>
                            <input 
                                v-model="createForm.data_devolucao" 
                                type="datetime-local" 
                                class="w-full bg-[#0f0f15] border border-white/10 rounded px-3 py-2 text-white focus:border-primary focus:outline-none text-sm"
                            />
                        </div>
                    </div>
                </div>

                <div class="mt-8 flex justify-end gap-3">
                    <button 
                        @click="showCreateModal = false"
                        class="px-4 py-2 text-sm font-bold text-secondary hover:text-white transition-colors"
                    >
                        Cancelar
                    </button>
                    <button 
                        @click="submitCreateReserva"
                        :disabled="loadingCreate"
                        class="px-6 py-2 bg-primary hover:bg-primary-600 text-white text-sm font-bold rounded flex items-center gap-2 disabled:opacity-50"
                    >
                        <svg v-if="loadingCreate" class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                        Confirmar Reserva
                    </button>
                </div>
            </div>
        </div>
    </div>

        <template #sidebar>
             <!-- Sidebar Content (Visible on Desktop) -->
             <div class="space-y-6">
                 <!-- Actions -->
                 <div class="bg-[#16161E] border border-white/5 rounded-xl p-4">
                     <h3 class="text-xs font-bold text-secondary uppercase tracking-wider mb-2">Instruções</h3>
                     <p class="text-xs text-secondary/80 leading-relaxed">
                         Visualize e gerencie suas solicitações de equipamentos.
                     </p>
                     <ul class="mt-4 text-xs text-secondary/70 space-y-2 list-disc pl-4">
                         <li>Reservas pendentes podem ser excluídas.</li>
                         <li>A retirada deve ser feita na Produção.</li>
                         <li>Respeite os prazos de devolução.</li>
                     </ul>
                 </div>
             </div>
        </template>
    </NuxtLayout>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: rgba(255, 255, 255, 0.05); }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 10px; }
</style>
