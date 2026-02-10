<script setup lang="ts">
import BaseSelect from '../../BaseSelect.vue';

const props = defineProps<{
    isOpen: boolean;
    isLoading?: boolean;
    produtos: any[]; 
}>();

const emit = defineEmits(['close', 'save']);
const user = useSupabaseUser();

const form = ref({
    id_produto: '',
    data_retirada: new Date().toISOString().split('T')[0], // Today YYYY-MM-DD
    data_devolucao: '',
    observacoes: ''
});

// Reset form when opening
watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        form.value = {
            id_produto: '',
            data_retirada: new Date().toISOString().split('T')[0],
            data_devolucao: '',
            observacoes: ''
        };
    }
});

const handleSubmit = () => {
    if (!user.value) {
        // Should not happen if protected
        return; 
    }
    
    emit('save', {
        id_usuario: user.value.id,
        id_produto: form.value.id_produto,
        data_retirada: new Date(form.value.data_retirada || new Date()).toISOString(),
        data_devolucao: form.value.data_devolucao ? new Date(form.value.data_devolucao).toISOString() : null,
        observacoes: form.value.observacoes || ''
    });
};
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[200] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-md p-6 relative z-10 shadow-2xl">
            <h3 class="text-lg font-bold text-white mb-6 uppercase tracking-wider">
                Nova Reserva
            </h3>

            <form @submit.prevent="handleSubmit" class="space-y-4">
                
                <!-- Produto -->
                <div class="space-y-2">
                    <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Produto *</label>
                    <BaseSelect 
                        v-model="form.id_produto"
                        :options="produtos.map(p => ({ ...p, label: `${p.nome} (Disp: ${p.total_estoque})`, disabled: p.total_estoque <= 0 }))"
                        labelKey="label"
                        valueKey="id"
                        placeholder="Selecione um produto..."
                    />
                </div>

                <!-- Datas -->
                <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Data Retirada *</label>
                        <input 
                            v-model="form.data_retirada"
                            type="date" 
                            required
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30 accent-primary"
                        />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Data Devolução</label>
                        <input 
                            v-model="form.data_devolucao"
                            type="date" 
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30 accent-primary"
                        />
                    </div>
                </div>

                <!-- Obs -->
                <div class="space-y-2">
                    <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Observações</label>
                    <textarea 
                        v-model="form.observacoes"
                        rows="3"
                        placeholder="Ex: Para gravação externa dia X"
                        class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30 resize-none"
                    ></textarea>
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
                        :disabled="isLoading || !form.id_produto"
                        class="flex-1 px-4 py-3 rounded-lg bg-primary hover:bg-primary/90 text-xs font-bold uppercase tracking-wider text-white transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                    >
                        <span v-if="isLoading" class="animate-spin w-4 h-4 border-2 border-white/20 border-t-white rounded-full"></span>
                        Reservar
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>
