<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useAppStore } from '../../../../stores/app';
import ModalPaciente from '~/components/ModalPaciente.vue';
import ModalExamReport from '~/components/ModalExamReport.vue';
import ModalNovoExame from '~/components/ModalNovoExame.vue';
import { useSupabaseUser } from '#imports';
import { useVVSExam } from '~/composables/useVVSExam';

definePageMeta({
  layout: 'base',
  middleware: 'auth'
})

const store = useAppStore();

interface Patient {
    id: string;
    nome_completo: string;
    ultima_interacao: string;
    status: boolean;
    imagem_user: string | null;
    email: string | null;
    data_nascimento: string | null;
}

interface Exam {
    id: string;
    criado_em: string;
    tipo: string;
    nome_profissional_ou_userclinica: string;
    // Add other fields if needed for display
}

const patients = ref<Patient[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);
const search = ref('');

const pagination = ref({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
});

const isModalOpen = ref(false);
const currentPatient = ref<Patient | null>(null);

// Novo Exame Modal State
const isNovoExameOpen = ref(false);
const selectedPatientExame = ref<Patient | null>(null);
const currentUser = useSupabaseUser();
const { startPareamento } = useVVSExam();

// Exams Expansion State
const expandedPatientId = ref<string | null>(null);
const examsCache = ref<Record<string, Exam[]>>({});
const examsLoading = ref<Record<string, boolean>>({});

// Report Modal State
const isReportOpen = ref(false);
const currentExamReport = ref<any>(null);

const fetchPatients = async (page = 1) => {
    loading.value = true;
    error.value = null;
    console.log('fetchPatients called with page:', page);
    try {
        const data = await $fetch('/api/pacientes/otolithics', {
            params: { 
                search: search.value,
                page: page,
                limit: pagination.value.limit
            }
        });
        
        console.log('fetchPatients response:', data);
        
        const result = data as any;
        if (result && result.pacientes) {
            patients.value = result.pacientes;
            pagination.value = {
                page: result.page,
                limit: result.limit,
                total: result.total,
                pages: result.pages
            };
        } else {
             patients.value = [];
             pagination.value.total = 0;
        }

    } catch (err: any) {
        error.value = err.message || 'Erro ao buscar pacientes';
        console.error('Erro ao buscar pacientes:', err);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    fetchPatients(1);
});

const handleSearch = () => {
    fetchPatients(1);
    expandedPatientId.value = null; // Collapse on search
};

const nextPage = () => {
    if (pagination.value.page < pagination.value.pages) {
        fetchPatients(pagination.value.page + 1);
        expandedPatientId.value = null;
    }
};

const previousPage = () => {
    if (pagination.value.page > 1) {
        fetchPatients(pagination.value.page - 1);
        expandedPatientId.value = null;
    }
};

const formatDate = (dateString: string) => {
    if (!dateString) return 'Nunca';
    return new Date(dateString).toLocaleDateString('pt-BR');
};

const formatDateTime = (dateString: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleString('pt-BR');
};

const calculateAge = (dob: string | null) => {
    if (!dob) return 'Idade não informada';
    const birthDate = new Date(dob);
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const m = today.getMonth() - birthDate.getMonth();
    if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
        age--;
    }
    return `${age} anos`;
};

// Helper for Image URL (Patients don't have photos yet, usage fallback)
const getImageUrl = (url: string | null, name: string) => {
    return `https://ui-avatars.com/api/?background=random&name=${encodeURIComponent(name)}`;
};

const toggleExams = async (patientId: string) => {
    if (expandedPatientId.value === patientId) {
        expandedPatientId.value = null;
        return;
    }

    expandedPatientId.value = patientId;

    if (!examsCache.value[patientId]) {
        examsLoading.value[patientId] = true;
        try {
            const data = await $fetch('/api/pacientes/otolithics/exames', {
                params: { patient_id: patientId }
            });
            examsCache.value[patientId] = (data as Exam[]) || [];
        } catch (e) {
            console.error('Erro ao buscar exames:', e);
            // Optionally show error toast
        } finally {
            examsLoading.value[patientId] = false;
        }
    }
};

const performExam = async (id: string) => {
    console.log('Realizar exame:', id);
    selectedPatientExame.value = patients.value.find(p => p.id === id) || null;
    isNovoExameOpen.value = true;
    
    // Explicit Launch instead of a Watcher
    console.log('[INDEX_DEBUG] Injetando pareamento no root view. Context UID:', currentUser.value?.id);
    await startPareamento(currentUser.value?.id);
};

