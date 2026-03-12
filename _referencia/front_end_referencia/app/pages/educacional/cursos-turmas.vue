<script setup lang="ts">
import BaseSelect from '../../components/BaseSelect.vue';
import { getAnoSemestre } from '../../../utils/seletivo';
import ModalCurso from '../../components/educacional/ModalCurso.vue';
import ModalTurma from '../../components/educacional/ModalTurma.vue';
import CalendarioTurma from '../../components/educacional/CalendarioTurma.vue';
import { useToast } from '../../../composables/useToast';

const { showToast } = useToast();
const route = useRoute();
const router = useRouter();

// --- STATE ---
const activeTab = ref<'cursos' | 'turmas' | 'calendarios'>('cursos');
const isLoading = ref(false);
const showCreateModal = ref(false); 
const showTurmaModal = ref(false);
const selectedCourseId = ref<string | null>(null);
const selectedTurmaId = ref<string | null>(null);

const filters = ref({
    search: '',
    area: null as string | null,
    anoSemestre: getAnoSemestre()
});

const semesterOptions = computed(() => [
    { label: `${getAnoSemestre(undefined, -1)} (Anterior)`, value: getAnoSemestre(undefined, -1) },
    { label: `${getAnoSemestre()} (Atual)`, value: getAnoSemestre() },
    { label: `${getAnoSemestre(undefined, 1)} (Próximo)`, value: getAnoSemestre(undefined, 1) }
]);

const areaOptions = [
    { label: 'Todas as Áreas', value: null },
    { label: 'Extensão', value: 'Extensão' },
    { label: 'Regulares', value: 'Regulares' },
    { label: 'Cursos Livres', value: 'Cursos Livres' }
];

const items = ref<any[]>([]);
const turmaItems = ref<any[]>([]);
const pagination = ref({ 
    pagina_atual: 1, 
    qtd_paginas: 1, 
    qtd_total: 0 
});
const turmaPagination = ref({ 
    pagina_atual: 1, 
    qtd_paginas: 1, 
    qtd_total: 0 
});

// Calendar State
const calendarEvents = ref<any[]>([]);
const selectedCalendarTurmaId = ref<string | null>(null);
const calendarTurmas = ref<any[]>([]);
const calendarArea = ref<string | null>('Extensão');

// --- ACTIONS ---

