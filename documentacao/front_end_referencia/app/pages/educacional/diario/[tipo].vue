<script setup lang="ts">
import { getAnoSemestre } from '../../../../utils/seletivo';
import BaseSelect from '~/components/BaseSelect.vue';
import { useAppStore } from '~/stores/app';

const store = useAppStore();

const route = useRoute();
const router = useRouter();
const tipo = computed(() => route.params.tipo as string);

// Page Title Mapping
const titleMap: Record<string, string> = {
    'extensao': 'Diário de Extensão',
    'regulares': 'Diário de Regulares',
    'cursos_livres': 'Diário de Cursos Livres'
};
const pageTitle = computed(() => titleMap[tipo.value] || 'Diário de Classe');

// Area Mapping for Fetching
const areaMap: Record<string, string> = {
    'extensao': 'Extensão',
    'regulares': 'Regulares',
    'cursos_livres': 'Cursos Livres'
};
const currentArea = computed(() => areaMap[tipo.value]);

// Filters
const filters = ref({
    data: new Date().toISOString().substring(0, 10),
    turmaId: null,
    search: '',
    anoSemestre: getAnoSemestre()
});

// Options
const semestres = ['25Is', '25IIs', '26Is', '26IIs', '27Is', '27IIs'];
const turmas = ref<any[]>([]);
const turmaOptions = computed(() => {
    return turmas.value.map((t: any) => {
        // Truncate logic similar to calendar
        const maxLen = 30; // Shorter for mobile usually
        const nomeTruncado = t.nome_curso.length > maxLen 
            ? t.nome_curso.substring(0, maxLen) + '...' 
            : t.nome_curso;
        
        return {
            id: t.id,
            label: `${t.nome_curso} (${t.cod_turma})`,
            labelShort: nomeTruncado,
            obj: t
        };
    });
});

// Fetch Turmas
const fetchTurmas = async () => {
    if (!currentArea.value) return;
    try {
        const data: any = await $fetch('/api/educacional/turmas', {
            params: {
                ano_semestre: filters.value.anoSemestre,
                area: currentArea.value
            }
        });
        
        if (data && data.itens) {
            console.log(`[FetchTurmas] Raw: ${data.itens.length} items. Filter target: ${currentArea.value}`);
            // Client-side filter by area
            turmas.value = data.itens.filter((t: any) => t.area_curso === currentArea.value);
            console.log(`[FetchTurmas] Filtered: ${turmas.value.length} items.`);
            
            // Auto Select first if none
            if (turmas.value.length > 0 && !filters.value.turmaId) {
                filters.value.turmaId = turmas.value[0].id;
            } else if (turmas.value.length === 0) {
                filters.value.turmaId = null;
            }
        }
    } catch (e) {
        console.error("Error fetching turmas", e);
    }
};

watch(() => filters.value.anoSemestre, () => {
    fetchTurmas();
});

watch(() => tipo.value, () => {
    // Reset and fetch when route changes
    filters.value.turmaId = null;
    fetchTurmas();
});

onMounted(() => {
    fetchTurmas();
});

// Data States
const diaryData = ref<any[]>([]);
const verificationData = ref<any>(null);
const isLoadingDiary = ref(false);

const loadDiary = async () => {
    if (!filters.value.turmaId || !filters.value.data) return;

    isLoadingDiary.value = true;
    diaryData.value = [];
    verificationData.value = null;

    try {
        // 1. Verify Class/Date Status
        const verify: any = await $fetch('/api/educacional/diario/verificar', {
            params: {
                id_turma: filters.value.turmaId,
                data: filters.value.data
            }
        });
        verificationData.value = verify;

        // 2. Fetch Student/Attendance Data ONLY if there is a class
        if (verify && verify.tem_aula) {
            const entries: any = await $fetch('/api/educacional/diario', {
                params: {
                    id_turma: filters.value.turmaId,
                    data: filters.value.data
                }
            });
            diaryData.value = entries || [];
        }

    } catch (e) {
        console.error("Error loading diary:", e);
    } finally {
        isLoadingDiary.value = false;
    }
};

watch(filters, () => {
    if (filters.value.turmaId && filters.value.data) {
        loadDiary();
    }
}, { deep: true });

