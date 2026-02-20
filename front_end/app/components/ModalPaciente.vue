<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { useAppStore } from '../../stores/app';

const props = defineProps({
  isOpen: {
    type: Boolean,
    required: true
  },
  patient: {
    type: Object as PropType<any>, // using any to bypass strict type check for now, or define interface
    default: null 
  }
});

import { type PropType } from 'vue';

const emit = defineEmits(['close', 'save']);
const store = useAppStore();

// Form State
const form = ref({
    nome_completo: '',
    email: '',
    telefone: '',
    sexo: 'masculino',
    data_nascimento: ''
});

const loading = ref(false);
const error = ref<string | null>(null);

// Watch for patient prop changes to populate form (Edit Mode)
watch(() => props.patient, (newVal) => {
    if (newVal) {
        form.value = {
            nome_completo: newVal.nome_completo,
            email: newVal.email || '',
            telefone: newVal.telefone || '',
            sexo: newVal.sexo || 'masculino',
            data_nascimento: newVal.data_nascimento || ''
        };
    } else {
        // Reset for Create Mode
        form.value = {
            nome_completo: '',
            email: '',
            telefone: '',
            sexo: 'masculino',
            data_nascimento: ''
        };
    }
}, { immediate: true });

const title = computed(() => props.patient ? 'Editar Paciente' : 'Novo Paciente');
const buttonText = computed(() => props.patient ? 'Salvar Alterações' : 'Criar Paciente');

const handleSave = async () => {
    if (!form.value.nome_completo) {
        error.value = 'Nome completo é obrigatório.';
        return;
    }

    loading.value = true;
    error.value = null;

    try {
        await $fetch('/api/pacientes/otolithics/upsert', {
            method: 'POST',
            body: {
                id: props.patient?.id,
                id_clinica: store.company?.id, // Get clinica from store
                ...form.value
            }
        });
        emit('save');
        emit('close');
    } catch (e: any) {
        error.value = e.statusMessage || 'Erro ao salvar paciente.';
    } finally {
        loading.value = false;
    }
};
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>

        <!-- Modal Content -->
        <div class="relative bg-div-15 border border-white/10 rounded-xl w-full max-w-lg shadow-2xl p-6 space-y-6">
            
             <h2 class="text-xl font-bold text-white">{{ title }}</h2>

            <div class="space-y-4">
                <!-- Nome -->
                <div>
                     <label class="block text-xs font-bold uppercase text-secondary mb-1">Nome Completo *</label>
                     <input 
                        v-model="form.nome_completo"
                        type="text" 
                        class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary/50"
                        placeholder="Ex: João Silva"
                     />
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <!-- Email -->
                    <div>
                         <label class="block text-xs font-bold uppercase text-secondary mb-1">Email</label>
                         <input 
                            v-model="form.email"
                            type="email" 
                            class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary/50"
                            placeholder="email@exemplo.com"
                         />
                    </div>
                    <!-- Telefone -->
                     <div>
                         <label class="block text-xs font-bold uppercase text-secondary mb-1">Telefone</label>
                         <input 
                            v-model="form.telefone"
                            type="tel" 
                            class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary/50"
                            placeholder="(11) 99999-9999"
                         />
                    </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <!-- Data Nascimento -->
                    <div>
                         <label class="block text-xs font-bold uppercase text-secondary mb-1">Data de Nascimento</label>
                         <input 
                            v-model="form.data_nascimento"
                            type="date" 
                            class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary/50"
                         />
                    </div>
                    <!-- Sexo -->
                     <div>
                         <label class="block text-xs font-bold uppercase text-secondary mb-1">Sexo</label>
                         <select 
                            v-model="form.sexo"
                            class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary/50 appearance-none"
                         >
                            <option value="masculino">Masculino</option>
                            <option value="feminino">Feminino</option>
                         </select>
                    </div>
                </div>
            </div>

            <!-- Error -->
            <div v-if="error" class="text-red-400 text-sm bg-red-900/20 border border-red-500/20 p-2 rounded">
                {{ error }}
            </div>

            <!-- Actions -->
            <div class="flex justify-end gap-3 pt-4 border-t border-white/5">
                <button 
                    @click="emit('close')"
                    class="px-4 py-2 rounded-lg text-secondary hover:text-white transition-colors text-sm font-bold uppercase tracking-wider"
                >
                    Cancelar
                </button>
                <button 
                    @click="handleSave"
                    :disabled="loading"
                    class="px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors text-sm font-bold uppercase tracking-wider disabled:opacity-50 flex items-center gap-2"
                >
                    <span v-if="loading" class="w-4 h-4 border-2 border-white/20 border-t-white rounded-full animate-spin"></span>
                    {{ buttonText }}
                </button>
            </div>

        </div>
    </div>
</template>
