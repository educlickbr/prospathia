<script setup lang="ts">
import BaseSelect from '../../BaseSelect.vue';

const props = defineProps<{
    isOpen: boolean;
    initialData?: any;
    isLoading?: boolean;
    categorias: any[];
    tipos: any[];
    unidades: any[];
}>();

const emit = defineEmits(['close', 'save']);

const form = ref({
    nome: '',
    id_categoria: '',
    id_tipo: '',
    id_unidade: '',
    treshold: 5,
    quantidade_inicial: 0,
    valor_inicial: 0,
    codigo_barras: '',
    observacoes: ''
});

watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        if (props.initialData) {
            form.value = {
                nome: props.initialData.nome,
                id_categoria: props.initialData.categoria?.id || props.initialData.id_categoria_produto,
                id_tipo: props.initialData.tipo?.id || props.initialData.id_tipo_produto,
                id_unidade: props.initialData.unidade?.id || props.initialData.id_unidade,
                treshold: props.initialData.treshold,
                quantidade_inicial: 0, // Don't edit qty here
                valor_inicial: props.initialData.valor_inicial,
                codigo_barras: props.initialData.codigo_barras,
                observacoes: props.initialData.observacoes
            };
        } else {
            form.value = {
                nome: '',
                id_categoria: '',
                id_tipo: '',
                id_unidade: '',
                treshold: 5,
                quantidade_inicial: 0,
                valor_inicial: 0,
                codigo_barras: '',
                observacoes: ''
            };
        }
    }
});

const handleSubmit = () => {
    emit('save', { ...form.value });
};
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[200] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-2xl p-6 relative z-10 shadow-2xl max-h-[90vh] overflow-y-auto">
            <h3 class="text-lg font-bold text-white mb-6 uppercase tracking-wider">
                {{ initialData ? 'Editar Produto' : 'Novo Produto' }}
            </h3>

            <form @submit.prevent="handleSubmit" class="space-y-5">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <!-- Nome -->
                    <div class="col-span-2 space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Nome do Produto *</label>
                        <input v-model="form.nome" type="text" required placeholder="Ex: Câmera Canon 5D Mark IV" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30" />
                    </div>

                    <!-- Categoria -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Categoria *</label>
                        <BaseSelect 
                            v-model="form.id_categoria"
                            :options="categorias"
                            labelKey="nome"
                            valueKey="id"
                            placeholder="Selecione a categoria"
                        />
                    </div>

                    <!-- Tipo -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Tipo</label>
                        <BaseSelect 
                            v-model="form.id_tipo"
                            :options="tipos"
                            labelKey="nome"
                            valueKey="id"
                            placeholder="Selecione o tipo"
                        />
                    </div>

                        <!-- Unidade -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Unidade *</label>
                        <BaseSelect 
                            v-model="form.id_unidade"
                            :options="unidades.map(u => ({ ...u, label: `${u.nome} (${u.sufixo})` }))"
                            labelKey="label"
                            valueKey="id"
                            placeholder="Selecione a unidade"
                        />
                    </div>
                    
                    <!-- Treshold (Minimo) -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Estoque Mínimo</label>
                        <input v-model.number="form.treshold" type="number" min="0" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none" />
                    </div>

                        <!-- Quantidade Inicial -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-success ml-1">Qtd. Inicial (Estoque)</label>
                        <input v-model.number="form.quantidade_inicial" type="number" min="0" :disabled="!!initialData" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed" title="Para adicionar estoque a um produto existente, use a ação rápida no card." />
                    </div>

                    <!-- Valor Inicial -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Valor Unitário (Inicial)</label>
                        <input v-model.number="form.valor_inicial" type="number" step="0.01" min="0" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none" />
                    </div>
                    
                    <!-- Codigo Barras -->
                    <div class="col-span-2 space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Código de Barras / Patrimônio</label>
                        <input v-model="form.codigo_barras" type="text" placeholder="Opcional" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30" />
                    </div>

                    <!-- Obs -->
                    <div class="col-span-2 space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Observações</label>
                        <textarea v-model="form.observacoes" rows="3" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30 resize-none"></textarea>
                    </div>
                </div>

                <div class="flex items-center gap-3 pt-4 border-t border-white/5 mt-4">
                    <button 
                        type="button" 
                        @click="emit('close')"
                        class="flex-1 px-4 py-3 rounded-lg border border-white/10 text-xs font-bold uppercase tracking-wider text-secondary hover:bg-white/5 transition-colors"
                    >
                        Cancelar
                    </button>
                    <button 
                        type="submit" 
                        :disabled="isLoading"
                        class="flex-1 px-4 py-3 rounded-lg bg-primary hover:bg-primary/90 text-xs font-bold uppercase tracking-wider text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                    >
                        <span v-if="isLoading" class="animate-spin w-4 h-4 border-2 border-white/20 border-t-white rounded-full"></span>
                        {{ initialData ? 'Salvar' : 'Criar Produto' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>
