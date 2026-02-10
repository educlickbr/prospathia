<script setup lang="ts">
import { useAppStore } from '~/stores/app';
import { useEstoqueStore } from '~/stores/estoque';
import { useToast } from "../../../composables/useToast";

import ConfirmationModal from '../../components/ConfirmationModal.vue';
import KitFormModal from '../../components/producao/estoque/KitFormModal.vue';
import ProductFormModal from '../../components/producao/estoque/ProductFormModal.vue';
import AvariasModal from '../../components/producao/estoque/AvariasModal.vue';

const store = useAppStore();
const estoqueStore = useEstoqueStore();
const { showToast } = useToast();

// State
const activeTab = ref('kits'); // kits | produtos | estoque
const isLoading = ref(false);

// Kits State
const kits = ref<any[]>([]);
const showKitModal = ref(false);
const editingKit = ref<any>(null); // null = creating, object = editing

// Delete Modal State
const showDeleteConfirm = ref(false);
const itemToDelete = ref<any>(null);
const isDeleting = ref(false);

// Stock Items State (Avarias Tab)
const estoqueItens = ref<any[]>([]);
const showAvariasModal = ref(false);
const selectedEstoqueItem = ref<any>(null);
const estoquePagination = ref({ pagina_atual: 1, qtd_paginas: 1, qtd_itens: 0 });
const buscaEstoque = ref('');
let searchEstoqueTimeout: any;

const showKitSelectModal = ref(false);
const itemToAssociate = ref<any>(null);
const selectedKitId = ref<string>('');

// Products State

// Products State
const produtos = ref<any[]>([]);
const produtosPagination = ref({ pagina_atual: 1, qtd_paginas: 1, qtd_itens: 0 });
const busca = ref('');
let searchTimeout: any;

// Product Modal State
const showProductModal = ref(false);
const editingProduct = ref<any>(null);
const categorias = ref<any[]>([]);
const unidades = ref<any[]>([]);
const tipos = ref<any[]>([]);

const fetchProdutos = async (page = 1) => {
    isLoading.value = true;
    try {
        const data = await estoqueStore.getProdutos({
            page: page,
            limit: 12,
            busca: busca.value || undefined
        });
        
        if (data) {
            produtos.value = (data.itens || []).map((p: any) => ({
                ...p,
                quantidade_a_adicionar: 0
            }));
            
            produtosPagination.value = {
                pagina_atual: data.pagina_atual,
                qtd_paginas: data.qtd_paginas,
                qtd_itens: data.qtd_itens
            };
        }
    } catch (e: any) {
        showToast('Erro ao carregar produtos: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

// Search Watcher
watch(busca, () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        fetchProdutos(1);
    }, 500);
});

