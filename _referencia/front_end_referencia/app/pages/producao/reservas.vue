<script setup lang="ts">
import { useEstoqueStore } from '~/stores/estoque';
import { useToast } from "../../../composables/useToast";
import DashboardMetrics from '../../../components/producao/dashboard/DashboardMetrics.vue';
import WeeklySchedule from '../../../components/producao/dashboard/WeeklySchedule.vue';
import RecentActivity from '../../../components/producao/dashboard/RecentActivity.vue';
import ConfirmationModal from '../../components/ConfirmationModal.vue';
import ModalRelatorioSemanal from '../../components/producao/ModalRelatorioSemanal.vue';

const estoqueStore = useEstoqueStore();
const { showToast } = useToast();

// State
const activeTab = ref('dashboard'); // dashboard | reservas
const isLoading = ref(false);

// Dashboard State
const dashboardStats = ref(null);
const weeklySchedule = ref<any[]>([]);
const recentActivity = ref<any[]>([]);
const loadingDashboard = ref(false);

// Reservas State
const reservas = ref<any[]>([]);
const reservasPagination = ref({ pagina_atual: 1, qtd_paginas: 1, qtd_itens: 0 });
const buscaReservas = ref('');
let searchReservasTimeout: any;

// Expansion State
const expandedItems = ref<Record<string, any[]>>({});
const loadingDetails = ref<Record<string, boolean>>({});
const expandedReservas = ref<Set<string>>(new Set());

// Create Modal State
const showCreateModal = ref(false);
const createLoading = ref(false);
const userResults = ref<any[]>([]);
const productResults = ref<any[]>([]);
const selectedUser = ref<any>(null);
const selectedProduct = ref<any>(null);
const createForm = ref({
    userSearch: '',
    productSearch: '',
    quantidade: 1,
    data_retirada: '',
    data_devolucao: ''
});

// Delete Modal State
const isDeleting = ref(false);
const showDeleteConfirm = ref(false);
const itemToDelete = ref<any>(null);
const isReportModalOpen = ref(false);

onMounted(() => {
    if (activeTab.value === 'dashboard') fetchDashboardData();
    else if (activeTab.value === 'reservas') fetchReservas();
});

// Watch tab change
watch(activeTab, (newTab) => {
    if (newTab === 'dashboard') fetchDashboardData();
    if (newTab === 'reservas') fetchReservas();
});

// Dashboard Actions
const fetchDashboardData = async () => {
    loadingDashboard.value = true;
    try {
        const [stats, weekly, activity] = await Promise.all([
            estoqueStore.getDashboardStats(),
            estoqueStore.getDashboardWeekly(),
            estoqueStore.getRecentActivity()
        ]);
        dashboardStats.value = stats;
        weeklySchedule.value = weekly || [];
        recentActivity.value = activity || [];
    } catch (e: any) {
        showToast('Erro ao carregar dashboard: ' + e.message, { type: 'error' });
    } finally {
        loadingDashboard.value = false;
    }
};

