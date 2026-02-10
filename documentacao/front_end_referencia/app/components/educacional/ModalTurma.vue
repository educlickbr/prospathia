<script setup lang="ts">
import BaseSelect from '../BaseSelect.vue';
import { useToast } from '../../../composables/useToast';

const props = defineProps<{
    isOpen: boolean;
    turmaId?: string | null;
}>();

const emit = defineEmits(['close', 'save']);
const { showToast } = useToast();

const isLoading = ref(false);
const isSaving = ref(false);

// Options
const cursos = ref<any[]>([]);
const semestres = ['25Is', '25IIs', '26Is', '26IIs', '27Is', '27IIs'];
const turnos = ['Matutino', 'Vespertino', 'Noturno'];
const areaOptions = [
    { label: 'Todas as Áreas', value: null },
    { label: 'Extensão', value: 'Extensão' },
    { label: 'Regulares', value: 'Regulares' },
    { label: 'Cursos Livres', value: 'Cursos Livres' }
];

const selectedArea = ref<string | null>(null);

// Form
const defaultForm = {
    // Info
    id_curso: '',
    ano_semestre: '26Is',
    turno: 'Matutino',
    link_video: false,

    // Dates
    dt_ini_curso: '',
    dt_fim_curso: '',
    dt_ini_inscri: '',
    dt_fim_inscri: '',
    dt_ini_mat: '',
    dt_fim_mat: '',
    dt_ini_inscri_docente: '',
    dt_fim_inscri_docente: '',

    // Time & Schedule
    hora_ini: '08:00',
    hora_fim: '12:00',
    dias_semana: [] as string[]
};

const form = ref({ ...defaultForm });

// Computed
const filteredCursos = computed(() => {
    if (!selectedArea.value) return cursos.value;
    return cursos.value.filter(c => c.area === selectedArea.value);
});

const selectedCurso = computed(() => {
    return cursos.value.find(c => c.id === form.value.id_curso);
});

const previewCodCurso = computed(() => selectedCurso.value?.cod_curso || 'XXX');
const previewCodTurma = computed(() => {
    if (!selectedCurso.value) return '...';
    const turnoInitial = form.value.turno ? form.value.turno[0] : 'X';
    return `${selectedCurso.value.cod_curso}-${form.value.ano_semestre}${turnoInitial}`;
});
const previewCodModulo = computed(() => {
    if (!selectedCurso.value) return '...';
    const turnoInitial = form.value.turno ? form.value.turno[0] : 'X';
    return `${form.value.ano_semestre}${turnoInitial}-${selectedCurso.value.cod_curso}`;
});

// Load Courses
const fetchCourses = async () => {
    try {
        const data: any = await $fetch('/api/educacional/cursos', {
            params: { 
                limite: 100,
                // We fetch all (up to 100) and filter client-side for smoother UX in dropdown
            } 
        });
        if (data && data.itens) {
            cursos.value = data.itens.map((c: any) => ({
                id: c.id,
                nome: c.nome_curso,
                cod_curso: c.cod_curso,
                area: c.area
            }));
        }
    } catch (e) {
        console.error('Error loading courses', e);
    }
};

// Actions
const resetForm = () => {
    form.value = JSON.parse(JSON.stringify(defaultForm));
    form.value.ano_semestre = '26Is'; // Default
    form.value.turno = 'Matutino';
   
    // Set some sensible default dates (e.g. current year logic?)
    // For now keep empty or hardcode sample
    const today = new Date().toISOString().substring(0, 10);
    form.value.dt_ini_inscri = today;
    form.value.dt_fim_inscri = today;
    form.value.dt_ini_mat = today;
    form.value.dt_fim_mat = today;
    form.value.dt_ini_inscri_docente = today;
    form.value.dt_fim_inscri_docente = today;
    form.value.dt_ini_curso = today;
    form.value.dt_fim_curso = today;
};

const save = async () => {
    if (!form.value.id_curso) {
        showToast('Selecione um curso', { type: 'error' });
        return;
    }
    if (form.value.dias_semana.length === 0) {
        showToast('Selecione ao menos um dia da semana', { type: 'error' });
        return;
    }

    isSaving.value = true;
    try {
        const payload = {
            dados_turma: {
                id: props.turmaId || undefined,
                id_curso: form.value.id_curso,
                ano_semestre: form.value.ano_semestre,
                turno: form.value.turno,
                link_video: form.value.link_video,
                
                // Dates
                dt_ini_curso: form.value.dt_ini_curso,
                dt_fim_curso: form.value.dt_fim_curso,
                dt_ini_inscri: form.value.dt_ini_inscri,
                dt_fim_inscri: form.value.dt_fim_inscri,
                dt_ini_mat: form.value.dt_ini_mat,
                dt_fim_mat: form.value.dt_fim_mat,
                dt_ini_inscri_docente: form.value.dt_ini_inscri_docente,
                dt_fim_inscri_docente: form.value.dt_fim_inscri_docente,

                // Schedule
                hora_ini: form.value.hora_ini,
                hora_fim: form.value.hora_fim,
                dias_semana: form.value.dias_semana
            }
        };

        const response: any = await $fetch('/api/educacional/turma', {
            method: 'POST',
            body: payload
        });

        if (response && response.success) {
            showToast(props.turmaId ? 'Turma atualizada!' : 'Turma criada: ' + response.log_calendario, { type: 'success' });
            emit('save');
            emit('close');
        } else {
             showToast('Erro ao salvar turma', { type: 'error' });
        }


    } catch (e: any) {
        console.error(e);
        showToast('Erro: ' + (e.message || 'Falha ao salvar'), { type: 'error' });
    } finally {
        isSaving.value = false;
    }
};

