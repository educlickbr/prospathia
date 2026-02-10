<script setup lang="ts">
import BaseSelect from '../../BaseSelect.vue';

const props = defineProps<{
    isOpen: boolean;
    estoqueItem: any;
    isLoading?: boolean;
}>();

const emit = defineEmits(['close', 'refresh']);
const supabase = useSupabaseClient();
const user = useSupabaseUser();
const estoqueStore = useEstoqueStore();

const avarias = ref<any[]>([]);
const newAvariaMode = ref(false);
const loadingAvarias = ref(false);
const expandedAvariaId = ref<string | null>(null);
const editingForm = ref({
    descricao: '',
    observacoes: '',
    status: '',
    tipo_avaria: ''
});

const form = ref({
    descricao: '',
    observacoes: '',
    status: 'Pendente', // Default status
    tipo_avaria: '',
});

const tipoAvariaOptions = ref<any[]>([]);

const statusOptions = ['Pendente', 'Em Reparo', 'Reparado', 'Não se Aplica', 'Descartado'];

const fetchTiposAvaria = async () => {
    const { data } = await supabase.from('produto_tipo_avaria' as any).select('*');
    if (data) {
        tipoAvariaOptions.value = data;
    }
};

// Fetch latest avarias when modal opens or item changes
const fetchAvarias = async () => {
    if (!props.estoqueItem?.id) return;
    
    loadingAvarias.value = true;
    const { data, error } = await supabase
        .from('produto_avarias')
        .select('*')
        .eq('id_produto_estoque', props.estoqueItem.id)
        .order('data_entrada_avaria', { ascending: false });
        
    if (data) avarias.value = data;
    loadingAvarias.value = false;
};

watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        newAvariaMode.value = false;
        expandedAvariaId.value = null;
        fetchAvarias();
        fetchTiposAvaria();
        form.value = { descricao: '', observacoes: '', status: 'Pendente', tipo_avaria: '' };
    }
});

const handleSaveAvaria = async () => {
    if (!form.value.descricao) return;
    
    loadingAvarias.value = true;
    
    try {
        await estoqueStore.criarAvaria({
            descricao: form.value.descricao,
            observacoes: form.value.observacoes,
            status_reparo: form.value.status,
            id_produto_estoque: props.estoqueItem.id,
            id_produto: props.estoqueItem.produto.id,
            tipo_avaria: form.value.tipo_avaria || undefined
        });

        newAvariaMode.value = false;
        await fetchAvarias();
        emit('refresh'); // Tell parent to refresh list (to update status indicator)
        
    } catch (e: any) {
         // Error handled in store but we can show alert here if needed or toast
         alert(e.data?.message || e.message);
    }
    
    loadingAvarias.value = false;
};

const hasBlockingAvaria = computed(() => {
    return avarias.value.some((a: any) => ['Pendente', 'Em Reparo', 'Descartado'].includes(a.status_reparo));
});

const updateStatus = async (avariaId: string, newStatus: string) => {
    const { error } = await (supabase.from('produto_avarias') as any)
        .update({ status_reparo: newStatus })
        .eq('id', avariaId);
        
    if (!error) {
        await fetchAvarias();
        emit('refresh');
    }
};

const toggleExpand = (avaria: any) => {
    if (expandedAvariaId.value === avaria.id) {
        expandedAvariaId.value = null;
    } else {
        expandedAvariaId.value = avaria.id;
        editingForm.value = {
            descricao: avaria.descricao,
            observacoes: avaria.observacoes || '',
            status: avaria.status_reparo,
            tipo_avaria: avaria.tipo_avaria
        };
    }
};

const handleUpdateAvaria = async (id: string) => {
    if (!editingForm.value.descricao) return;

    loadingAvarias.value = true;
    try {
        await estoqueStore.atualizarAvaria({
            id: id,
            descricao: editingForm.value.descricao,
            observacoes: editingForm.value.observacoes,
            status_reparo: editingForm.value.status,
            tipo_avaria: editingForm.value.tipo_avaria
        });

        expandedAvariaId.value = null;
        await fetchAvarias();
        emit('refresh');
    } catch (e: any) {
        alert(e.data?.message || e.message);
    }
    loadingAvarias.value = false;
};

