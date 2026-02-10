<script setup lang="ts">
import BaseSelect from '../BaseSelect.vue';
import { useToast } from '../../../composables/useToast';
import { timeToMinutes, minutesToTime, calculateTotalHours } from '../../utils/curso';

const props = defineProps<{
    isOpen: boolean;
    courseId?: string | null;
}>();

const emit = defineEmits(['close', 'save']);
const { showToast } = useToast();

const isLoading = ref(false);

// Form Data
// Form Data
const defaultForm = {
    nome_curso: '',
    area: 'Extensão',
    modalidade: 'Presencial',
    cod_curso: '',
    descricao: '',
    
    // Calculation Fields
    modulos: 1,
    encontros_modulo: 1,
    periodos: 1,
    
    // Times
    carga_horaria_total: '00:00', // HH:MM
    carga_horaria_modulo: '00:00', // HH:MM (Calculated)
    carga_horaria_encontro: '00:00', // HH:MM (Standard)
    
    // Irregularity (DB: padrao_encontros=true means Regular)
    // UI: Toggle "Irregularidade" (true) means padrao_encontros = false
    is_irregular: false, 
    irregular_meetings: [] as string[] // Array of HH:MM
};

const form = ref({ ...defaultForm });

// Dropdown Options
const areas = [
    { label: 'Extensão', value: 'Extensão' },
    { label: 'Regulares', value: 'Regulares' },
    { label: 'Cursos Livres', value: 'Cursos Livres' }
];

const modalidades = [
    { label: 'Presencial', value: 'Presencial' },
    { label: 'Online', value: 'Online' },
    { label: 'Híbrido', value: 'Híbrido' }
];

// --- COMPUTED ---

const totalEncontros = computed(() => {
    return (form.value.modulos || 1) * (form.value.encontros_modulo || 1);
});

// We need to keep 'carga_horaria_total' updated automatically
watchEffect(() => {
    if (form.value.is_irregular) {
        // Sum irregular meetings
        let totalMins = 0;
        form.value.irregular_meetings.forEach(t => totalMins += timeToMinutes(t));
        form.value.carga_horaria_total = minutesToTime(totalMins);
    } else {
        // Standard Math
        const encMins = timeToMinutes(form.value.carga_horaria_encontro);
        const totalMins = encMins * totalEncontros.value;
        form.value.carga_horaria_total = minutesToTime(totalMins);
    }
    
    // Calculate Hours/Module based on Total / Modules
    const totalMin = timeToMinutes(form.value.carga_horaria_total);
    const modulos = form.value.modulos || 1;
    const minPerModule = Math.round(totalMin / modulos);
    form.value.carga_horaria_modulo = minutesToTime(minPerModule);
});

// Sync irregular array size with totalCount when NOT irregular mode (or maybe initialize it?)
// Actually, the requirements say "ele abre um repetidor com Encontro 1... Encontro 2..."
// So the array size should probably match specific logic.
// Let's link the array size to `totalEncontros` for now, so if user says 9 meetings, we show 9 slots.
watch(totalEncontros, (count) => {
    if (form.value.is_irregular) {
        const currentLen = form.value.irregular_meetings.length;
        if (count > currentLen) {
            for (let i = currentLen; i < count; i++) {
                form.value.irregular_meetings.push('00:00');
            }
        } else if (count < currentLen) {
             form.value.irregular_meetings.splice(count);
        }
    }
}, { immediate: true });

// Also watch toggle to init array
// Also watch toggle to init array
watch(() => form.value.is_irregular, (val) => {
    if (val) {
         // Ensure array is populated to match total count
         const count = totalEncontros.value;
         if (form.value.irregular_meetings.length !== count) {
            // Preserve existing values if expanding, or cut if shrinking, or init if empty
            const newArr = [...form.value.irregular_meetings];
            if (count > newArr.length) {
                for (let i = newArr.length; i < count; i++) {
                    newArr.push('00:00');
                }
            } else {
                newArr.splice(count);
            }
            form.value.irregular_meetings = newArr;
         }
         // Fallback if empty and count > 0 (should be covered above but safe guard)
         if (count > 0 && form.value.irregular_meetings.length === 0) {
             form.value.irregular_meetings = Array(count).fill('00:00');
         }
    }
});


// --- LOAD & RESET ---

const resetForm = () => {
    form.value = JSON.parse(JSON.stringify(defaultForm));
    form.value.area = 'Extensão'; // Defaults
    form.value.modalidade = 'Presencial';
};