// Watchers
watch(() => props.isOpen, async (val) => {
    if (val) {
        if (cursos.value.length === 0) await fetchCourses();
        resetForm();
        selectedArea.value = null; // Reset Area filter
        if (props.turmaId) {
            // TODO: Load existing turma logic (for edit)
            // For now assume creation mode or implement load later
            console.log("Edit mode not fully implemented yet in Modal load");
        }
    }
});

// Days Helper
const daysOfWeek = [
    { label: 'Segunda-Feira', value: 'SEG' },
    { label: 'Terça-Feira', value: 'TER' },
    { label: 'Quarta-Feira', value: 'QUA' },
    { label: 'Quinta-Feira', value: 'QUI' },
    { label: 'Sexta-Feira', value: 'SEX' },
    { label: 'Sábado', value: 'SAB' },
    { label: 'Domingo', value: 'DOM' }
];

const toggleDay = (day: string) => {
    const idx = form.value.dias_semana.indexOf(day);
    if (idx >= 0) {
        form.value.dias_semana.splice(idx, 1);
    } else {
        form.value.dias_semana.push(day);
    }
};

</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        
        <div class="relative bg-[#1A1B26] border border-white/10 rounded-xl shadow-2xl w-full max-w-4xl max-h-[90vh] flex flex-col overflow-hidden">
            
            <!-- Header -->
            <div class="p-6 border-b border-white/5 flex items-center justify-between bg-[#16161E]">
                <div>
                    <h2 class="text-xl font-bold text-white mb-1">{{ turmaId ? 'Editar Turma' : 'Criar Turma' }}</h2>
                    <p class="text-xs text-secondary">Defina as datas e horários para gerar o calendário.</p>
                </div>
                <button @click="emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>
            
            <!-- Body -->
            <div class="p-6 overflow-y-auto flex-1 custom-scrollbar space-y-6">
                
                <!-- 1. Curso & Info -->
                <div class="space-y-4">
                     <!-- AREA is read-only based on course usually, or maybe filter? User UI shows Area dropdown.
                          If user selects Area first, we filter courses?
                          For simplicity, let's just show Course Select first since Area is derived in our logic usually. 
                          But user UI has Area. Let's just put Course Select and auto-fill Area display. -->
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                         <!-- Area Filter -->
                         <div class="md:col-span-2">
                             <label class="block text-xs font-bold text-secondary mb-2">Área</label>
                             <BaseSelect 
                                 v-model="selectedArea" 
                                 :options="areaOptions"
                                 label-key="label"
                                 value-key="value"
                                 placeholder="Todas as Áreas"
                             />
                        </div>

                        <!-- Course Select -->
                        <div class="md:col-span-2">
                             <label class="block text-xs font-bold text-secondary mb-2">Nome do Curso</label>
                             <BaseSelect
                                v-model="form.id_curso"
                                :options="filteredCursos"
                                labelKey="nome"
                                valueKey="id"
                                placeholder="Selecione um curso"
                                :disabled="!cursos.length"
                             />
                        </div>

                        <!-- Semestre & Turno -->
                        <div>
                             <label class="block text-xs font-bold text-secondary mb-2">Ano/Semestre</label>
                             <BaseSelect
                                v-model="form.ano_semestre"
                                :options="semestres"
                             />
                        </div>
                        <div>
                             <label class="block text-xs font-bold text-secondary mb-2">Turno</label>
                             <BaseSelect
                                v-model="form.turno"
                                :options="turnos"
                             />
                        </div>
                    </div>

                    <!-- Auto Codes (Read Only) -->
                     <div class="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
                         <div>
                            <label class="block text-[10px] font-bold text-secondary mb-1">Código do Curso</label>
                            <input type="text" :value="previewCodCurso" readonly class="w-full bg-[#0f0f15] border border-white/5 rounded-lg px-3 py-2 text-sm text-secondary-300 font-mono" />
                         </div>
                         <div>
                            <label class="block text-[10px] font-bold text-secondary mb-1">Código do Módulo</label>
                            <input type="text" :value="previewCodModulo" readonly class="w-full bg-[#0f0f15] border border-white/5 rounded-lg px-3 py-2 text-sm text-secondary-300 font-mono" />
                         </div>
                         <div>
                            <label class="block text-[10px] font-bold text-secondary mb-1">Código da Turma</label>
                            <input type="text" :value="previewCodTurma" readonly class="w-full bg-[#0f0f15] border border-white/5 rounded-lg px-3 py-2 text-sm text-secondary-300 font-mono" />
                         </div>
                     </div>
                </div>

                <div class="h-px bg-white/5"></div>

                <!-- 2. Dates Grid -->
                <div class="space-y-4">
                    <h3 class="text-xs font-bold text-white uppercase tracking-wider opacity-70">Períodos e Datas</h3>
                    
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <!-- Inscrição -->
                        <div class="space-y-2">
                            <label class="block text-[10px] font-bold text-secondary">Data Início Inscrição</label>
                            <input v-model="form.dt_ini_inscri" type="date" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>
                        <div class="space-y-2">
                            <label class="block text-[10px] font-bold text-secondary">Data Fim Inscrição</label>
                            <input v-model="form.dt_fim_inscri" type="date" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>

                        <!-- Docente -->
                        <div class="space-y-2">
                            <label class="block text-[10px] font-bold text-secondary">Data Início S. Docente</label>
                            <input v-model="form.dt_ini_inscri_docente" type="date" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>
                        <div class="space-y-2">
                            <label class="block text-[10px] font-bold text-secondary">Data Fim S. Docente</label>
                            <input v-model="form.dt_fim_inscri_docente" type="date" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>

                        <!-- Matrícula -->
                        <div class="space-y-2">
                            <label class="block text-[10px] font-bold text-secondary">Data Início Matrícula</label>
                            <input v-model="form.dt_ini_mat" type="date" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>
                        <div class="space-y-2">
                            <label class="block text-[10px] font-bold text-secondary">Data Fim Matrícula</label>
                            <input v-model="form.dt_fim_mat" type="date" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>
                        
                        <!-- Curso (Highlight) -->
                        <div class="col-span-2 pt-2 border-t border-white/5 grid grid-cols-2 gap-4">
                            <div class="space-y-2">
                                <label class="block text-[10px] font-bold text-primary">Data Início Curso</label>
                                <input v-model="form.dt_ini_curso" type="date" class="w-full bg-[#0f0f15] border border-primary/30 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                            <div class="space-y-2">
                                <label class="block text-[10px] font-bold text-primary">Data Fim Curso</label>
                                <input v-model="form.dt_fim_curso" type="date" class="w-full bg-[#0f0f15] border border-primary/30 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                            </div>
                        </div>

                    </div>
                </div>

                <div class="h-px bg-white/5"></div>

                <!-- 3. Schedule -->
                <div class="space-y-4">
                    <h3 class="text-xs font-bold text-white uppercase tracking-wider opacity-70">Grade Horária</h3>
                    
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-[10px] font-bold text-secondary mb-1">Horário Início</label>
                            <input v-model="form.hora_ini" type="time" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>
                        <div>
                            <label class="block text-[10px] font-bold text-secondary mb-1">Horário Fim</label>
                            <input v-model="form.hora_fim" type="time" class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:border-primary focus:outline-none" />
                        </div>
                    </div>

                    <!-- Days -->
                    <div class="space-y-2">
                         <label class="block text-[10px] font-bold text-secondary">Dias da Semana</label>
                         <div class="bg-[#0f0f15] border border-white/10 rounded-xl divide-y divide-white/5">
                             <div 
                                v-for="day in daysOfWeek" 
                                :key="day.value"
                                @click="toggleDay(day.value)"
                                class="flex items-center justify-between p-3 cursor-pointer hover:bg-white/5 transition-colors"
                             >
                                <span class="text-sm text-white ml-2">{{ day.label }}</span>
                                <div class="w-5 h-5 rounded-full border flex items-center justify-center transition-all bg-black/40"
                                    :class="form.dias_semana.includes(day.value) ? 'border-primary bg-primary text-white' : 'border-white/20 text-transparent'"
                                >
                                    <svg class="w-3.5 h-3.5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" /></svg>
                                </div>
                             </div>
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
                    :disabled="isSaving"
                    class="bg-primary hover:bg-primary-dark text-white rounded-lg px-6 py-2 text-sm font-bold flex items-center gap-2 transition-all disabled:opacity-50"
                >
                    <svg v-if="isSaving" class="animate-spin h-4 w-4 text-white" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                    {{ turmaId ? 'Salvar Alterações' : 'Criar Turma' }}
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
