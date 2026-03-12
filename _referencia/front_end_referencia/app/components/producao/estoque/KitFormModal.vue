<script setup lang="ts">
const props = defineProps<{
    isOpen: boolean;
    initialData?: any;
    isLoading?: boolean;
}>();

const emit = defineEmits(['close', 'save']);

const form = ref({
    nome: ''
});

// Watch for opening/editing to set initial state
watch(() => props.isOpen, (newVal) => {
    if (newVal) {
        if (props.initialData) {
            form.value.nome = props.initialData.nome;
        } else {
            form.value.nome = '';
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
        <div class="bg-[#16161E] border border-white/10 rounded-xl w-full max-w-md p-6 relative z-10 shadow-2xl">
            <h3 class="text-lg font-bold text-white mb-6 uppercase tracking-wider">
                {{ initialData ? 'Editar Kit' : 'Novo Kit' }}
            </h3>

            <form @submit.prevent="handleSubmit" class="space-y-4">
                <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-secondary/60 ml-1">Nome do Kit</label>
                        <input 
                        v-model="form.nome"
                        type="text" 
                        required
                        placeholder="Ex: Kit Aula Prática"
                        class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder-secondary/30"
                    />
                </div>

                <div class="flex items-center gap-3 pt-4">
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
                        Salvar
                    </button>
                </div>
            </form>
        </div>
    </div>
</template>
