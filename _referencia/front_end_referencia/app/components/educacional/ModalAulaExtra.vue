<script setup lang="ts">
import { useToast } from '../../../composables/useToast';

const props = defineProps<{
    isOpen: boolean;
    turmaId: string;
    date: string | null; // ISO Date String (YYYY-MM-DD or full ISO)
}>();

const emit = defineEmits(['close', 'save']);
const { showToast } = useToast();

const isLoading = ref(false);

const form = ref({
    hora_ini: '08:00',
    hora_fim: '10:00',
    observacoes: ''
});

// Reset form on open
watch(() => props.isOpen, (val) => {
    if (val) {
        form.value = {
            hora_ini: '08:00',
            hora_fim: '10:00',
            observacoes: ''
        };
    }
});

const formattedDate = computed(() => {
    if (!props.date) return '';
    // Format YYYY-MM-DD to DD/MM/YYYY for display
    return new Date(props.date).toLocaleDateString('pt-BR', { timeZone: 'UTC' }); 
    // Note: FullCalendar dates often come as YYYY-MM-DD. Using UTC prevents shift if just a date string.
});

const save = async () => {
    if (!props.turmaId || !props.date) return;
    
    isLoading.value = true;
    try {
        const payload = {
            id_turma: props.turmaId,
            data: props.date, // API expects YYYY-MM-DD
            hora_ini: form.value.hora_ini,
            hora_fim: form.value.hora_fim,
            observacoes: form.value.observacoes
        };

        const response: any = await $fetch('/api/educacional/calendario/evento', {
            method: 'POST' as any,
            body: payload
        });

        if (response && response.success) {
            showToast('Aula extra adicionada!', { type: 'success' });
            emit('save');
            emit('close');
        } else {
             showToast('Erro ao adicionar aula: ' + (response.message || 'Erro desconhecido'), { type: 'error' });
        }

    } catch (e: any) {
        console.error(e);
        showToast('Erro: ' + (e.message || 'Falha na requisição'), { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        
        <div class="relative bg-[#1A1B26] border border-white/10 rounded-xl shadow-2xl w-full max-w-md overflow-hidden">
            
            <div class="p-6 border-b border-white/5 bg-[#16161E]">
                <h2 class="text-lg font-bold text-white mb-1">Adicionar Aula Extra</h2>
                <p class="text-sm text-secondary">Para o dia <span class="text-white font-mono">{{ formattedDate }}</span></p>
            </div>
            
            <div class="p-6 space-y-4">
                 <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-1.5 uppercase">Início</label>
                        <input v-model="form.hora_ini" type="time" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                    </div>
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-1.5 uppercase">Fim</label>
                        <input v-model="form.hora_fim" type="time" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                    </div>
                </div>
                
                <div>
                     <label class="block text-xs font-bold text-secondary mb-1.5 uppercase">Observações (Opcional)</label>
                     <input v-model="form.observacoes" type="text" placeholder="Ex: Reposição, Ensaio Geral..." class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder:text-secondary/30 focus:border-primary focus:outline-none" />
                </div>
            </div>

             <div class="p-6 border-t border-white/5 bg-[#16161E] flex justify-end gap-3">
                <button 
                    @click="emit('close')"
                    class="px-4 py-2 text-sm font-bold text-secondary hover:text-white transition-colors"
                >
                    Cancelar
                </button>
                <button 
                    @click="save"
                    :disabled="isLoading"
                    class="bg-primary hover:bg-primary-dark text-white rounded-lg px-4 py-2 text-sm font-bold flex items-center gap-2 transition-all disabled:opacity-50"
                >
                    <svg v-if="isLoading" class="animate-spin h-3 w-3 text-white" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    Adicionar
                </button>
            </div>

        </div>
    </div>
</template>