const loadCourseData = async (id: string) => {
    isLoading.value = true;
    try {
        const data: any = await $fetch(`/api/educacional/curso/${id}`);
        
        // Map fields
        form.value.nome_curso = data.nome;
        form.value.cod_curso = data.codigo;
        form.value.descricao = data.descricao || '';
        form.value.modulos = data.qtd_modulos;
        form.value.encontros_modulo = data.qtd_encontros_modulo;
        form.value.periodos = data.qtd_periodos;
        
        // Map Enums (Normalize back to UI options if needed)
        // Simple heuristic: find option that matches lowercase
        const foundArea = areas.find(a => a.value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "") === data.area);
        if (foundArea) form.value.area = foundArea.value;
        
        const foundMod = modalidades.find(m => m.value.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "") === data.modalidade);
        if (foundMod) form.value.modalidade = foundMod.value;
        
        // Structure
        form.value.is_irregular = !data.padrao_encontros;
        
        if (data.encontros && data.encontros.length > 0) {
            // Populate times
            if (form.value.is_irregular) {
                form.value.irregular_meetings = data.encontros.map((e: any) => minutesToTime(e.tempo_minutos));
            } else {
                form.value.carga_horaria_encontro = minutesToTime(data.encontros[0].tempo_minutos);
                form.value.irregular_meetings = [];
            }
        }
        
    } catch (e: any) {
        console.error('Error loading course:', e);
        showToast('Erro ao carregar dados do curso', { type: 'error' });
        emit('close');
    } finally {
        isLoading.value = false;
    }
};

watch(() => props.isOpen, (val) => {
    if (val) {
        if (props.courseId) {
            loadCourseData(props.courseId);
        } else {
            resetForm();
        }
    }
});


// --- ACTIONS ---

const client = useSupabaseClient();