const viewExam = async (examId: string) => {
    console.log('Ver exame:', examId);
    try {
        const data = await $fetch(`/api/pacientes/otolithics/exame/${examId}`);
        console.log('Dados do exame:', data);
        currentExamReport.value = data;
        isReportOpen.value = true;
    } catch (e) {
        console.error('Erro ao buscar detalhes do exame:', e);
    }
};

const editPatient = (p: Patient) => {
    currentPatient.value = p;
    isModalOpen.value = true;
};

const newPatient = () => {
    currentPatient.value = null;
    isModalOpen.value = true;
};

const onModalSave = () => {
    fetchPatients(pagination.value.page);
};
</script>

<template>
    <div class="space-y-6">
        
        <!-- Header -->
        <div class="flex items-center justify-between border-b border-white/10 pb-6 gap-4">
            
            <!-- Search (Expanded) -->
            <div class="flex-1 flex gap-2">
                 <input 
                    v-model="search" 
                    @keyup.enter="handleSearch"
                    type="text" 
                    placeholder="Buscar paciente..." 
                    class="bg-white/5 border border-white/10 rounded-lg px-4 py-2 text-sm text-white focus:outline-none focus:border-primary/50 transition-colors w-full max-w-md"
                />
                <button 
                    @click="handleSearch" 
                    class="px-4 py-2 bg-primary text-white text-xs font-bold uppercase tracking-wider rounded-lg hover:bg-primary-dark transition-colors"
                >
                    Buscar
                </button>
            </div>

            <!-- New Patient Button -->
            <button 
                @click="newPatient"
                class="px-4 py-2 bg-emerald-600 text-white text-xs font-bold uppercase tracking-wider rounded-lg hover:bg-emerald-700 transition-colors flex items-center gap-2"
            >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                Novo Paciente
            </button>
        </div>

        <!-- List -->
        <div v-if="loading" class="space-y-4">
             <div v-for="i in 3" :key="i" class="h-24 bg-white/5 rounded-xl animate-pulse"></div>
        </div>

        <div v-else-if="error" class="bg-red-900/20 border border-red-500/50 text-red-200 p-4 rounded-xl text-center text-sm">
            {{ error }}
        </div>

        <div v-else-if="patients.length > 0" class="space-y-4">
            <!-- Vertical List Item (Planos styling) with User Card internal look (Usuarios styling) -->
            <div v-for="patient in patients" :key="patient.id" class="group relative bg-[#1A1A23] border border-white/5 rounded-xl transition-all duration-300 overflow-hidden">
                
                <div class="p-4 flex items-center justify-between gap-4">
                    
                    <!-- Left: Avatar + Info -->
                    <div class="flex items-center gap-4 flex-1">
                        <!-- Avatar -->
                        <div class="w-12 h-12 rounded-full overflow-hidden border border-white/10 shrink-0 bg-black/20">
                            <img 
                                :src="getImageUrl(patient.imagem_user, patient.nome_completo)" 
                                :alt="patient.nome_completo"
                                class="w-full h-full object-cover"
                            >
                        </div>

                        <!-- Info -->
                        <div>
                             <h3 class="text-base font-bold text-white">{{ patient.nome_completo }}</h3>
                             <p class="text-xs text-secondary">{{ calculateAge(patient.data_nascimento) }}</p>
                             <div class="flex items-center gap-2 mt-1">
                                <span class="text-[10px] uppercase font-bold text-secondary/60 tracking-wider">Última interação:</span>
                                <span class="text-[10px] text-white/80 font-mono">{{ formatDate(patient.ultima_interacao) }}</span>
                             </div>
                        </div>
                    </div>

                    <!-- Right: Actions -->
                    <div class="flex items-center gap-2">
                        <button 
                            @click="performExam(patient.id)" 
                            class="px-3 py-2 bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider rounded-lg hover:bg-primary hover:text-white transition-all border border-primary/20"
                            title="Realizar Exame"
                        >
                            Novo Exame
                        </button>
                        
                        <div class="h-8 w-px bg-white/10 mx-2"></div>

                        <button 
                            @click="toggleExams(patient.id)" 
                            class="p-2 rounded-lg bg-white/5 text-white hover:bg-white/10 transition-colors group-hover:bg-white/10"
                            :class="{ 'bg-primary/20 text-primary': expandedPatientId === patient.id }"
                            title="Histórico de Exames"
                        >
                            <svg class="w-5 h-5 transition-transform duration-300" :class="{ 'rotate-180': expandedPatientId === patient.id }" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        </button>

                        <button 
                            @click="editPatient(patient)" 
                            class="p-2 rounded-lg bg-white/5 text-secondary hover:text-white hover:bg-white/10 transition-colors"
                            title="Editar"
                        >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                        </button>
                    </div>

                </div>

                <!-- Expanded Exams Section -->
                <transition
                    enter-active-class="transition duration-300 ease-out"
                    enter-from-class="transform scale-y-0 opacity-0"
                    enter-to-class="transform scale-y-100 opacity-100"
                    leave-active-class="transition duration-200 ease-in"
                    leave-from-class="transform scale-y-100 opacity-100"
                    leave-to-class="transform scale-y-0 opacity-0"
                >
                    <div v-if="expandedPatientId === patient.id" class="border-t border-white/5 bg-black/20 origin-top">
                        <div class="p-4">
                            <h4 class="text-xs font-bold uppercase text-secondary tracking-wider mb-3 flex items-center gap-2">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
                                Histórico de Exames
                            </h4>

                            <div v-if="examsLoading[patient.id]" class="flex justify-center py-4">
                                <svg class="animate-spin h-5 w-5 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                            </div>

                            <div v-else-if="!examsCache[patient.id] || examsCache[patient.id]?.length === 0" class="text-center py-4 text-xs text-secondary/60">
                                Nenhum exame encontrado para este paciente.
                            </div>

                            <div v-else class="space-y-2">
                                <div v-for="exam in (examsCache[patient.id] || [])" :key="exam.id" class="flex items-center justify-between bg-white/5 rounded-lg p-3 hover:bg-white/10 transition-colors">
                                    <div class="flex items-center gap-4">
                                        <div class="w-8 h-8 rounded bg-primary/20 text-primary flex items-center justify-center font-bold text-xs">
                                            EX
                                        </div>
                                        <div>
                                            <p class="text-xs font-bold text-white">{{ formatDateTime(exam.criado_em) }}</p>
                                            <p class="text-[10px] text-secondary">Prof: {{ exam.nome_profissional_ou_userclinica || 'N/A' }}</p>
                                        </div>
                                    </div>
                                    <button 
                                        @click="viewExam(exam.id)" 
                                        class="px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider bg-white/5 hover:bg-white/10 text-white rounded transition-colors"
                                    >
                                        Ver Exame
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </transition>

            </div>

            <!-- Pagination Controls -->
            <div class="flex items-center justify-between pt-4 border-t border-white/5">
                <span class="text-xs text-secondary">
                    Total: <span class="text-white font-bold">{{ pagination.total }}</span> pacientes
                </span>
                
                <div class="flex gap-2">
                    <button 
                        @click="previousPage" 
                        :disabled="pagination.page === 1"
                        class="px-3 py-1.5 text-xs font-bold uppercase tracking-wider text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                    >
                        Anterior
                    </button>
                    <span class="text-xs text-white px-2 py-1.5">
                        {{ pagination.page }} de {{ pagination.pages }}
                    </span>
                    <button 
                        @click="nextPage" 
                        :disabled="pagination.page >= pagination.pages"
                        class="px-3 py-1.5 text-xs font-bold uppercase tracking-wider text-white bg-white/5 border border-white/10 rounded-lg hover:bg-white/10 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                    >
                        Próxima
                    </button>
                </div>
            </div>
        </div>

        <div v-else class="text-center py-20 bg-white/5 rounded-xl border border-white/5 border-dashed">
            <svg class="w-12 h-12 text-secondary/30 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
            <h3 class="text-lg font-bold text-white mb-1">Nenhum paciente encontrado</h3>
            <p class="text-secondary text-sm">Tente ajustar os filtros ou adicione um novo paciente.</p>
        </div>

        <ModalPaciente 
            :is-open="isModalOpen"
            :patient="currentPatient"
            @close="isModalOpen = false"
            @save="onModalSave"
        />

        <ModalExamReport 
            :is-open="isReportOpen"
            :exam="currentExamReport"
            @close="isReportOpen = false"
        />

        <ModalNovoExame 
            :is-open="isNovoExameOpen"
            :patient="selectedPatientExame"
            @close="isNovoExameOpen = false"
        />
    </div>
</template>