// Reservas Actions
const fetchReservas = async (page = 1) => {
    isLoading.value = true;
    try {
        const data = await estoqueStore.getReservas({ 
            page, 
            limit: 12,
            busca: buscaReservas.value || undefined
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

watch(buscaReservas, () => {
    clearTimeout(searchReservasTimeout);
    searchReservasTimeout = setTimeout(() => {
        fetchReservas(1);
    }, 500);
});

const handleUpdateReservaStatus = async (reserva: any, newStatus: string) => {
    isLoading.value = true;
    try {
        const result = await estoqueStore.atualizarStatusReserva({
            ids: reserva.ids,
            status: newStatus
        });
        console.log('Reserva Status Update Result:', result);
        showToast(`Reserva atualizada para: ${newStatus}`, { type: 'success' });
        fetchReservas(reservasPagination.value.pagina_atual);
    } catch (e: any) {
        showToast('Erro ao atualizar status: ' + e.message, { type: 'error' });
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
    } else {
        expandedReservas.value.add(id);
        if (!expandedItems.value[id]) {
            await fetchReservaDetails(reserva);
        }
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
    // Set defaults
    const now = new Date();
    // Default Retirada = Now
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
    createForm.value.data_retirada = now.toISOString().slice(0, 16);
    
    // Default Devolucao = +24h
    // Default Devolucao = +24h
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setMinutes(tomorrow.getMinutes() - tomorrow.getTimezoneOffset());
    createForm.value.data_devolucao = tomorrow.toISOString().slice(0, 16);

    createForm.value.userSearch = '';
    createForm.value.productSearch = '';
    createForm.value.quantidade = 1;
    selectedUser.value = null;
    selectedProduct.value = null;
    userResults.value = [];
    productResults.value = [];
    
    showCreateModal.value = true;
};

const closeCreateModal = () => {
    showCreateModal.value = false;
};

const searchUsers = async () => {
    if (createForm.value.userSearch.length < 2) {
        userResults.value = [];
        return;
    }
    userResults.value = await estoqueStore.searchUsers(createForm.value.userSearch);
};

const selectUser = (user: any) => {
    selectedUser.value = user;
    createForm.value.userSearch = ''; // clear search
    userResults.value = [];
};

const clearUser = () => {
    selectedUser.value = null;
};

const searchProducts = async () => {
    if (createForm.value.productSearch.length < 2) {
        productResults.value = [];
        return;
    }
    productResults.value = await estoqueStore.searchProdutos(createForm.value.productSearch);
};

const selectProduct = (prod: any) => {
    selectedProduct.value = prod;
    createForm.value.productSearch = ''; // clear search
    productResults.value = [];
    createForm.value.quantidade = 1;
};

const isFormValid = computed(() => {
    return selectedUser.value && selectedProduct.value && createForm.value.quantidade > 0 && createForm.value.data_retirada;
});

const submitCreateReserva = async () => {
    if (!isFormValid.value) return;
    
    createLoading.value = true;
    try {
        await estoqueStore.createReserva({
            id_usuario: selectedUser.value.id,
            id_produto: selectedProduct.value.id,
            quantidade: createForm.value.quantidade,
            data_retirada: new Date(createForm.value.data_retirada).toISOString(),
            data_devolucao: createForm.value.data_devolucao ? new Date(createForm.value.data_devolucao).toISOString() : null as any
        });
        showToast('Reserva criada com sucesso!', { type: 'success' });
        closeCreateModal();
        fetchReservas(); // Refresh list
    } catch (e: any) {
        showToast('Erro ao criar reserva: ' + e.message, { type: 'error' });
    } finally {
        createLoading.value = false;
    }
};

const confirmDeleteReserva = async () => {
    if (!itemToDelete.value) return;

    isDeleting.value = true;
    try {
        await estoqueStore.deletarReserva(itemToDelete.value.ids);
        showToast('Reserva excluída com sucesso!', { type: 'success' });
        fetchReservas(reservasPagination.value.pagina_atual);
        showDeleteConfirm.value = false;
        itemToDelete.value = null;
    } catch (e: any) {
        showToast(e.message, { type: 'error' });
    } finally {
        isDeleting.value = false;
    }
};
</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-transparent md:bg-div-15 rounded-none md:rounded-xl p-0 md:p-8 flex-1 w-full relative">
            
            <!-- HEADER / TABS -->
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <div>
                    <h1 class="text-2xl font-bold text-white mb-2">Reservas de Produtos</h1>
                    <p class="text-secondary text-sm">Gerencie reservas, retiradas e devoluções.</p>
                </div>
                
                 <div class="flex items-center gap-3 w-full md:w-auto">
                    <!-- Create Button -->
                    <button 
                        @click="openCreateModal"
                        class="bg-primary hover:bg-primary-dark text-white rounded-lg px-3 py-1.5 text-xs font-bold flex items-center gap-2 transition-colors h-[32px]"
                    >
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                        Nova Reserva
                    </button>
                 </div>
            </div>

            <!-- Create Modal -->
            <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
                <div class="bg-[#1A1B26] border border-white/10 rounded-xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl">
                    <div class="p-6 border-b border-white/5 flex justify-between items-center">
                        <h3 class="text-lg font-bold text-white">Nova Reserva</h3>
                        <button @click="closeCreateModal" class="text-secondary hover:text-white">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>
                    
                    <div class="p-6 space-y-6">
                        <!-- User Selection -->
                        <div>
                            <label class="block text-xs font-bold text-secondary uppercase mb-2">Usuário</label>
                            <div class="relative">
                                <input 
                                    v-model="createForm.userSearch" 
                                    @input="searchUsers"
                                    type="text"
                                    class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-primary/50 focus:outline-none"
                                    placeholder="Buscar usuário por nome..."
                                >
                                <!-- Dropdown -->
                                <div v-if="userResults.length > 0" class="absolute z-10 w-full mt-1 bg-[#16161E] border border-white/10 rounded-lg shadow-xl max-h-48 overflow-y-auto">
                                    <div 
                                        v-for="user in userResults" 
                                        :key="user.id"
                                        @click="selectUser(user)"
                                        class="p-3 hover:bg-white/5 cursor-pointer flex justify-between items-center border-b border-white/5 last:border-0"
                                    >
                                        <div>
                                            <div class="text-white text-sm font-bold">{{ user.nome }} {{ user.sobrenome }}</div>
                                            <div class="text-secondary text-xs">{{ user.email }}</div>
                                        </div>
                                        <div class="text-[10px] uppercase font-bold bg-white/10 px-2 py-0.5 rounded text-secondary">{{ user.papel }}</div>
                                    </div>
                                </div>
                            </div>
                            <div v-if="selectedUser" class="mt-2 flex items-center gap-2 bg-primary/10 border border-primary/20 rounded-lg p-2">
                                <div class="w-6 h-6 rounded-full bg-primary/20 text-primary flex items-center justify-center font-bold text-xs">
                                    {{ selectedUser.nome.charAt(0).toUpperCase() }}
                                </div>
                                <span class="text-sm font-bold text-white">{{ selectedUser.nome }} {{ selectedUser.sobrenome }}</span>
                                <button @click="clearUser" class="ml-auto text-secondary hover:text-white text-xs">Alterar</button>
                            </div>
                        </div>

                        <!-- Product Selection -->
                        <div class="grid grid-cols-3 gap-4">
                            <div class="col-span-2">
                                <label class="block text-xs font-bold text-secondary uppercase mb-2">Produto</label>
                                <div class="relative">
                                     <input 
                                        v-model="createForm.productSearch" 
                                        @input="searchProducts"
                                        type="text"
                                        class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-primary/50 focus:outline-none"
                                        placeholder="Buscar produto..."
                                    >
                                    <!-- Dropdown -->
                                    <div v-if="productResults.length > 0" class="absolute z-10 w-full mt-1 bg-[#16161E] border border-white/10 rounded-lg shadow-xl max-h-48 overflow-y-auto">
                                        <div 
                                            v-for="prod in productResults" 
                                            :key="prod.id"
                                            @click="selectProduct(prod)"
                                            class="p-2 hover:bg-white/5 cursor-pointer flex items-center gap-3 border-b border-white/5 last:border-0"
                                        >
                                            <img :src="prod.imagem || 'https://via.placeholder.com/40'" class="w-8 h-8 rounded object-cover bg-white/5">
                                            <div class="flex-1">
                                                <div class="text-white text-sm font-bold">{{ prod.nome }}</div>
                                                <div class="text-secondary text-xs">Disp: {{ prod.qtd_disponivel }}</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                 <div v-if="selectedProduct" class="mt-2 flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/20 rounded-lg p-2">
                                    <span class="text-sm font-bold text-emerald-500">{{ selectedProduct.nome }}</span>
                                    <span class="text-xs text-secondary ml-auto">Disponível: {{ selectedProduct.qtd_disponivel }}</span>
                                </div>
                            </div>
                            <div>
                                <label class="block text-xs font-bold text-secondary uppercase mb-2">Quantidade</label>
                                <input 
                                    v-model="createForm.quantidade" 
                                    type="number" 
                                    min="1"
                                    :max="selectedProduct?.qtd_disponivel || 1"
                                    class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-primary/50 focus:outline-none"
                                >
                            </div>
                        </div>

                        <!-- Dates -->
                        <div class="grid grid-cols-2 gap-4">
                            <div>
                                <label class="block text-xs font-bold text-secondary uppercase mb-2">Data Retirada (Prev)</label>
                                <input 
                                    v-model="createForm.data_retirada" 
                                    type="datetime-local"
                                    class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white/70 focus:border-primary/50 focus:outline-none text-sm"
                                >
                            </div>
                            <div>
                                <label class="block text-xs font-bold text-secondary uppercase mb-2">Data Devolução (Prev)</label>
                                <input 
                                    v-model="createForm.data_devolucao" 
                                    type="datetime-local"
                                    class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white/70 focus:border-primary/50 focus:outline-none text-sm"
                                >
                            </div>
                        </div>
                    </div>

                    <div class="p-6 border-t border-white/5 flex justify-end gap-3">
                        <button @click="closeCreateModal" class="px-4 py-2 text-secondary hover:text-white transition-colors text-sm font-bold">Cancelar</button>
                        <button 
                            @click="submitCreateReserva" 
                            :disabled="!isFormValid || createLoading"
                            class="bg-primary hover:bg-primary-dark disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg px-6 py-2 text-sm font-bold transition-colors flex items-center gap-2"
                        >
                            <svg v-if="createLoading" class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                            Confirmar Reserva
                        </button>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <div class="flex items-center gap-6 border-b border-secondary/10 w-full mb-8 pb-1 overflow-x-auto no-scrollbar">
                <button 
                    @click="activeTab = 'dashboard'"
                    class="text-sm font-bold pb-2 relative transition-colors whitespace-nowrap"
                    :class="activeTab === 'dashboard' ? 'text-primary' : 'text-secondary hover:text-white'"
                >
                    Visão Geral
                    <span v-if="activeTab === 'dashboard'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                </button>
                <button 
                    @click="activeTab = 'reservas'"
                    class="text-sm font-bold pb-2 relative transition-colors whitespace-nowrap"
                    :class="activeTab === 'reservas' ? 'text-primary' : 'text-secondary hover:text-white'"
                >
                    Todas as Reservas
                    <span v-if="activeTab === 'reservas'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                </button>
            </div>

            <!-- CONTENT AREA -->
            <div>

                <!-- DASHBOARD TAB -->
                <div v-if="activeTab === 'dashboard'">
                    <div v-if="loadingDashboard" class="flex justify-center py-20">
                        <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    </div>
                    <div v-else class="flex flex-col h-full">
                         <!-- Weekly Schedule (Takes full width in main area) -->
                         <WeeklySchedule :events="weeklySchedule" class="h-full" />
                    </div>
                </div>
                
                <!-- RESERVAS TAB -->
                <div v-if="activeTab === 'reservas'">
                    
                    <!-- Search Bar -->
                     <div class="mb-6">
                        <div class="relative">
                            <input 
                                v-model="buscaReservas"
                                type="text" 
                                placeholder="Buscar reservas por nome do usuário..." 
                                class="w-full bg-[#16161E] border border-white/10 rounded-xl px-4 py-3 pl-11 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/50 transition-colors"
                            />
                            <div class="absolute left-4 top-3.5 text-secondary/50">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                            </div>
                        </div>
                    </div>

                    <!-- Loading -->
                    <div v-if="isLoading && reservas.length === 0" class="py-20 flex justify-center">
                         <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    </div>

                    <!-- Empty -->
                    <div v-else-if="reservas.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 border border-dashed border-white/10 rounded-xl">
                        <div class="text-4xl mb-4 text-secondary/50">
                            <svg class="w-16 h-16" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                        </div>
                        <p class="text-white font-medium">Nenhuma reserva encontrada</p>
                    </div>

                    <!-- Cards Grid -->
                    <div v-else class="grid grid-cols-1 gap-4">
                        <div 
                            v-for="reserva in reservas" 
                            :key="reserva.ids[0]" 
                            class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col relative overflow-hidden group hover:border-primary/50 transition-colors"
                        >
                            <!-- Card Header: User & Status -->
                            <div class="flex items-center justify-between mb-3 border-b border-white/5 pb-2">
                                <div class="flex items-center gap-3">
                                    <div class="w-6 h-6 rounded-full bg-primary/20 text-primary flex items-center justify-center font-bold text-xs">
                                        {{ reserva.nome_usuario.charAt(0).toUpperCase() }}
                                    </div>
                                    <h4 class="font-bold text-white text-sm">{{ reserva.nome_usuario }}</h4>
                                </div>
                                <div class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider border"
                                    :class="{
                                        'bg-amber-500/10 text-amber-500 border-amber-500/20': reserva.status === 'reservado',
                                        'bg-blue-500/10 text-blue-500 border-blue-500/20': reserva.status === 'retirado',
                                        'bg-emerald-500/10 text-emerald-500 border-emerald-500/20': reserva.status === 'devolvido',
                                        'bg-red-500/10 text-red-500 border-red-500/20': ['atrasado', 'cancelado'].includes(reserva.status)
                                    }"
                                >
                                    {{ reserva.status }}
                                </div>
                            </div>

                            <!-- Main Content: Product & Quantity (Horizontal) -->
                            <div class="flex items-center gap-3 mb-3">
                                <h3 class="text-base font-bold text-white leading-tight">{{ reserva.produto_nome }}</h3>
                                <div class="bg-primary/10 text-primary border border-primary/20 rounded px-2 py-0.5 text-xs font-bold flex items-center gap-1">
                                    <span>{{ reserva.qtd_itens }}</span>
                                    <span class="text-[8px] uppercase opacity-70">unid</span>
                                </div>
                            </div>

                            <!-- Dates Grid (Compact) -->
                            <div class="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-3 bg-white/5 p-2 rounded text-[10px]">
                                <div>
                                    <span class="text-secondary block font-bold">Reservado</span>
                                    <span class="text-white">{{ new Date(reserva.data_reserva).toLocaleString() }}</span>
                                </div>
                                <div v-if="reserva.data_retirada">
                                    <span class="text-secondary block font-bold">Retirado</span>
                                    <span class="text-white">{{ new Date(reserva.data_retirada).toLocaleString() }}</span>
                                </div>
                                <div>
                                    <span class="text-secondary block font-bold">Prev. Devolução</span>
                                    <span class="text-white">{{ reserva.data_devolucao ? new Date(reserva.data_devolucao).toLocaleDateString() : '-' }}</span>
                                </div>
                                <div v-if="reserva.data_devolvido">
                                    <span class="text-secondary block font-bold">Devolvido</span>
                                    <span class="text-white">{{ new Date(reserva.data_devolvido).toLocaleString() }}</span>
                                </div>
                            </div>

                             <!-- Actions Bar -->
                             <div class="flex items-center justify-between gap-3 pt-2 border-t border-white/5">
                                <!-- Expand Button -->
                                <button 
                                    @click="toggleExpand(reserva)"
                                    class="text-xs text-secondary hover:text-white transition-colors flex items-center gap-1 font-medium"
                                >
                                    <span v-if="isExpanded(reserva)">Ocultar Itens</span>
                                    <span v-else>Ver Itens ({{ reserva.qtd_itens }})</span>
                                    <svg class="w-3 h-3 transition-transform duration-200" :class="isExpanded(reserva) ? 'rotate-180' : ''" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                                </button>

                                <!-- Management Buttons -->
                                <div class="flex items-center gap-2">
                                    <button 
                                        v-if="reserva.status === 'reservado'"
                                        @click="handleUpdateReservaStatus(reserva, 'retirado')"
                                        class="bg-blue-500 hover:bg-blue-600 text-white rounded px-3 py-1 text-[10px] font-bold uppercase transition-colors"
                                    >
                                        Retirar
                                    </button>

                                    <button 
                                        v-if="reserva.status === 'retirado'"
                                        @click="handleUpdateReservaStatus(reserva, 'devolvido')"
                                        class="bg-emerald-500 hover:bg-emerald-600 text-white rounded px-3 py-1 text-[10px] font-bold uppercase transition-colors"
                                    >
                                    Devolver
                                    </button>

                                    <button 
                                        @click="handleDeleteReserva(reserva)"
                                        class="text-secondary hover:text-danger p-1 transition-colors"
                                        title="Excluir"
                                    >
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                    </button>
                                </div>
                             </div>

                             <!-- Expanded Content -->
                             <div v-if="isExpanded(reserva)" class="mt-3 pt-3 border-t border-white/5 bg-black/20 -mx-5 -mb-5 px-5 pb-4">
                                 <div v-if="loadingDetails[reserva.ids[0]]" class="flex justify-center py-2">
                                     <svg class="animate-spin h-4 w-4 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                                 </div>
                                 <div v-else class="flex flex-col gap-1">
                                     <div v-for="item in expandedItems[reserva.ids[0]] || []" :key="item.id" class="flex items-center justify-between text-[10px] bg-white/5 px-2 py-1.5 rounded font-mono hover:bg-white/10 transition-colors">
                                         <span class="text-white">ID: {{ item.id.split('-')[0] }}...</span>
                                         <span class="text-primary">{{ item.codigo_barras || 'S/N' }}</span>
                                         <span class="text-secondary">{{ item.status_item || 'Indefinido' }}</span>
                                     </div>
                                 </div>
                             </div>

                        </div>
                    </div>

                    <!-- Pagination -->
                    <div v-if="reservas.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-8 pt-4 border-t border-white/5">
                         <span class="text-xs md:text-sm text-secondary-500 order-2 md:order-1">
                            <span class="font-medium text-white">{{ (reservasPagination.pagina_atual - 1) * 12 + 1 }}</span> a <span class="font-medium text-white">{{ Math.min(reservasPagination.pagina_atual * 12, reservasPagination.qtd_itens) }}</span> de <span class="font-medium text-white">{{ reservasPagination.qtd_itens }}</span>
                        </span>
                        <div class="flex gap-2 order-1 md:order-2">
                            <button 
                                @click="fetchReservas(reservasPagination.pagina_atual - 1)" 
                                :disabled="reservasPagination.pagina_atual === 1"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Anterior
                            </button>
                            <button 
                                @click="fetchReservas(reservasPagination.pagina_atual + 1)" 
                                :disabled="reservasPagination.pagina_atual >= reservasPagination.qtd_paginas"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Próxima
                            </button>
                        </div>
                    </div>
                </div>

                </div>

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

             <!-- Report Modal -->
             <ModalRelatorioSemanal 
                :isOpen="isReportModalOpen"
                @close="isReportModalOpen = false"
             />

        </div>

        <template #sidebar>
             <!-- Sidebar Content (Visible on Desktop) -->
             <div class="space-y-6">
                 <!-- Actions -->
                 <div class="bg-[#16161E] border border-white/5 rounded-xl p-4">
                     <h3 class="text-xs font-bold text-secondary uppercase tracking-wider mb-4">Ações Rápidas</h3>
                     <button 
                        @click="isReportModalOpen = true"
                        class="w-full bg-white/5 hover:bg-white/10 text-xs font-bold text-secondary hover:text-white py-3 px-4 rounded-lg border border-white/5 transition-colors flex items-center justify-between group"
                     >
                         <span>Relatório Semanal</span>
                         <svg class="w-4 h-4 opacity-50 group-hover:opacity-100" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                     </button>
                 </div>

                 <!-- Metrics -->
                 <DashboardMetrics :stats="dashboardStats" class="!grid-cols-2" />
                 
                 <!-- Activity -->
                 <RecentActivity :activity="recentActivity" />
             </div>
        </template>
    </NuxtLayout>
</template>