const fetchCursos = async () => {
    isLoading.value = true;
    try {
        const data: any = await $fetch('/api/educacional/cursos', {
            params: {
                area: filters.value.area,
                nome: filters.value.search || null,
                pagina: pagination.value.pagina_atual,
                limite: 12
            }
        });
        
        if (data && data.itens) {
            items.value = data.itens;
            pagination.value = {
                pagina_atual: data.pagina_atual,
                qtd_paginas: data.qtd_paginas,
                qtd_total: data.qtd_total
            };
        } else {
             items.value = [];
        }
    } catch (e: any) {
        console.error('Error fetching cursos:', e);
        showToast('Erro ao buscar cursos.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const fetchTurmas = async () => {
    isLoading.value = true;
    try {
        const data: any = await $fetch('/api/educacional/turmas', {
            params: {
                area: filters.value.area,
                nome: filters.value.search || null,
                ano_semestre: filters.value.anoSemestre,
                pagina: turmaPagination.value.pagina_atual,
                limite: 12
            }
        });
        
        if (data && data.itens) {
            turmaItems.value = data.itens;
            turmaPagination.value = {
                pagina_atual: data.pagina,
                qtd_paginas: data.qtd_paginas,
                qtd_total: data.total
            };
        } else {
             turmaItems.value = [];
        }
    } catch (e: any) {
        console.error('Error fetching turmas:', e);
        showToast('Erro ao buscar turmas.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const fetchCalendarEvents = async () => {
    if (!selectedCalendarTurmaId.value) return;
    isLoading.value = true;
    try {
        const events: any = await $fetch('/api/educacional/calendario', {
            params: { id_turma: selectedCalendarTurmaId.value }
        });
        calendarEvents.value = events || [];
    } catch (e: any) {
        console.error('Error fetching calendar:', e);
        showToast('Erro ao buscar calendário.', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const initCalendarTab = async () => {
    isLoading.value = true;
    try {
        // Fetch turmas for dropdown (limit 100 for now, filtered by area)
        const data: any = await $fetch('/api/educacional/turmas', {
            params: { 
                limite: 100,
                area: calendarArea.value
            }
        });
        
        if (data && data.itens) {
            calendarTurmas.value = data.itens.map((t: any) => {
                const maxLen = 50;
                const nomeTruncado = t.nome_curso.length > maxLen 
                    ? t.nome_curso.substring(0, maxLen) + '...' 
                    : t.nome_curso;
                
                return {
                    id: t.id,
                    label: `${t.nome_curso} (${t.cod_turma})`,
                    labelShort: nomeTruncado // Display only truncated name in the button to save space
                };
            });
            
            // Auto-select first if none selected, OR if current selection is not in the new list
            const current = calendarTurmas.value.find(t => t.id === selectedCalendarTurmaId.value);
            if (!current) {
                 if (calendarTurmas.value.length > 0) {
                    selectedCalendarTurmaId.value = calendarTurmas.value[0].id;
                 } else {
                    selectedCalendarTurmaId.value = null;
                    calendarEvents.value = [];
                 }
            }
        } else {
            calendarTurmas.value = [];
            selectedCalendarTurmaId.value = null;
            calendarEvents.value = [];
        }
        
    } catch (e) {
        console.error(e);
        calendarTurmas.value = [];
    } finally {
        isLoading.value = false;
    }

    if (selectedCalendarTurmaId.value) {
        await fetchCalendarEvents();
    }
};

watch(selectedCalendarTurmaId, () => {
    if (activeTab.value === 'calendarios') {
        fetchCalendarEvents();
    }
});

watch(calendarArea, () => {
    if (activeTab.value === 'calendarios') {
        initCalendarTab();
    }
});


// Debounced Search
let searchTimeout: any = null;
watch(() => filters.value.search, () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(() => {
        if (activeTab.value === 'cursos') fetchCursos();
        if (activeTab.value === 'turmas') fetchTurmas();
    }, 500);
});

watch(() => filters.value.area, () => {
    if (activeTab.value === 'cursos') fetchCursos();
    if (activeTab.value === 'turmas') fetchTurmas();
});

watch(() => filters.value.anoSemestre, () => {
    if (activeTab.value === 'turmas') fetchTurmas();
    // For Calendar, since it depends on the selected Turma, we might need to re-fetch the list if we filtered the list by semester too.
    // Ideally initCalendarTab should also respect semester if we want consistent filtering.
    if (activeTab.value === 'calendarios') initCalendarTab();
});

watch(activeTab, (val) => {
    if (val === 'cursos') {
        fetchCursos();
    } else if (val === 'turmas') {
        fetchTurmas();
        turmaItems.value = [];
    } else if (val === 'calendarios') {
        initCalendarTab();
    } else {
        items.value = [];
        turmaItems.value = [];
    }
});

// Init
onMounted(() => {
    fetchCursos();
});

</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-div-15 rounded-xl p-6 md:p-8">
            
            <!-- HEADER -->
            <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 mb-8">
                <div>
                    <h1 class="text-2xl font-black text-white uppercase tracking-tight">Cursos e Turmas</h1>
                    <p class="text-sm text-secondary font-medium mt-1">Gestão Acadêmica</p>
                </div>
                <button 
                    v-if="activeTab !== 'calendarios'"
                    @click="() => {
                        if (activeTab === 'cursos') {
                            selectedCourseId = null; 
                            showCreateModal = true;
                        } else if (activeTab === 'turmas') {
                            selectedTurmaId = null;
                            showTurmaModal = true;
                        }
                    }"
                    class="bg-primary hover:bg-primary-dark text-white rounded-lg px-4 py-2 text-sm font-bold uppercase tracking-wider flex items-center gap-2 transition-all shadow-lg shadow-primary/20"
                >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                    {{ activeTab === 'turmas' ? 'Nova Turma' : 'Novo Curso' }}
                </button>
            </div>

            <!-- TABS -->
            <div class="flex items-center gap-6 border-b border-secondary/10 mb-6">
                <button 
                    @click="activeTab = 'cursos'"
                    class="text-sm font-bold pb-3 relative transition-colors"
                    :class="activeTab === 'cursos' ? 'text-primary' : 'text-secondary hover:text-white'"
                >
                    Cursos
                    <span v-if="activeTab === 'cursos'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                </button>
                <button 
                    @click="activeTab = 'turmas'"
                    class="text-sm font-bold pb-3 relative transition-colors"
                    :class="activeTab === 'turmas' ? 'text-primary' : 'text-secondary hover:text-white'"
                >
                    Turmas
                    <span v-if="activeTab === 'turmas'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                </button>
                <button 
                    @click="activeTab = 'calendarios'"
                    class="text-sm font-bold pb-3 relative transition-colors"
                    :class="activeTab === 'calendarios' ? 'text-primary' : 'text-secondary hover:text-white'"
                >
                    Calendários
                    <span v-if="activeTab === 'calendarios'" class="absolute bottom-[-1px] left-0 w-full h-0.5 bg-primary rounded-full"></span>
                </button>
            </div>

            <!-- CURSOS TAB CONTENT -->
            <div v-if="activeTab === 'cursos'">
                
                <!-- Filters -->
                <div class="grid grid-cols-1 md:grid-cols-12 gap-4 mb-6">
                    <!-- Search -->
                    <div class="md:col-span-8">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Buscar por Nome</label>
                        <div class="relative">
                            <input 
                                v-model="filters.search" 
                                type="text" 
                                placeholder="Digite para buscar..."
                                class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 pl-10 text-sm text-white focus:outline-none focus:border-primary transition-colors placeholder:text-secondary/30"
                            />
                            <svg class="w-4 h-4 text-secondary/50 absolute left-3.5 top-3.5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                        </div>
                    </div>

                    <!-- Area Filter -->
                    <div class="md:col-span-4">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Área</label>
                        <BaseSelect 
                            v-model="filters.area" 
                            :options="areaOptions"
                            label-key="label"
                            value-key="value"
                            placeholder="Todas as Áreas"
                        />
                    </div>
                </div>

                <!-- List -->
                <div v-if="isLoading" class="flex justify-center py-20">
                     <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
                </div>

                <div v-else-if="items.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 bg-[#0f0f15] rounded-xl border border-white/5 border-dashed">
                     <div class="text-4xl mb-4">📚</div>
                     <p class="text-white font-bold">Nenhum curso encontrado</p>
                     <p class="text-sm text-secondary">Tente ajustar os filtros de busca.</p>
                </div>

                <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                    <div 
                        v-for="curso in items" 
                        :key="curso.id"
                        class="bg-[#0f0f15] border border-white/5 rounded-xl p-5 hover:border-primary/30 transition-all group relative overflow-hidden"
                    >
                        <div class="absolute top-0 right-0 p-3 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button @click="selectedCourseId = curso.id; showCreateModal = true" class="bg-white/5 hover:bg-white/10 text-white p-2 rounded-lg transition-colors">
                                <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
                            </button>
                        </div>

                        <div class="flex items-start justify-between mb-3">
                            <span 
                                class="text-[10px] font-black uppercase tracking-wider px-2 py-1 rounded border"
                                :class="{
                                    'bg-blue-500/10 text-blue-500 border-blue-500/20': curso.area === 'Extensão',
                                    'bg-purple-500/10 text-purple-500 border-purple-500/20': curso.area === 'Regulares',
                                    'bg-orange-500/10 text-orange-500 border-orange-500/20': curso.area === 'Cursos Livres',
                                    'bg-gray-500/10 text-gray-400 border-gray-500/20': !['Extensão', 'Regulares', 'Cursos Livres'].includes(curso.area)
                                }"
                            >
                                {{ curso.area }}
                            </span>
                        </div>

                        <h3 class="text-lg font-bold text-white mb-1 line-clamp-2 leading-tight group-hover:text-primary transition-colors">
                            {{ curso.nome_curso }}
                        </h3>
                        
                        <div class="flex items-center gap-2 text-xs text-secondary mb-4">
                            <svg class="w-3.5 h-3.5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" /></svg>
                            <span class="font-mono opacity-70">{{ curso.cod_curso || 'SEM CÓDIGO' }}</span>
                        </div>

                        <div class="pt-4 border-t border-white/5 flex items-center justify-between">
                            <div class="flex items-center gap-2">
                                <div class="w-2 h-2 rounded-full" :class="true ? 'bg-emerald-500' : 'bg-red-500'"></div> <!-- Assuming active since we filter status=true -->
                                <span class="text-xs text-secondary font-medium">Ativo</span>
                            </div>
                            <span class="text-xs text-secondary-500 font-medium">{{ curso.modalidade || 'Presencial' }}</span>
                        </div>
                    </div>
                </div>

                   <!-- PAGINATION -->
                    <div v-if="items.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-8 pt-4 border-t border-white/5">
                        <span class="text-xs md:text-sm text-secondary-500 order-2 md:order-1">
                            <span class="font-medium text-white">{{ (pagination.pagina_atual - 1) * 12 + 1 }}</span> a <span class="font-medium text-white">{{ Math.min(pagination.pagina_atual * 12, pagination.qtd_total) }}</span> de <span class="font-medium text-white">{{ pagination.qtd_total }}</span>
                        </span>
                        <div class="flex gap-2 order-1 md:order-2">
                            <button 
                                @click="pagination.pagina_atual--; fetchCursos()" 
                                :disabled="pagination.pagina_atual === 1"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Anterior
                            </button>
                            <button 
                                @click="pagination.pagina_atual++; fetchCursos()" 
                                :disabled="pagination.pagina_atual >= pagination.qtd_paginas"
                                class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                            >
                                Próxima
                            </button>
                        </div>
                    </div>

            </div>



            <!-- TURMAS TAB CONTENT -->
            <div v-else-if="activeTab === 'turmas'">
                
                <!-- Filters (Shared for now) -->
                <div class="grid grid-cols-1 md:grid-cols-12 gap-4 mb-6">
                    <!-- Search -->
                    <div class="md:col-span-6">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Buscar por Nome / Curso</label>
                        <div class="relative">
                            <input 
                                v-model="filters.search" 
                                type="text" 
                                placeholder="Buscar por nome do curso..."
                                class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 pl-10 text-sm text-white focus:outline-none focus:border-primary transition-colors placeholder:text-secondary/30"
                            />
                            <svg class="w-4 h-4 text-secondary/50 absolute left-3.5 top-3.5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                            </svg>
                        </div>
                    </div>

                    <!-- Semester Filter -->
                    <div class="md:col-span-3">
                         <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Semestre</label>
                        <BaseSelect 
                            v-model="filters.anoSemestre" 
                            :options="semesterOptions"
                            label-key="label"
                            value-key="value"
                            placeholder="Selecione"
                        />
                    </div>

                    <!-- Area Filter -->
                    <div class="md:col-span-3">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Área</label>
                        <BaseSelect 
                            v-model="filters.area" 
                            :options="areaOptions"
                            label-key="label"
                            value-key="value"
                            placeholder="Todas as Áreas"
                        />
                    </div>
                </div>

                <!-- List -->
                <div v-if="isLoading" class="flex justify-center py-20">
                     <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
                </div>

                <div v-else-if="turmaItems.length === 0" class="flex flex-col items-center justify-center py-20 opacity-50 bg-[#0f0f15] rounded-xl border border-white/5 border-dashed">
                     <div class="text-4xl mb-4">🏫</div>
                     <p class="text-white font-bold">Nenhuma turma encontrada</p>
                     <p class="text-sm text-secondary">Tente ajustar os filtros.</p>
                </div>

                <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                    <div 
                        v-for="turma in turmaItems" 
                        :key="turma.id"
                        class="bg-[#0f0f15] border border-white/5 rounded-xl p-5 hover:border-primary/30 transition-all group relative overflow-hidden flex flex-col"
                    >
                         <!-- Status Badge -->
                         <div class="flex items-start justify-between mb-3">
                            <span 
                                class="text-[10px] font-black uppercase tracking-wider px-2 py-1 rounded border"
                                :class="{
                                    'bg-blue-500/10 text-blue-500 border-blue-500/20': turma.area_curso_int === 'Extensão',
                                    'bg-purple-500/10 text-purple-500 border-purple-500/20': turma.area_curso_int === 'Regulares',
                                    'bg-orange-500/10 text-orange-500 border-orange-500/20': turma.area_curso_int === 'Cursos Livres',
                                    'bg-gray-500/10 text-gray-400 border-gray-500/20': !['Extensão', 'Regulares', 'Cursos Livres'].includes(turma.area_curso_int)
                                }"
                            >
                                {{ turma.area_curso }}
                            </span>
                            <span v-if="turma.ano_semestre" class="text-[10px] font-bold text-white bg-white/10 px-2 py-1 rounded">
                                {{ turma.ano_semestre }}
                            </span>
                        </div>

                        <!-- Title -->
                        <h3 class="text-lg font-bold text-white mb-1 leading-tight group-hover:text-primary transition-colors">
                            {{ turma.nome_curso }}
                        </h3>
                        <p class="text-xs text-secondary-400 font-medium mb-4">{{ turma.cod_turma }} · {{ turma.turno || 'Sem Turno' }}</p>

                        <!-- Info Grid -->
                        <div class="grid grid-cols-2 gap-y-2 gap-x-4 text-xs text-secondary mb-4 mt-auto">
                            <div class="flex items-center gap-2">
                                <svg class="w-3.5 h-3.5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                                <span class="truncate">{{ turma.dias_semana || 'A definir' }}</span>
                            </div>
                            <div class="flex items-center gap-2">
                                <svg class="w-3.5 h-3.5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                <span>{{ turma.hora_ini }} - {{ turma.hora_fim }}</span>
                            </div>
                        </div>

                        <!-- Dates Grid -->
                        <div class="grid grid-cols-2 gap-y-3 gap-x-4 border-t border-white/5 pt-4 mt-auto">
                            <!-- Inscrições -->
                            <div>
                                <p class="text-[10px] text-secondary font-bold uppercase tracking-wider mb-1">Inscrições</p>
                                <div class="flex items-center gap-2">
                                    <span class="text-xs text-white">{{ turma.dt_ini_inscri ? new Date(turma.dt_ini_inscri).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' }) : 'N/A' }}</span>
                                    <span class="text-[10px] text-secondary">até</span>
                                    <span class="text-xs text-white">{{ turma.dt_fim_inscri ? new Date(turma.dt_fim_inscri).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' }) : 'N/A' }}</span>
                                </div>
                            </div>
                            <!-- Matrículas -->
                            <div>
                                <p class="text-[10px] text-secondary font-bold uppercase tracking-wider mb-1">Matrículas</p>
                                <div class="flex items-center gap-2">
                                    <span class="text-xs text-white">{{ turma.dt_ini_mat ? new Date(turma.dt_ini_mat).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' }) : 'N/A' }}</span>
                                    <span class="text-[10px] text-secondary">até</span>
                                    <span class="text-xs text-white">{{ turma.dt_fim_mat ? new Date(turma.dt_fim_mat).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' }) : 'N/A' }}</span>
                                </div>
                            </div>
                            <!-- Curso -->
                            <div class="col-span-2 pt-2 border-t border-white/5">
                                 <p class="text-[10px] text-secondary font-bold uppercase tracking-wider mb-1">Período do Curso</p>
                                <div class="flex items-center gap-2">
                                    <span class="text-xs text-secondary-300 font-mono">{{ turma.dt_ini_curso ? new Date(turma.dt_ini_curso).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' }) : 'N/A' }}</span>
                                    <span class="text-[10px] text-secondary">a</span>
                                    <span class="text-xs text-secondary-300 font-mono">{{ turma.dt_fim_curso ? new Date(turma.dt_fim_curso).toLocaleDateString('pt-BR', { timeZone: 'America/Sao_Paulo' }) : 'N/A' }}</span>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>

                 <!-- PAGINATION -->
                <div v-if="turmaItems.length > 0" class="flex flex-col md:flex-row items-center justify-between gap-3 mt-8 pt-4 border-t border-white/5">
                    <span class="text-xs md:text-sm text-secondary-500 order-2 md:order-1">
                        <span class="font-medium text-white">{{ (turmaPagination.pagina_atual - 1) * 12 + 1 }}</span> a <span class="font-medium text-white">{{ Math.min(turmaPagination.pagina_atual * 12, turmaPagination.qtd_total) }}</span> de <span class="font-medium text-white">{{ turmaPagination.qtd_total }}</span>
                    </span>
                    <div class="flex gap-2 order-1 md:order-2">
                        <button 
                            @click="turmaPagination.pagina_atual--; fetchTurmas()" 
                            :disabled="turmaPagination.pagina_atual === 1"
                            class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                            Anterior
                        </button>
                        <button 
                            @click="turmaPagination.pagina_atual++; fetchTurmas()" 
                            :disabled="turmaPagination.pagina_atual >= turmaPagination.qtd_paginas"
                            class="px-4 py-2 text-sm font-medium text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                        >
                            Próxima
                        </button>
                    </div>
                </div>

            </div>

            <!-- CALENDARIOS TAB CONTENT -->
            <div v-else-if="activeTab === 'calendarios'">
                
                <div class="grid grid-cols-1 md:grid-cols-12 gap-4 mb-6">
                     <!-- Semester Filter -->
                    <div class="md:col-span-3">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Semestre</label>
                        <BaseSelect 
                            v-model="filters.anoSemestre" 
                            :options="semesterOptions"
                            label-key="label"
                            value-key="value"
                            placeholder="Selecione"
                        />
                    </div>

                    <!-- Area Filter -->
                     <div class="md:col-span-3">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Área</label>
                        <BaseSelect 
                            v-model="calendarArea" 
                            :options="areaOptions"
                            label-key="label"
                            value-key="value"
                            placeholder="Todas as Áreas"
                        />
                    </div>
                    
                    <!-- Turma Select -->
                    <div class="md:col-span-6">
                        <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Selecione a Turma</label>
                        <BaseSelect 
                            v-model="selectedCalendarTurmaId" 
                            :options="calendarTurmas"
                            label-key="label"
                            value-key="id"
                            selected-label-key="labelShort"
                            placeholder="Selecione uma turma para visualizar o calendário"
                            :disabled="calendarTurmas.length === 0"
                        />
                    </div>
                </div>

                <div v-if="isLoading && !calendarEvents.length" class="flex justify-center py-20">
                     <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-primary"></div>
                </div>
                
                <div v-else class="bg-[#0f0f15] border border-white/5 rounded-xl p-6">
                    <CalendarioTurma 
                        :events="calendarEvents" 
                        :turmaId="selectedCalendarTurmaId"
                        @refresh="fetchCalendarEvents"
                    />
                </div>
            </div>

        </div>
    </NuxtLayout>

    <ModalCurso 
        :isOpen="showCreateModal"
        :courseId="selectedCourseId"
        @close="showCreateModal = false"
        @save="fetchCursos"
    />

    <ModalTurma 
        :isOpen="showTurmaModal"
        :turmaId="selectedTurmaId"
        @close="showTurmaModal = false"
        @save="fetchTurmas"
    />
</template>