const handleAddStock = async (prod: any) => {
    if (!prod.quantidade_a_adicionar || prod.quantidade_a_adicionar <= 0) return;

    isLoading.value = true;
    try {
        await estoqueStore.adicionarEstoqueLote({
            id_produto: prod.id,
            quantidade: prod.quantidade_a_adicionar,
            valor_inicial: prod.valor_inicial // Optional, using current product value
        });
        
        showToast(`${prod.quantidade_a_adicionar} itens adicionados ao estoque!`, { type: 'success' });
        await fetchProdutos(produtosPagination.value.pagina_atual);
        
    } catch (e: any) {
        showToast('Erro ao adicionar estoque: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

// Product Modal Actions
const loadAuxiliaries = async () => {
    if (categorias.value.length === 0) {
        isLoading.value = true;
        try {
            const [cats, units, types] = await Promise.all([
                estoqueStore.getCategorias(),
                estoqueStore.getUnidades(),
                estoqueStore.getTipos()
            ]);
            categorias.value = cats || [];
            unidades.value = units || [];
            tipos.value = types || [];
        } catch (e) {
            console.error(e);
            showToast("Erro ao carregar auxiliares", { type: 'error' });
        } finally {
            isLoading.value = false;
        }
    }
}

const openCreateProductModal = async () => {
    await loadAuxiliaries();
    editingProduct.value = null;
    showProductModal.value = true;
};

const openEditProductModal = async (prod: any) => {
    await loadAuxiliaries();
    editingProduct.value = prod;
    showProductModal.value = true;
};

const handleSaveProduct = async (formData: any) => {
    if (!formData.nome || !formData.id_categoria || !formData.id_unidade) {
        showToast("Preencha os campos obrigatórios (*)", { type: 'error' });
        return;
    }

    isLoading.value = true;
    try {
         if (editingProduct.value) {
            // Update
            await estoqueStore.atualizarProduto({
                id: editingProduct.value.id,
                nome: formData.nome,
                id_categoria_produto: formData.id_categoria, // Store handles mapping
                id_tipo_produto: formData.id_tipo,
                id_unidade: formData.id_unidade,
                treshold: formData.treshold,
                valor_inicial: formData.valor_inicial,
                codigo_barras: formData.codigo_barras,
                observacoes: formData.observacoes
            });
            showToast("Produto atualizado com sucesso!", { type: 'success' });
        } else {
            await estoqueStore.criarProduto(formData);
            showToast("Produto criado com sucesso!", { type: 'success' });
        }
        showProductModal.value = false;
        fetchProdutos(produtosPagination.value.pagina_atual);
    } catch (e: any) {
        showToast('Erro ao salvar produto: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const handleDeleteProduct = (prod: any) => {
    itemToDelete.value = { ...prod, type: 'produto' }; 
    showDeleteConfirm.value = true;
};

const confirmDeleteProduct = async () => {
    isDeleting.value = true;
    try {
        await estoqueStore.deletarProduto(itemToDelete.value.id);
        showToast('Produto excluído com sucesso!', { type: 'success' });
        fetchProdutos(1);
        showDeleteConfirm.value = false;
        itemToDelete.value = null;
    } catch (e: any) {
        showToast(e.message, { type: 'error' });
    } finally {
        isDeleting.value = false;
    }
};


// Fetch Data
const fetchKits = async () => {
// ... existing fetchKits ...
    isLoading.value = true;
    try {
        const data = await estoqueStore.getKits();
        kits.value = data || [];
    } catch (e: any) {
        showToast('Erro ao carregar kits: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

// ... existing code ...


// Kit Actions
const openCreateKitModal = () => {
    editingKit.value = null;
    showKitModal.value = true;
};

const openEditKitModal = (kit: any) => {
    editingKit.value = kit;
    showKitModal.value = true;
};

const handleSaveKit = async (formData: any) => {
    if (!formData.nome.trim()) return;
    
    isLoading.value = true;
    try {
        if (editingKit.value) {
            // Update
            await estoqueStore.atualizarKit({
                id: editingKit.value.id,
                nome: formData.nome
            });
            showToast('Kit atualizado com sucesso!', { type: 'success' });
        } else {
            // Create
            await estoqueStore.criarKit({
                nome: formData.nome
            });
            showToast('Kit criado com sucesso!', { type: 'success' });
        }
        showKitModal.value = false;
        fetchKits();
    } catch (e: any) {
        showToast('Erro ao salvar kit: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const handleDeleteKit = (kit: any) => {
    itemToDelete.value = kit;
    showDeleteConfirm.value = true;
};

const confirmDeleteKit = async () => {
    if (!itemToDelete.value) return;

    isDeleting.value = true;
    try {
        await estoqueStore.deletarKit(itemToDelete.value.id);
        showToast('Kit excluído com sucesso!', { type: 'success' });
        fetchKits();
        showDeleteConfirm.value = false;
        itemToDelete.value = null;
    } catch (e: any) {
        showToast('Erro ao excluir kit: ' + e.message, { type: 'error' });
    } finally {
        isDeleting.value = false;
    }
};

const confirmDelete = async () => {
    if (!itemToDelete.value) return;

    if (itemToDelete.value.type === 'produto') {
        await confirmDeleteProduct();
    } else if (itemToDelete.value.type === 'estoque') {
        await confirmDeleteEstoqueItem();
    } else {
        await confirmDeleteKit();
    }
};

const confirmDeleteEstoqueItem = async () => {
    isDeleting.value = true;
    try {
        await estoqueStore.deletarEstoque(itemToDelete.value.id);
        showToast('Item removido do estoque!', { type: 'success' });
        fetchEstoqueItens(estoquePagination.value.pagina_atual);
        showDeleteConfirm.value = false;
        itemToDelete.value = null;
    } catch (e: any) {
        showToast(e.message, { type: 'error' });
    } finally {
        isDeleting.value = false;
    }
}

// Stock Items Actions
const fetchEstoqueItens = async (page = 1) => {
    isLoading.value = true;
    try {
        const data = await estoqueStore.getItensEstoque({ 
            page, 
            limit: 12,
            busca: buscaEstoque.value || undefined
        });
        if (data) {
            estoqueItens.value = data.itens || [];
            estoquePagination.value = {
                pagina_atual: data.pagina_atual,
                qtd_paginas: data.qtd_paginas,
                qtd_itens: data.qtd_itens
            };
        }
    } catch (e: any) {
        showToast('Erro ao carregar estoque: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

// Search Watcher for Stock
watch(buscaEstoque, () => {
    clearTimeout(searchEstoqueTimeout);
    searchEstoqueTimeout = setTimeout(() => {
        fetchEstoqueItens(1);
    }, 500);
});

const openAvariasModal = (item: any) => {
    selectedEstoqueItem.value = item;
    showAvariasModal.value = true;
};

const handleDeleteEstoqueItem = (item: any) => {
    itemToDelete.value = { ...item, type: 'estoque', nome: `${item.produto.nome} (${item.id.split('-')[0]})` };
    showDeleteConfirm.value = true;
};

const handleDeleteReserva = (reserva: any) => {
    itemToDelete.value = { ...reserva, type: 'reserva', nome: `Reserva de ${reserva.nome_usuario}` };
    showDeleteConfirm.value = true;
};

const openAssociateKitModal = (item: any) => {
    itemToAssociate.value = item;
    // If item already has a kit, pre-select it (assuming id_kit is returned, we need to ensure query returns it)
    // For now assuming id_kit might be on the item if we updated the query, but let's just default to empty
    selectedKitId.value = ''; 
    // We should ensure kits are loaded
    if (kits.value.length === 0) fetchKits();
    showKitSelectModal.value = true;
};

const handleAssociateKit = async () => {
    if (!itemToAssociate.value) return;
    
    isLoading.value = true;
    try {
        await estoqueStore.associarKit(itemToAssociate.value.id, selectedKitId.value || null);
        showToast(selectedKitId.value ? 'Item associado ao kit!' : 'Associação removida!', { type: 'success' });
        showKitSelectModal.value = false;
        fetchEstoqueItens(estoquePagination.value.pagina_atual);
    } catch (e: any) {
        showToast(e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const hasActiveAvaria = (avarias: any[]) => {
    if (!avarias || avarias.length === 0) return false;
    return avarias.some((a: any) => !['Reparado', 'Não se Aplica', 'Descartado'].includes(a.status_reparo));
};

const getAvariaSummary = (avarias: any[]) => {
    if (!avarias || avarias.length === 0) return 'Sem avarias';
    const active = avarias.filter((a: any) => !['Reparado', 'Não se Aplica', 'Descartado'].includes(a.status_reparo));
    if (active.length > 0) return `${active.length} Pendente(s)`;
    return 'Avarias Resolvidas';
};

const getActiveAvariaStatus = (item: any) => {
    if (!item.avarias || !Array.isArray(item.avarias)) return 'AVARIA';
    const active = item.avarias.find((a: any) => ['Pendente', 'Em Reparo', 'Descartado'].includes(a.status_reparo));
    return active ? active.status_reparo : 'AVARIA';
};

// Initial Fetch
onMounted(() => {
    if (activeTab.value === 'kits') fetchKits();
    if (activeTab.value === 'produtos') fetchProdutos();
    if (activeTab.value === 'estoque') fetchEstoqueItens();
});

// Watch tab change
watch(activeTab, (newTab) => {
    if (newTab === 'kits') fetchKits();
    if (newTab === 'produtos') fetchProdutos();
    if (newTab === 'estoque') fetchEstoqueItens();
});
</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-div-15 rounded-xl p-6 md:p-8 min-h-[calc(100vh-100px)]">
            
            <!-- HEADER / TABS -->
            <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-8">
                <!-- Tabs -->
                <div class="flex items-center gap-6 border-b border-secondary/10 w-full md:w-auto pb-1 overflow-x-auto no-scrollbar">
                    <button 
                        @click="activeTab = 'kits'"
                        class="text-sm font-bold pb-2 relative transition-colors whitespace-nowrap"
                        :class="activeTab === 'kits' ? 'text-primary' : 'text-secondary hover:text-white'"
                    >
                        Kits
                        <span v-if="activeTab === 'kits'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                    </button>
                    <button 
                        @click="activeTab = 'produtos'"
                        class="text-sm font-bold pb-2 relative transition-colors whitespace-nowrap"
                        :class="activeTab === 'produtos' ? 'text-primary' : 'text-secondary hover:text-white'"
                    >
                        Produtos
                        <span v-if="activeTab === 'produtos'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                    </button>
                    <button 
                        @click="activeTab = 'estoque'"
                        class="text-sm font-bold pb-2 relative transition-colors whitespace-nowrap"
                        :class="activeTab === 'estoque' ? 'text-primary' : 'text-secondary hover:text-white'"
                    >
                        Estoque / Avarias
                        <span v-if="activeTab === 'estoque'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                    </button>
                </div>

                <!-- Action Button -->
                <div v-if="activeTab === 'kits'">
                    <button 
                        @click="openCreateKitModal"
                        class="bg-primary hover:bg-primary/80 text-white text-xs font-bold uppercase tracking-wider px-4 py-2 rounded-lg flex items-center gap-2 transition-colors"
                    >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                        Novo Kit
                    </button>
                </div>
                <div v-if="activeTab === 'produtos'">
                    <button 
                        @click="openCreateProductModal"
                        class="bg-primary hover:bg-primary/80 text-white text-xs font-bold uppercase tracking-wider px-4 py-2 rounded-lg flex items-center gap-2 transition-colors"
                    >
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                        Novo Produto
                    </button>
                </div>
                <div v-if="activeTab === 'estoque'">
                     <!-- Actions for Estoque could be added here later -->
                </div>
            </div>

            <!-- CONTENT AREA -->
            <div>
                <!-- KITS TAB -->
                <div v-if="activeTab === 'kits'">
                    
                    <!-- Loading -->
                    <div v-if="isLoading" class="py-20 flex justify-center">
                         <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    </div>

                    <!-- Empty State -->
                    <div v-else-if="kits.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 border border-dashed border-white/10 rounded-xl">
                        <div class="text-4xl mb-4 text-secondary/50">
                             <svg class="w-16 h-16" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"></line><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
                        </div>
                        <p class="text-white font-medium">Nenhum kit encontrado</p>
                        <button @click="openCreateKitModal" class="text-xs text-primary mt-2 hover:underline">Criar op primeiro kit</button>
                    </div>

                    <!-- Grid List -->
                    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        <div v-for="kit in kits" :key="kit.id" class="bg-[#16161E] border border-white/5 rounded-xl p-4 flex flex-col justify-between hover:border-white/10 transition-colors group">
                            
                            <!-- Header -->
                            <div class="flex items-start justify-between mb-4">
                                <div class="flex items-center gap-3">
                                    <div class="w-10 h-10 rounded-lg bg-emerald-500/10 text-emerald-500 flex items-center justify-center">
                                       <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"></line><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
                                    </div>
                                    <div>
                                        <h4 class="text-sm font-bold text-white">{{ kit.nome }}</h4>
                                        <p class="text-[10px] text-secondary">ID: {{ kit.id.split('-')[0] }}...</p>
                                    </div>
                                </div>
                            </div>

                            <!-- Actions -->
                            <div class="flex items-center justify-end gap-2 pt-3 border-t border-white/5 opacity-0 group-hover:opacity-100 transition-opacity">
                                <button 
                                    @click="openEditKitModal(kit)" 
                                    class="p-1.5 rounded hover:bg-white/10 text-secondary hover:text-white transition-colors" 
                                    title="Editar"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                                </button>
                                <button 
                                    @click="handleDeleteKit(kit)" 
                                    class="p-1.5 rounded hover:bg-danger/10 text-secondary hover:text-danger transition-colors" 
                                    title="Excluir"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- PRODUTOS TAB -->
                <div v-if="activeTab === 'produtos'">
                    
                    <!-- Search Bar -->
                    <div class="mb-6">
                        <div class="relative">
                            <input 
                                v-model="busca"
                                type="text" 
                                placeholder="Buscar produtos por nome..." 
                                class="w-full bg-[#16161E] border border-white/10 rounded-xl px-4 py-3 pl-11 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/50 transition-colors"
                            />
                            <div class="absolute left-4 top-3.5 text-secondary/50">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                            </div>
                        </div>
                    </div>

                    <!-- Loading -->
                    <div v-if="isLoading && produtos.length === 0" class="py-20 flex justify-center">
                         <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    </div>

                    <!-- Products Grid -->
                    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                        <div v-for="prod in produtos" :key="prod.id" class="bg-[#16161E] border border-white/5 rounded-xl p-5 flex flex-col justify-between hover:border-white/10 transition-all group relative overflow-hidden">
                            
                            <!-- Badges -->
                            <div class="flex items-center gap-2 mb-3">
                                <span v-if="prod.categoria" class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-primary/10 text-primary border border-primary/20">
                                    {{ prod.categoria.nome }}
                                </span>
                                <span v-if="prod.tipo" class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-white/5 text-secondary border border-white/10">
                                    {{ prod.tipo.nome }}
                                </span>
                            </div>

                            <!-- Actions (Consolidated with Kit Design) -->
                            <div class="absolute top-3 right-3 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity z-20">
                                <button 
                                    @click.stop="openEditProductModal(prod)" 
                                    class="p-1.5 rounded hover:bg-white/10 text-secondary hover:text-white transition-colors backdrop-blur-sm" 
                                    title="Editar Produto"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                                </button>
                                <button 
                                    @click.stop="handleDeleteProduct(prod)" 
                                    class="p-1.5 rounded hover:bg-danger/10 text-secondary hover:text-danger conversion-colors backdrop-blur-sm" 
                                    title="Excluir Produto"
                                >
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                </button>
                            </div>

                            <!-- Content -->
                            <div class="mb-6">
                                <h3 class="text-base font-bold text-white leading-tight mb-1 line-clamp-2" :title="prod.nome">
                                    {{ prod.nome }}
                                </h3>
                                <div class="flex items-center gap-2 text-xs text-secondary/60">
                                    <span v-if="prod.unidade">{{ prod.unidade.nome }}</span>
                                    <span v-if="prod.codigo_barras" class="font-mono bg-black/30 px-1 rounded text-[10px]">{{ prod.codigo_barras }}</span>
                                </div>
                            </div>


                            <!-- Footer / Stock Action -->
                            <div class="mt-auto pt-4 border-t border-white/5">
                                <div class="flex items-center justify-between mb-3">
                                    <div class="flex items-center gap-2">
                                        <div class="w-2 h-2 rounded-full" :class="prod.total_estoque > (prod.treshold || 0) ? 'bg-emerald-500' : 'bg-red-500'"></div>
                                        <span class="text-xs font-medium text-white">
                                            Estoque: <span class="font-bold">{{ prod.total_estoque }}</span>
                                        </span>
                                    </div>
                                    <span v-if="prod.treshold" class="text-[10px] text-secondary" title="Estoque Mínimo">Min: {{ prod.treshold }}</span>
                                </div>

                                <!-- Quick Add Form -->
                                <div class="flex items-center gap-2">
                                    <input 
                                        v-model.number="prod.quantidade_a_adicionar" 
                                        type="number" 
                                        min="0"
                                        placeholder="+ Qtd"
                                        class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-xs text-white focus:border-primary focus:outline-none placeholder-secondary/30 transition-colors"
                                        @click.stop
                                    />
                                    <button 
                                        @click.stop="handleAddStock(prod)"
                                        :disabled="!prod.quantidade_a_adicionar || prod.quantidade_a_adicionar <= 0"
                                        class="bg-primary hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed text-white p-2 rounded-lg transition-colors flex-shrink-0"
                                        title="Adicionar ao Estoque"
                                    >
                                        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                                    </button>
                                </div>
                            </div>

                        </div>
                    </div>
                    
                    <!-- Pagination (Advanced View) -->
                    <div v-if="produtos.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-8 pt-4 border-t border-white/5">
                        <span class="text-xs md:text-sm text-secondary-500 order-2 md:order-1">
                            <span class="font-medium text-white">{{ (produtosPagination.pagina_atual - 1) * 12 + 1 }}</span> a <span class="font-medium text-white">{{ Math.min(produtosPagination.pagina_atual * 12, produtosPagination.qtd_itens) }}</span> de <span class="font-medium text-white">{{ produtosPagination.qtd_itens }}</span>
                        </span>
                        <div class="flex gap-2 order-1 md:order-2">
                            <button 
                                @click="fetchProdutos(produtosPagination.pagina_atual - 1)" 
                                :disabled="produtosPagination.pagina_atual === 1"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Anterior
                            </button>
                            <button 
                                @click="fetchProdutos(produtosPagination.pagina_atual + 1)" 
                                :disabled="produtosPagination.pagina_atual >= produtosPagination.qtd_paginas"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Próxima
                            </button>
                        </div>
                    </div>

                </div>

                <!-- ESTOQUE / AVARIAS TAB -->
                <div v-if="activeTab === 'estoque'">
                    
                     <!-- Search Bar -->
                     <div class="mb-6">
                        <div class="relative">
                            <input 
                                v-model="buscaEstoque"
                                type="text" 
                                placeholder="Buscar itens em estoque por nome do produto..." 
                                class="w-full bg-[#16161E] border border-white/10 rounded-xl px-4 py-3 pl-11 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/50 transition-colors"
                            />
                            <div class="absolute left-4 top-3.5 text-secondary/50">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                            </div>
                        </div>
                    </div>

                    <!-- Loading -->
                    <div v-if="isLoading && estoqueItens.length === 0" class="py-20 flex justify-center">
                         <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    </div>

                    <!-- Empty -->
                    <div v-else-if="estoqueItens.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 border border-dashed border-white/10 rounded-xl">
                        <div class="text-4xl mb-4 text-secondary/50">
                            <svg class="w-16 h-16" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>
                        </div>
                        <p class="text-white font-medium">Nenhum item de estoque encontrado</p>
                    </div>

                    <!-- Cards Grid -->
                    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                        <div 
                            v-for="item in estoqueItens" 
                            :key="item.id" 
                            class="bg-[#16161E] border border-white/5 rounded-xl p-4 flex flex-col gap-4 relative overflow-hidden group hover:border-primary/50 transition-colors"
                        >
                            <!-- Top Bar -->
                            <div class="flex justify-between items-start">
                                <div>
                                    <h4 class="font-bold text-white text-sm line-clamp-2 leading-tight">{{ item.produto?.nome || 'Produto Desconhecido' }}</h4>
                                    <span class="text-[10px] uppercase font-bold text-secondary mt-1 block">
                                        ID: {{ item.id.split('-')[0] }}
                                    </span>
                                </div>
                                <div class="bg-white/5 rounded px-2 py-1">
                                    <p class="text-[10px] font-mono text-secondary">{{ item.produto?.codigo_barras || 'S/N' }}</p>
                                </div>
                            </div>
                            
                            <!-- Status Badges -->
                            <div class="flex items-center gap-2 flex-wrap mt-auto pt-2 border-t border-white/5">
                                 <!-- Avarias Status (Combined w/ Item Status if relevant) -->
                                 <div v-if="hasActiveAvaria(item.avarias)" class="flex items-center gap-1 text-amber-500 px-2 py-0.5 rounded bg-amber-500/10 border border-amber-500/20">
                                    <svg class="w-3 h-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                    <span class="text-[10px] font-bold uppercase">{{ item.status_item }} / {{ getActiveAvariaStatus(item) }}</span>
                                 </div>
                                 
                                 <!-- Standard Status Item (Only if NO active avaria) -->
                                 <span v-else class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider border"
                                    :class="item.status_item === 'disponível' ? 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20' : 'bg-white/5 text-secondary border-white/10'"
                                 >{{ item.status_item }}</span>
                            </div>

                            <!-- Actions -->
                            <button 
                                @click="openAvariasModal(item)"
                                class="w-full bg-white/5 hover:bg-white/10 text-secondary hover:text-white border border-white/10 rounded-lg px-3 py-2 text-xs font-bold uppercase tracking-wider transition-colors flex items-center justify-center gap-2"
                            >
                                <svg class="w-3 h-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                Gerenciar Avarias
                            </button>
                        </div>
                    </div>

                    <!-- Pagination (Advanced View) -->
                    <div v-if="estoqueItens.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-8 pt-4 border-t border-white/5">
                        <span class="text-xs md:text-sm text-secondary-500 order-2 md:order-1">
                            <span class="font-medium text-white">{{ (estoquePagination.pagina_atual - 1) * 12 + 1 }}</span> a <span class="font-medium text-white">{{ Math.min(estoquePagination.pagina_atual * 12, estoquePagination.qtd_itens) }}</span> de <span class="font-medium text-white">{{ estoquePagination.qtd_itens }}</span>
                        </span>
                        <div class="flex gap-2 order-1 md:order-2">
                            <button 
                                @click="fetchEstoqueItens(estoquePagination.pagina_atual - 1)" 
                                :disabled="estoquePagination.pagina_atual === 1"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Anterior
                            </button>
                            <button 
                                @click="fetchEstoqueItens(estoquePagination.pagina_atual + 1)" 
                                :disabled="estoquePagination.pagina_atual >= estoquePagination.qtd_paginas"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Próxima
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Avarias Modal -->
                <AvariasModal
                    :isOpen="showAvariasModal"
                    :estoqueItem="selectedEstoqueItem"
                    @close="showAvariasModal = false"
                    @refresh="fetchEstoqueItens(estoquePagination.pagina_atual)"
                />

            </div>

             <!-- KIT MODAL -->
             <KitFormModal
                :isOpen="showKitModal"
                :initialData="editingKit"
                :isLoading="isLoading"
                @close="showKitModal = false"
                @save="handleSaveKit"
             />

             <!-- Delete Confirmation Modal -->
             <ConfirmationModal
                :isOpen="showDeleteConfirm"
                title="Excluir Item"
                :message="`Tem certeza que deseja excluir '${itemToDelete?.nome}'? Esta ação não pode ser desfeita.`"
                confirmText="Excluir"
                cancelText="Cancelar"
                type="danger"
                :loading="isDeleting"
                @close="showDeleteConfirm = false"
                @confirm="confirmDelete"
             />

            <!-- PRODUCT CREATE MODAL -->
            <!-- PRODUCT CREATE MODAL -->
             <ProductFormModal
                :isOpen="showProductModal"
                :initialData="editingProduct"
                :isLoading="isLoading"
                :categorias="categorias"
                :tipos="tipos"
                :unidades="unidades"
                @close="showProductModal = false"
                @save="handleSaveProduct"
             />

        </div>

    </NuxtLayout>
</template>