const save = async () => {
    if (!form.value.nome_curso) {
        showToast('Informe o nome do curso', { type: 'error' });
        return;
    }

    isLoading.value = true;
    try {
        const totalMinutes = timeToMinutes(form.value.carga_horaria_total);
        const encontroMinutes = timeToMinutes(form.value.carga_horaria_encontro);
        
        // Construct time arrays [H, M, TotalM]
        // This is an assumption based on user SQL: `c_carga_horaria_encontro->>2`
        // We will send { 2: minutes } just to be safe if that's what index access means, 
        // OR we send explicit array [0, 0, minutes]. The latter is safer for JSON arrays.
        
        const payload = {
            dados_curso: {
                id: props.courseId || undefined,
                criar_editar: props.courseId ? 'editar' : 'criar',
                nome_curso: form.value.nome_curso,
                area: form.value.area,
                modalidade: form.value.modalidade,
                cod_curso: form.value.cod_curso,
                descricao: form.value.descricao,
                padrao_encontros: !form.value.is_irregular,
                modulos: form.value.modulos,
                encontros_modulo: form.value.encontros_modulo,
                periodos: form.value.periodos,
                // Time structures
                c_carga_horaria_periodo: [0, 0, 0], // Placeholder as logic not defined for period duration specifically, or maybe (Total / Periodos)
                c_carga_horaria_encontro: [0, 0, encontroMinutes],
                c_carga_horaria_modulo: [0, 0, 0], // Placeholder
                carga_horaria_total: [0, 0, totalMinutes]
            },
            encontros_curso: [] as any[]
        };

        // Populate meetings if irregular
        if (form.value.is_irregular) {
            payload.encontros_curso = form.value.irregular_meetings.map((time, idx) => ({
                numero_encontro: idx + 1,
                qtd_periodos: 1, // Default?
                duracao_somente_minutos: timeToMinutes(time),
                observacao: ''
            }));
        }



        // Call BFF instead of direct RPC
        const response = await $fetch('/api/educacional/curso', {
            method: 'POST',
            body: payload
        });
        
        showToast(props.courseId ? 'Curso atualizado com sucesso!' : 'Curso criado com sucesso!', { type: 'success' });
        emit('save');
        emit('close');
        
    } catch (e: any) {
        console.error(e);
        showToast('Erro ao salvar: ' + (e.message || e.details), { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        
        <div class="relative bg-[#1A1B26] border border-white/10 rounded-xl shadow-2xl w-full max-w-4xl overflow-hidden flex flex-col max-h-[90vh]">
            
            <!-- Header -->
            <div class="p-6 border-b border-white/5 flex items-center justify-between bg-[#16161E]">
                <div>
                    <h2 class="text-xl font-bold text-white mb-1">Novo Curso</h2>
                    <p class="text-xs text-secondary">Preencha os dados curriculares</p>
                </div>
                <button @click="emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>
            
            <!-- Body -->
            <div class="p-6 overflow-y-auto flex-1 custom-scrollbar space-y-6">
                
                <!-- Basic Info -->
                <div class="space-y-4">
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-2">Nome do Curso</label>
                        <input 
                            v-model="form.nome_curso"
                            type="text" 
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30 transition-colors"
                            placeholder="Ex: A Dança no Século XXI"
                        />
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-bold text-secondary mb-2">Área</label>
                            <BaseSelect
                                v-model="form.area"
                                :options="areas"
                                labelKey="label"
                                valueKey="value"
                            />
                        </div>
                        <div>
                            <label class="block text-xs font-bold text-secondary mb-2">Modalidade</label>
                            <BaseSelect
                                v-model="form.modalidade"
                                :options="modalidades"
                                labelKey="label"
                                valueKey="value"
                            />
                        </div>
                    </div>

                    <!-- Code and Description split rows -->
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-2">Código do Curso</label>
                        <input 
                            v-model="form.cod_curso"
                            type="text" 
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30 transition-colors"
                            placeholder="Ex: RDSXXI"
                        />
                    </div>

                    <div>
                            <label class="block text-xs font-bold text-secondary mb-2">Descrição / Ementa Resumida</label>
                            <textarea 
                            v-model="form.descricao"
                            rows="3"
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30 transition-colors resize-none"
                            placeholder="Breve descrição..."
                            ></textarea>
                    </div>
                </div>

                <!-- Divider -->
                <div class="h-px bg-white/5"></div>

                <!-- Structure & Time -->
                <div class="space-y-6">
                    <!-- Toggle -->
                    <div class="flex items-center justify-between bg-white/5 p-4 rounded-xl border border-white/5">
                        <div>
                            <h3 class="text-sm font-bold text-white">Encontros com Irregularidade</h3>
                            <p class="text-[10px] text-secondary">Habilite se os encontros tiverem durações diferentes entre si.</p>
                        </div>
                        <!-- Toggle Switch -->
                        <button 
                            @click="form.is_irregular = !form.is_irregular"
                            class="w-12 h-6 rounded-full relative transition-colors duration-300 focus:outline-none"
                            :class="form.is_irregular ? 'bg-primary' : 'bg-gray-600'"
                        >
                            <div 
                                class="w-4 h-4 rounded-full bg-white absolute top-1 transition-all duration-300 shadow-md"
                                :class="form.is_irregular ? 'left-7' : 'left-1'"
                            ></div>
                        </button>
                    </div>

                    <!-- Main Metrics -->
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <!-- Left: Structure -->
                        <div class="space-y-4 p-4 rounded-xl border border-white/5 bg-[#0f0f15]">
                             <h4 class="text-xs font-bold text-white uppercase tracking-wider mb-4 opacity-70">Estrutura</h4>
                             
                             <div class="grid grid-cols-2 gap-3">
                                <div>
                                    <label class="block text-[10px] font-bold text-secondary mb-1">Qtd. Módulos (Semestres)</label>
                                    <input 
                                        v-model.number="form.modulos" 
                                        type="number" min="1"
                                        class="w-full bg-[#1A1B26] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none"
                                    />
                                </div>
                                <div>
                                    <label class="block text-[10px] font-bold text-secondary mb-1">Encontros/Módulo</label>
                                    <input 
                                        v-model.number="form.encontros_modulo" 
                                        type="number" min="1"
                                        class="w-full bg-[#1A1B26] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none"
                                    />
                                </div>
                                <div class="col-span-2">
                                    <label class="block text-[10px] font-bold text-secondary mb-1">Qtd. Períodos (Períodos no Dia)</label>
                                    <input 
                                        v-model.number="form.periodos" 
                                        type="number" min="1"
                                        class="w-full bg-[#1A1B26] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none"
                                    />
                                </div>
                             </div>
                        </div>

                        <!-- Right: Time -->
                        <div class="space-y-4 p-4 rounded-xl border border-white/5 bg-[#0f0f15]">
                             <h4 class="text-xs font-bold text-white uppercase tracking-wider mb-4 opacity-70">Carga Horária</h4>
                             
                             <!-- If standard, show single input. If irregular, show helper text -->
                             <div v-if="!form.is_irregular">
                                <label class="block text-[10px] font-bold text-secondary mb-1">Duração Padrão do Encontro (HH:MM)</label>
                                <input 
                                    v-model="form.carga_horaria_encontro" 
                                    type="time"
                                    class="w-full bg-[#1A1B26] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none"
                                />
                             </div>
                             <div v-else class="p-3 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                                 <p class="text-[10px] text-amber-500 font-medium">Modo Irregular Ativo: Defina a duração de cada encontro individualmente abaixo.</p>
                             </div>


                             <!-- Total (Read only most of the time, or calculated) -->
                             <div>
                                <label class="block text-[10px] font-bold text-secondary mb-1">Carga Horária Total (Calculada)</label>
                                <div class="w-full bg-black/40 border border-white/10 rounded-lg px-3 py-2 text-lg font-mono text-primary font-bold">
                                    {{ form.carga_horaria_total }} <span class="text-xs text-secondary font-normal ml-1">horas</span>
                                </div>
                             </div>

                             <!-- New Calculated Field: Hours per Module -->
                             <div class="pt-2 border-t border-white/5 mt-2">
                                <label class="block text-[10px] font-bold text-secondary mb-1">Carga Horária / Módulo</label>
                                <div class="text-sm font-mono text-white opacity-80">
                                    {{ form.carga_horaria_modulo }} <span class="text-xs text-secondary font-normal ml-1">horas</span>
                                </div>
                             </div>
                        </div>
                    </div>

                    <!-- Irregular Repeater -->
                    <div v-if="form.is_irregular" class="bg-[#0f0f15] border border-white/5 rounded-xl p-4 animate-in fade-in slide-in-from-top-4 duration-300">
                        <h4 class="text-xs font-bold text-white uppercase tracking-wider mb-4 opacity-70 flex items-center justify-between">
                            <span>Detalhamento dos Encontros</span>
                            <span class="text-[10px] bg-white/10 px-2 py-1 rounded text-white">{{ form.irregular_meetings.length }} Encontros Total</span>
                        </h4>
                        
                        <div class="space-y-3 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
                            <div v-for="(time, index) in form.irregular_meetings" :key="index" class="bg-[#1A1B26] p-3 rounded-lg border border-white/5 flex items-center gap-4">
                                <div class="w-24 shrink-0">
                                    <span class="text-xs font-bold text-white uppercase">Encontro {{ index + 1 }}</span>
                                </div>
                                
                                <div class="flex items-center gap-2 flex-1">
                                    <div class="flex-1">
                                        <label class="block text-[10px] text-secondary mb-1">Horas</label>
                                        <input 
                                            :value="time.split(':')[0]"
                                            @input="(e: any) => {
                                                const h = e.target.value.padStart(2, '0');
                                                const m = (form.irregular_meetings[index] || '00:00').split(':')[1] || '00';
                                                form.irregular_meetings[index] = `${h}:${m}`;
                                            }"
                                            type="number" min="0" max="23"
                                            class="w-full bg-black/30 border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30"
                                            placeholder="HH"
                                        />
                                    </div>
                                    <span class="text-white font-bold mt-4">:</span>
                                    <div class="flex-1">
                                        <label class="block text-[10px] text-secondary mb-1">Minutos</label>
                                        <input 
                                             :value="time.split(':')[1]"
                                             @input="(e: any) => {
                                                const m = e.target.value.padStart(2, '0');
                                                const h = (form.irregular_meetings[index] || '00:00').split(':')[0] || '00';
                                                form.irregular_meetings[index] = `${h}:${m}`;
                                             }"
                                            type="number" min="0" max="59"
                                            class="w-full bg-black/30 border border-white/10 rounded px-3 py-2 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30"
                                            placeholder="MM"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Calculated Read-Only Stats -->
                    <div class="grid grid-cols-2 gap-4 pt-4 border-t border-white/5">
                        <div>
                             <p class="text-[10px] font-bold text-secondary uppercase">Total de Encontros</p>
                             <p class="text-sm font-mono text-white">{{ totalEncontros }}</p>
                        </div>
                        <div>
                             <p class="text-[10px] font-bold text-secondary uppercase">CH Média por Encontro</p>
                             <p class="text-sm font-mono text-white">
                                {{ form.is_irregular ? 'Variável' : form.carga_horaria_encontro }}
                             </p>
                        </div>
                    </div>

                </div>
            </div>

            <!-- Footer -->
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
                    class="bg-primary hover:bg-primary-dark text-white rounded-lg px-6 py-2 text-sm font-bold flex items-center gap-2 transition-all disabled:opacity-50"
                >
                    <svg v-if="isLoading" class="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    {{ courseId ? 'Salvar' : 'Criar Curso' }}
                </button>
            </div>

        </div>
    </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: #0f0f15; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 3px; }
</style>