const getStatusColor = (status: string) => {
    switch (status) {
        case 'Pendente': return 'text-amber-500 bg-amber-500/10 border-amber-500/20';
        case 'Em Reparo': return 'text-blue-500 bg-blue-500/10 border-blue-500/20';
        case 'Reparado': return 'text-emerald-500 bg-emerald-500/10 border-emerald-500/20';
        case 'Não se Aplica': return 'text-secondary bg-white/5 border-white/10';
        case 'Descartado': return 'text-danger bg-danger/10 border-danger/20';
        default: return 'text-secondary bg-white/5 border-white/10';
    }
};
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[200] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-2xl p-6 relative z-10 shadow-2xl max-h-[90vh] overflow-y-auto flex flex-col">
            
            <!-- Header -->
            <div class="flex items-center justify-between mb-6">
                <div>
                     <h3 class="text-lg font-bold text-white uppercase tracking-wider">
                        Gerenciar Avarias
                    </h3>
                    <p class="text-xs text-secondary mt-1">Item: {{ estoqueItem?.produto?.nome }} (ID: {{ estoqueItem?.id.split('-')[0] }})</p>
                </div>
                <button 
                    v-if="!newAvariaMode && !hasBlockingAvaria"
                    @click="newAvariaMode = true"
                    class="bg-danger/10 hover:bg-danger/20 text-danger border border-danger/20 text-xs font-bold uppercase tracking-wider px-4 py-2 rounded-lg transition-colors flex items-center gap-2"
                >
                    <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                    Nova Avaria
                </button>
                <div v-else-if="hasBlockingAvaria" class="text-xs text-secondary/60 italic border border-white/5 bg-white/5 px-3 py-1.5 rounded">
                     Avaria Ativa. Resolva para criar nova.
                </div>
            </div>

            <!-- New Avaria Form -->
            <div v-if="newAvariaMode" class="bg-black/20 border border-white/5 rounded-xl p-4 mb-6">
                <h4 class="text-sm font-bold text-white mb-4">Registrar Nova Avaria</h4>
                <form @submit.prevent="handleSaveAvaria" class="space-y-4">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Descrição do Problema *</label>
                        <input v-model="form.descricao" type="text" required class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30" placeholder="Ex: Tela riscada, Botão emperrado..." />
                    </div>
                     <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Tipo de Avaria</label>
                        <BaseSelect 
                            v-model="form.tipo_avaria" 
                            :options="tipoAvariaOptions" 
                            label-key="avaria"
                            value-key="id"
                            placeholder="Selecione o tipo..." 
                        />
                    </div>
                     <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Observações</label>
                        <textarea v-model="form.observacoes" rows="2" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30 resize-none"></textarea>
                    </div>
                     <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Status Inicial</label>
                        <BaseSelect 
                            v-model="form.status" 
                            :options="statusOptions" 
                            placeholder="Selecione..." 
                        />
                    </div>
                    <div class="flex justify-end gap-2 pt-2">
                        <button type="button" @click="newAvariaMode = false" class="text-xs font-bold text-secondary hover:text-white px-3 py-2">Cancelar</button>
                        <button type="submit" class="bg-primary hover:bg-primary/90 text-white text-xs font-bold uppercase px-4 py-2 rounded-lg">Salvar</button>
                    </div>
                </form>
            </div>

            <!-- List -->
            <div class="flex-1 overflow-y-auto">
                 <div v-if="loadingAvarias" class="py-10 flex justify-center">
                     <svg class="animate-spin h-6 w-6 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                 </div>
                 <div v-else-if="avarias.length === 0" class="text-center py-10 text-secondary/50 text-sm">
                     Nenhuma avaria registrada para este item.
                 </div>
                 <div v-else class="space-y-3">
                     <div v-for="avaria in avarias" :key="avaria.id" class="bg-white/5 rounded-lg border border-white/5 overflow-hidden transition-all duration-300">
                         
                         <!-- Header / Collapsed View -->
                         <div 
                            @click="toggleExpand(avaria)"
                            class="p-4 flex items-center justify-between cursor-pointer hover:bg-white/5 transition-colors"
                         >
                             <div class="flex-1">
                                 <div class="flex items-center gap-3 mb-1">
                                     <h5 class="font-bold text-white text-sm">{{ avaria.descricao }}</h5>
                                     <span 
                                        class="px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider border"
                                        :class="getStatusColor(avaria.status_reparo)"
                                     >
                                         {{ avaria.status_reparo }}
                                     </span>
                                 </div>
                                 <div class="flex items-center gap-2 text-[10px] text-secondary">
                                      <span>{{ new Date(avaria.data_entrada_avaria).toLocaleDateString() }}</span>
                                      <span v-if="avaria.tipo_avaria" class="text-secondary/50">• ID Tipo: {{ avaria.tipo_avaria }}</span>
                                 </div>
                             </div>
                             
                             <!-- Expand Icon -->
                             <div class="text-secondary transition-transform duration-300" :class="{ 'rotate-180': expandedAvariaId === avaria.id }">
                                 <svg class="w-5 h-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                             </div>
                         </div>

                         <!-- Expanded Content / Edit Form -->
                         <div v-if="expandedAvariaId === avaria.id" class="px-4 pb-4 pt-0 border-t border-white/5 bg-black/20" @click.stop>
                             <div class="pt-4 space-y-4">
                                 
                                 <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                     <!-- Description -->
                                     <div class="space-y-2">
                                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Descrição *</label>
                                        <input v-model="editingForm.descricao" type="text" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30" />
                                     </div>

                                     <!-- Status -->
                                     <div class="space-y-2">
                                         <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60">Status</label>
                                         <BaseSelect 
                                            v-model="editingForm.status" 
                                            :options="statusOptions"
                                         />
                                     </div>
                                 </div>

                                 <!-- Type -->
                                  <div class="space-y-2">
                                     <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Tipo de Avaria</label>
                                     <BaseSelect 
                                         v-model="editingForm.tipo_avaria" 
                                         :options="tipoAvariaOptions" 
                                         label-key="avaria"
                                         value-key="id"
                                         placeholder="Selecione o tipo..." 
                                     />
                                 </div>

                                 <!-- Observations -->
                                 <div class="space-y-2">
                                     <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60">Observações</label>
                                     <textarea v-model="editingForm.observacoes" rows="2" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30 resize-none"></textarea>
                                 </div>

                                 <!-- Actions -->
                                 <div class="flex justify-end gap-2 pt-2">
                                    <button @click="expandedAvariaId = null" class="text-xs font-bold text-secondary hover:text-white px-3 py-2">Cancelar</button>
                                    <button @click="handleUpdateAvaria(avaria.id)" class="bg-primary hover:bg-primary/90 text-white text-xs font-bold uppercase px-4 py-2 rounded-lg">Salvar Alterações</button>
                                 </div>
                             </div>
                         </div>
                     </div>
                 </div>
            </div>

            <div class="pt-6 mt-4 border-t border-white/10 flex justify-end">
                <button 
                    @click="emit('close')"
                    class="px-6 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-xs font-bold uppercase tracking-wider text-white transition-colors"
                >
                    Fechar
                </button>
            </div>

        </div>
    </div>
</template>