</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-transparent md:bg-div-15 rounded-none md:rounded-xl p-0 md:p-8 min-h-[calc(100vh-100px)]">
            


            <!-- FILTERS ROW -->
            <!-- Mobile: Stacked, Desktop: Grid -->
            <div class="grid grid-cols-1 md:grid-cols-12 gap-4 px-4 md:px-0 mb-8">
                
                <!-- 1. Ano/Semestre (Small) -->
                <div class="md:col-span-2">
                    <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Período</label>
                    <div class="relative">
                        <select v-model="filters.anoSemestre" class="w-full bg-[#0f0f15] border border-white/10 text-white text-sm rounded-lg focus:ring-1 focus:ring-primary focus:border-primary p-3 pr-8 outline-none cursor-pointer appearance-none">
                            <option v-for="s in semestres" :key="s" :value="s">{{ s }}</option>
                        </select>
                        <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-secondary">
                             <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </div>
                    </div>
                </div>

                <!-- 2. Turma Selector (Primary Filter) -->
                <div class="md:col-span-4">
                    <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Turma</label>
                    <BaseSelect 
                        v-model="filters.turmaId" 
                        :options="turmaOptions"
                        label-key="label"
                        selected-label-key="labelShort"
                        value-key="id"
                        placeholder="Selecione a Turma"
                        :disabled="!turmas.length"
                    />
                </div>

                <!-- 3. Date Picker -->
                <div class="md:col-span-2">
                    <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Data</label>
                    <input 
                        v-model="filters.data" 
                        type="date" 
                        class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-3 py-2.5 text-sm text-white focus:border-primary focus:outline-none h-[46px]"
                    />
                </div>

                <!-- 4. Search Student -->
                <div class="md:col-span-4">
                    <label class="block text-xs text-secondary-600 mb-1.5 font-bold uppercase tracking-wider">Buscar Aluno</label>
                    <div class="relative">
                        <input 
                            v-model="filters.search" 
                            type="text" 
                            placeholder="Nome ou matrícula..." 
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-2.5 pl-10 text-sm text-white focus:border-primary focus:outline-none h-[46px]"
                        />
                        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                            <svg class="h-4 w-4 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                        </div>
                    </div>
                </div>

            </div>

            <!-- CONTENT -->
            <div class="px-4 md:px-0">
                 <div v-if="!filters.turmaId" class="flex flex-col items-center justify-center py-20 opacity-50 border border-dashed border-white/10 rounded-xl">
                     <p class="text-white font-medium">Selecione uma turma para visualizar o diário.</p>
                 </div>
                 
                 <div v-else class="space-y-6">
                     
                    <!-- STATUS BAR (Only if result is negative) -->
                    <div v-if="verificationData && !verificationData.tem_aula" class="rounded-xl p-4 flex items-center gap-4 transition-all bg-red-500/10 border border-red-500/20">
                        
                        <div class="p-2 rounded-full bg-red-500/20 text-red-500">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                        </div>
                        
                        <div>
                            <h3 class="font-bold text-red-500">
                                Sem Aula Prevista
                            </h3>
                            <p class="text-xs text-secondary font-bold uppercase tracking-wider opacity-80">
                                {{ verificationData.motivo }}
                            </p>
                        </div>
                    </div>

                    <!-- LOADING -->
                    <div v-if="isLoadingDiary" class="flex justify-center py-20">
                         <div class="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
                    </div>

                    <!-- STUDENTS LIST (CARD LAYOUT) -->
                    <div v-else-if="diaryData.length > 0" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
                        <div v-for="student in diaryData" :key="student.id_matricula" 
                            class="bg-[#16161E] border border-white/5 rounded-xl flex md:overflow-visible overflow-hidden transition-colors group relative min-h-[160px]"
                            :class="student.status_matricula === 'Ativa' ? 'hover:border-primary/30' : 'opacity-50 grayscale-[0.8] hover:border-white/10'">
                            
                            <!-- Left: Full Height Photo -->
                            <div class="w-32 relative flex-shrink-0 bg-white/5 border-r border-white/5 group/photo hover:z-50">
                                    <img 
                                    v-if="student.foto_user && store.hash_base" 
                                    :src="store.hash_base + student.foto_user" 
                                    class="absolute inset-0 w-full h-full object-cover transition-all duration-300 z-10 rounded-l-xl md:rounded-lg"
                                    :class="student.status_matricula === 'Ativa' ? 'group-hover/photo:scale-[1.8] group-hover/photo:translate-x-16 group-hover/photo:shadow-[0_0_30px_rgba(0,0,0,0.5)]' : ''"
                                    alt="Foto"
                                    @error="(e: any) => e.target.style.display = 'none'"
                                />
                                <div v-else class="absolute inset-0 flex flex-col items-center justify-center text-xs font-bold text-secondary bg-black/20">
                                    <span class="text-2xl mb-1">{{ student.nome_aluno?.charAt(0) }}</span>
                                    <span class="text-[9px] opacity-50">Sem Foto</span>
                                </div>
                            </div>

                            <!-- Right: Info + Actions -->
                            <div class="flex-1 p-3 flex flex-col justify-between min-w-0 z-10 gap-3 relative">
                                
                                <!-- Status Bullet (Absolute Top Right) -->
                                <div 
                                    class="absolute top-3 right-3 flex items-center gap-1.5 px-2 py-0.5 rounded border"
                                    :class="{
                                        'bg-green-500/10 border-green-500/20 text-green-500': student.status_matricula === 'Ativa',
                                        'bg-red-500/10 border-red-500/20 text-red-500': student.status_matricula !== 'Ativa'
                                    }"
                                >
                                    <span 
                                        class="w-1.5 h-1.5 rounded-full"
                                        :class="{
                                            'bg-green-500': student.status_matricula === 'Ativa',
                                            'bg-red-500': student.status_matricula !== 'Ativa'
                                        }"
                                    ></span>
                                    <span class="text-[9px] font-bold uppercase tracking-wider">{{ student.status_matricula }}</span>
                                </div>

                                <!-- Top Info Block -->
                                <div class="space-y-1">
                                    <!-- Name -->
                                    <div class="pr-20 space-y-0.5">
                                        <!-- Main: Official Name -->
                                        <h5 class="text-sm font-bold text-white truncate leading-tight" :title="student.nome_aluno">
                                            {{ student.nome_aluno }}
                                        </h5>
                                        
                                        <!-- Social Name -->
                                        <p v-if="student.nome_social" class="text-[10px] text-secondary truncate">
                                            Nome Social: {{ student.nome_social }}
                                        </p>
                                        
                                        <!-- Artistic Name -->
                                        <p v-if="student.nome_artistico" class="text-[10px] text-secondary truncate font-italic">
                                            Nome Artístico: {{ student.nome_artistico }}
                                        </p>
                                        
                                        <!-- RA -->
                                        <p class="text-[10px] text-secondary/60 truncate font-mono">
                                            RA: {{ student.ra || student.ra_legado || '-' }}
                                        </p>
                                    </div>
                                </div>

                                <!-- Bottom: Attendance Actions OR Warning -->
                                <div class="flex items-center justify-between mt-1 pt-2 border-t border-white/5 min-h-[36px]">
                                    
                                    <!-- Inactive Warning -->
                                    <div v-if="student.status_matricula !== 'Ativa'" class="w-full flex items-center justify-center gap-2 text-red-400 opacity-80">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                                        <span class="text-[10px] font-bold uppercase tracking-wider">Aluno não possui matrícula ativa</span>
                                    </div>

                                    <!-- Actions (Active Only) -->
                                    <template v-else>
                                        <span class="text-[9px] font-bold text-secondary uppercase tracking-wider mr-2 hidden md:block">Presença</span>
                                        <div class="flex items-center gap-1 w-full md:w-auto justify-between md:justify-end">
                                            <!-- P (Presença) - Success -->
                                            <button 
                                                class="w-7 h-7 rounded flex items-center justify-center text-xs font-bold transition-all border"
                                                :class="student.diario_p1 === 'Presente' 
                                                    ? 'bg-green-500/20 text-green-500 border-green-500/50' 
                                                    : 'bg-white/5 text-secondary border-transparent hover:bg-green-500/20 hover:text-green-500 hover:border-green-500/30'"
                                                title="Presença"
                                            >
                                                P
                                            </button>
                                            <!-- F (Falta) - Danger -->
                                            <button 
                                                class="w-7 h-7 rounded flex items-center justify-center text-xs font-bold transition-all border"
                                                :class="student.diario_p1 === 'Ausente' 
                                                    ? 'bg-red-500/20 text-red-500 border-red-500/50' 
                                                    : 'bg-white/5 text-secondary border-transparent hover:bg-red-500/20 hover:text-red-500 hover:border-red-500/30'"
                                                title="Falta"
                                            >
                                                F
                                            </button>
                                            <!-- J (Justificativa) - Secondary -->
                                            <button 
                                                class="w-7 h-7 rounded flex items-center justify-center text-xs font-bold transition-all border"
                                                :class="student.diario_p1 === 'Justificado' 
                                                    ? 'bg-zinc-500/20 text-zinc-300 border-zinc-500/50' 
                                                    : 'bg-white/5 text-secondary border-transparent hover:bg-zinc-500/20 hover:text-zinc-300 hover:border-zinc-500/30'"
                                                title="Justificativa"
                                            >
                                                J
                                            </button>
                                            <!-- A (Abono) - Secondary -->
                                            <button 
                                                class="w-7 h-7 rounded flex items-center justify-center text-xs font-bold transition-all border"
                                                :class="student.diario_p1 === 'Abono' 
                                                    ? 'bg-zinc-500/20 text-zinc-300 border-zinc-500/50' 
                                                    : 'bg-white/5 text-secondary border-transparent hover:bg-zinc-500/20 hover:text-zinc-300 hover:border-zinc-500/30'"
                                                title="Abono"
                                            >
                                                A
                                            </button>

                                            <div class="w-px h-4 bg-white/10 mx-1"></div>

                                            <!-- Relatório Button (Warning) -->
                                            <button 
                                                class="px-2 h-7 rounded flex items-center justify-center text-[9px] font-bold uppercase tracking-wider transition-all border bg-yellow-500/10 text-yellow-500 border-yellow-500/20 hover:bg-yellow-500/20 hover:border-yellow-500/40"
                                                title="Relatório"
                                            >
                                                Relatório
                                            </button>
                                        </div>
                                    </template>
                                </div>
                            </div>

                        </div>
                    </div>
                    
                    <div v-else-if="verificationData?.tem_aula" class="text-center py-20 text-secondary opacity-50">
                        Nenhum aluno encontrado nesta turma.
                    </div>

                 </div>
            </div>

        </div>
    </NuxtLayout>
</template>
