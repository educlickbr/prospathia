<script setup lang="ts">
import { useToast } from "../../../composables/useToast";

const props = defineProps<{
    isOpen: boolean;
    sala?: any | null; // If null, create mode
}>();

const emit = defineEmits(['close', 'saved']);

const { showToast } = useToast();
const isLoading = ref(false);

const form = ref({
    nome: '',
    cor: '#FFFFFF',
    ordem: 0
});

// Watch for changes in sala prop to populate form for editing
watch(() => props.sala, (newSala) => {
    if (newSala) {
        form.value = {
            nome: newSala.nome,
            cor: newSala.cor,
            ordem: newSala.ordem || 0
        };
    } else {
        // Reset for create
        form.value = {
            nome: '',
            cor: '#FFFFFF',
            ordem: 0
        };
    }
}, { immediate: true });

const handleSubmit = async () => {
    if (!form.value.nome) {
        showToast('Nome da sala é obrigatório', { type: 'info' });
        return;
    }
    
    // Validate Hex Color
    if (!/^#[0-9A-F]{6}$/i.test(form.value.cor)) {
        showToast('Cor inválida. Use formato Hex (ex: #FFFFFF)', { type: 'info' });
        return;
    }

    isLoading.value = true;
    try {
        const payload = {
            ...form.value,
            id: props.sala?.id // ID needed for update
        };

        const listResult = await $fetch('/api/producao/salas/upsert', {
            method: 'POST',
            body: payload
        });
        
        showToast('Sala salva com sucesso!', { type: 'success' });
        emit('saved');
        emit('close');
    } catch (e: any) {
        showToast('Erro ao salvar sala: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
        <div class="bg-[#1A1B26] border border-white/10 rounded-xl w-full max-w-md shadow-2xl">
            <div class="p-6 border-b border-white/5 flex justify-between items-center">
                <h3 class="text-lg font-bold text-white">{{ sala ? 'Editar Sala' : 'Nova Sala' }}</h3>
                <button @click="$emit('close')" class="text-secondary hover:text-white">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>
            
            <div class="p-6 space-y-4">
                <div>
                    <label class="block text-xs font-bold text-secondary uppercase mb-2">Nome</label>
                    <input 
                        v-model="form.nome" 
                        type="text" 
                        class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-primary/50 focus:outline-none"
                        placeholder="Ex: Sala de Reunião"
                    >
                </div>

                <div>
                    <label class="block text-xs font-bold text-secondary uppercase mb-2">Cor (Hex)</label>
                    <div class="flex gap-2">
                        <input 
                            v-model="form.cor" 
                            type="text" 
                            class="flex-1 bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-primary/50 focus:outline-none uppercase"
                            placeholder="#FFFFFF"
                            maxlength="7"
                        >
                        <input 
                            type="color" 
                            v-model="form.cor"
                            class="w-10 h-10 rounded border-0 bg-transparent cursor-pointer"
                        >
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold text-secondary uppercase mb-2">Ordem</label>
                    <input 
                        v-model="form.ordem" 
                        type="number" 
                        class="w-full bg-black/30 border border-white/10 rounded-lg px-4 py-2 text-white focus:border-primary/50 focus:outline-none"
                    >
                </div>
            </div>

            <div class="p-6 border-t border-white/5 flex justify-end gap-3">
                <button @click="$emit('close')" class="px-4 py-2 text-secondary hover:text-white transition-colors text-sm font-bold">Cancelar</button>
                <button 
                    @click="handleSubmit" 
                    :disabled="isLoading"
                    class="bg-primary hover:bg-primary-dark disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg px-6 py-2 text-sm font-bold transition-colors flex items-center gap-2"
                >
                    <svg v-if="isLoading" class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    Salvar
                </button>
            </div>
        </div>
    </div>
</template>
