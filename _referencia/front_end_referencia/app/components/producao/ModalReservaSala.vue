<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue';
import { format } from 'date-fns';
import { formatInTimeZone } from 'date-fns-tz';
import BaseSelect from '../BaseSelect.vue';
import { useToast } from '../../../composables/useToast';
import { getAnoSemestre } from '../../../utils/seletivo';
import { useAppStore } from '../../stores/app';

const props = defineProps<{
    isOpen: boolean;
    slotData: any; // The clicked slot
    day: Date;
    existingReserva?: any;
    allHorarios: any[]; // All slots to determine periods/day
    allReservas: any[]; // Current reservations to check conflicts
}>();

const emit = defineEmits(['close', 'refresh']);
const { showToast } = useToast();
const client = useSupabaseClient();
const appStore = useAppStore();

// State
const isLoading = ref(false);
const isSaving = ref(false);
const mode = ref<'create' | 'edit'>('create');

// Form Data
const tipo = ref<'curso' | 'evento'>('evento');
const eventoNome = ref('');
const observacoes = ref('');
const selectedArea = ref('Extensão');
const selectedSemestre = ref(getAnoSemestre());
const selectedTurmaId = ref<string | null>(null);

// Scope Selection
const scope = ref<'horario' | 'periodo' | 'dia'>('horario');

// Options
const areas = ['Extensão', 'Regulares', 'Cursos Livres'];
const turmasOptions = ref<any[]>([]);

// Area Map (UI -> DB)
const areaMap: Record<string, string> = {
    'Extensão': 'extensao',
    'Regulares': 'regulares',
    'Cursos Livres': 'cursos_livres'
};

// --- WATCHERS ---

watch(() => props.isOpen, (val) => {
    if (val) {
        initModal();
    }
});

watch([selectedArea, selectedSemestre], () => {
    if (props.isOpen) fetchTurmas();
});

// --- INIT ---

const initModal = () => {
    scope.value = 'horario';
    
    if (props.existingReserva) {
        mode.value = 'edit';
        // Map existing calculated type or actual type if available
        // If type_calculado is 'turma' (from RPC), we map to 'curso'
        tipo.value = props.existingReserva.tipo_calculado === 'turma' ? 'curso' : 'evento';
        observacoes.value = props.existingReserva.observacoes || '';
        
        if (tipo.value === 'evento') {
            eventoNome.value = props.existingReserva.evento || '';
        } else {
            selectedTurmaId.value = props.existingReserva.turma_id;
        }
    } else {
        mode.value = 'create';
        tipo.value = 'evento';
        eventoNome.value = '';
        observacoes.value = '';
        selectedTurmaId.value = null;
    }
    
    // Always fetch turmas to populate dropdowns if needed
    fetchTurmas();
};

// --- DATA FETCHING ---

const fetchTurmas = async () => {
    isLoading.value = true;
    try {
        const { data, error } = await (client.rpc as any)('nxt_get_turmas_seletivo', {
            p_area: areaMap[selectedArea.value],
            p_ano_semestre: selectedSemestre.value
        });
        
        if (error) throw error;
        
        const raw = data as any;
        // Combine all lists
        const all = [...(raw.em_andamento || []), ...(raw.encerrados || [])];
        
        turmasOptions.value = all.map((t: any) => ({
            id: t.id_turma,
            nome: t.nome_curso_turno // This field exists in the RPC return
        }));
        
    } catch (e: any) {
        console.error('Error fetching turmas', e);
        showToast('Erro ao buscar turmas', { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

// --- CONFLIT LOGIC ---

// Get target slots based on scope
const targetSlots = computed(() => {
    if (!props.slotData) return [];
    
    // 1. Horario (Just the clicked slot)
    if (scope.value === 'horario') {
        return [props.slotData];
    }
    
    // 2. Periodo (Same turno)
    if (scope.value === 'periodo') {
        return props.allHorarios.filter(h => 
            h.nome === props.slotData.nome && // Same Room
            h.turno_nome === props.slotData.turno_nome && // Same Session
            h.indice !== 3 && h.indice !== 6 // Skip breaks
        );
    }
    
    // 3. Dia (All slots for this room)
    if (scope.value === 'dia') {
        return props.allHorarios.filter(h => 
            h.nome === props.slotData.nome && // Same Room
            h.indice !== 3 && h.indice !== 6 // Skip breaks
        );
    }
    
    return [];
});

// Check availability
const checkConflict = (targetScope: 'horario' | 'periodo' | 'dia') => {
    // Determine slots for this hypothetical scope
    let slotsToCheck: any[] = [];
    if (targetScope === 'horario') slotsToCheck = [props.slotData];
    else if (targetScope === 'periodo') {
        slotsToCheck = props.allHorarios.filter(h => 
            h.nome === props.slotData.nome && 
            h.turno_nome === props.slotData.turno_nome &&
            h.indice !== 3 && h.indice !== 6
        );
    } else if (targetScope === 'dia') {
        slotsToCheck = props.allHorarios.filter(h => 
            h.nome === props.slotData.nome &&
            h.indice !== 3 && h.indice !== 6
        );
    }
    
    // Check if ANY of these slots has an existing reservation on this day
    const dayStr = formatInTimeZone(props.day, 'America/Sao_Paulo', 'yyyy-MM-dd');
    
    // Existing reservations for this day/room
    const exList = props.allReservas.filter(r => 
        r.data === dayStr
    );
    
    for (const slot of slotsToCheck) {
        // Is there a reservation for this slot?
        const conflict = exList.find(r => r.sala_horario_id === slot.id);
        
        if (conflict) {
            // If checking conflicts for a NEW reservation, any conflict is a blocker.
            // If EDITING, we ignore conflict if it is the SAME reservation.
            if (!props.existingReserva || conflict.id !== props.existingReserva.id) {
                return true; // Conflict found
            }
        }
    }
    
    return false; // No conflict
};

const isPeriodoDisabled = computed(() => checkConflict('periodo'));
const isDiaDisabled = computed(() => checkConflict('dia'));

// --- ACTIONS ---

const save = async () => {
    if (tipo.value === 'curso' && !selectedTurmaId.value) {
        showToast('Selecione uma turma', { type: 'error' });
        return;
    }
    if (tipo.value === 'evento' && !eventoNome.value.trim()) {
        showToast('Informe o nome do evento', { type: 'error' });
        return;
    }
    
    isSaving.value = true;
    
    try {
        const slots = targetSlots.value;
        const dayStr = formatInTimeZone(props.day, 'America/Sao_Paulo', 'yyyy-MM-dd');
        
        // Prepare Batch Payload
        const payload = slots.map(s => ({
            sala_horario_id: s.id,
            data: dayStr,
            status: 'reservado',
            observacoes: observacoes.value,
            evento: tipo.value === 'evento' ? eventoNome.value : null,
            turma_id: tipo.value === 'curso' ? selectedTurmaId.value : null,
            tipo: tipo.value, // 'curso' or 'evento'
            // Aux fields
            ano: formatInTimeZone(props.day, 'America/Sao_Paulo', 'yyyy'),
        }));
        
        await $fetch('/api/producao/calendario/reservas', {
            method: 'POST',
            body: { 
                reservas: payload,
                user_id: appStore.user_expandido_id 
            }
        });
        
        showToast('Reserva salva com sucesso', { type: 'success' });
        emit('refresh');
        emit('close');
        
    } catch (e: any) {
        console.error(e);
        showToast('Erro ao salvar: ' + e.message, { type: 'error' });
    } finally {
        isSaving.value = false;
    }
};

// --- DELETE CONFIRMATION ---

const showConfirmDelete = ref(false);

const handleDeleteClick = () => {
    showConfirmDelete.value = true;
};

const confirmRemove = async () => {
    if (!props.existingReserva) return;
    
    isSaving.value = true;
    try {
        await $fetch('/api/producao/calendario/reservas', {
            method: 'DELETE',
            body: { id: props.existingReserva.id }
        });
        
        showToast('Reserva excluída', { type: 'info' });
        emit('refresh');
        emit('close');
    } catch (e: any) {
        showToast('Erro ao excluir: ' + e.message, { type: 'error' });
    } finally {
        isSaving.value = false;
        showConfirmDelete.value = false;
    }
};

const cancelRemove = () => {
    showConfirmDelete.value = false;
};

</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-black/80 backdrop-blur-sm" @click="emit('close')"></div>
        
        <div class="relative bg-[#1A1B26] border border-white/10 rounded-xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col max-h-[90vh]">
            
            <!-- Header -->
            <div class="p-6 border-b border-white/5 flex items-center justify-between bg-[#16161E]">
                <div>
                    <h2 class="text-xl font-bold text-white mb-1">
                        {{ mode === 'create' ? 'Nova Reserva' : 'Editar Reserva' }}
                    </h2>
                    <p class="text-xs text-secondary">
                        {{ slotData?.nome }} - {{ format(day, 'dd/MM/yyyy') }} - {{ slotData?.horario_total }}
                    </p>
                </div>
                <button @click="emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>
            
            <!-- Body -->
            <div class="p-6 overflow-y-auto flex-1 custom-scrollbar space-y-6">
                
                <!-- Toggle Type -->
                <div class="flex p-1 bg-black/20 rounded-lg">
                    <button 
                        @click="tipo = 'evento'"
                        class="flex-1 py-2 text-sm font-bold rounded-md transition-all"
                        :class="tipo === 'evento' ? 'bg-primary text-white shadow-lg' : 'text-secondary hover:text-white'"
                    >
                        Evento
                    </button>
                    <button 
                        @click="tipo = 'curso'"
                        class="flex-1 py-2 text-sm font-bold rounded-md transition-all"
                        :class="tipo === 'curso' ? 'bg-[#4B5563] text-white shadow-lg' : 'text-secondary hover:text-white'"
                    >
                        Turma
                    </button>
                </div>
                
                <!-- Evento Form -->
                <div v-if="tipo === 'evento'" class="space-y-4">
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-2">Nome do Evento</label>
                        <input 
                            v-model="eventoNome"
                            type="text" 
                            class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30"
                            placeholder="Ex: Reunião Pedagógica"
                        />
                    </div>
                </div>
                
                <!-- Turma Form -->
                <div v-else class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                        <div>
                            <label class="block text-xs font-bold text-secondary mb-2">Área</label>
                            <BaseSelect
                                v-model="selectedArea"
                                :options="areas.map(a => ({ id: a, nome: a }))"
                                labelKey="nome"
                                valueKey="id"
                            />
                        </div>
                        <div>
                            <label class="block text-xs font-bold text-secondary mb-2">Semestre</label>
                            <BaseSelect
                                v-model="selectedSemestre"
                                :options="[getAnoSemestre(), getAnoSemestre(undefined, 1)].map(s => ({ id: s, nome: s }))"
                                labelKey="nome"
                                valueKey="id"
                            />
                        </div>
                    </div>
                    
                    <div>
                        <label class="block text-xs font-bold text-secondary mb-2">Turma</label>
                        <BaseSelect
                            v-model="selectedTurmaId"
                            :options="turmasOptions"
                            labelKey="nome"
                            valueKey="id"
                            placeholder="Selecione a Turma"
                            :disabled="isLoading"
                        />
                        <p v-if="isLoading" class="text-[10px] text-primary mt-1">Carregando turmas...</p>
                    </div>
                </div>
                
                <!-- Observações -->
                <div>
                    <label class="block text-xs font-bold text-secondary mb-2">Observações</label>
                    <textarea 
                        v-model="observacoes"
                        rows="3"
                        class="w-full bg-[#0f0f15] border border-white/10 rounded-lg px-4 py-3 text-sm text-white focus:border-primary focus:outline-none placeholder:text-secondary/30 resize-none"
                        placeholder="Detalhes adicionais..."
                    ></textarea>
                </div>
                
                <!-- Scope Selection -->
                <div>
                     <label class="block text-xs font-bold text-secondary mb-3">Aplicar Reserva para:</label>
                     <div class="space-y-2">
                        <!-- Horario -->
                        <label class="flex items-center justify-between p-3 rounded-lg border border-white/5 cursor-pointer hover:bg-white/5 transition-colors" :class="scope === 'horario' ? 'border-primary/50 bg-primary/5' : ''">
                            <div class="flex items-center gap-3">
                                <input type="radio" v-model="scope" value="horario" class="text-primary focus:ring-primary bg-transparent border-white/20">
                                <span class="text-sm font-medium text-white">Apenas este horário</span>
                            </div>
                            <span class="text-xs text-secondary">{{ slotData?.horario_total }}</span>
                        </label>
                        
                        <!-- Periodo (Disabled if conflict) -->
                        <label 
                            class="flex items-center justify-between p-3 rounded-lg border border-white/5 transition-colors" 
                            :class="[
                                isPeriodoDisabled ? 'opacity-50 cursor-not-allowed bg-red-500/5' : 'cursor-pointer hover:bg-white/5',
                                scope === 'periodo' ? 'border-primary/50 bg-primary/5' : ''
                            ]"
                        >
                            <div class="flex items-center gap-3">
                                <input type="radio" v-model="scope" value="periodo" :disabled="isPeriodoDisabled" class="text-primary focus:ring-primary bg-transparent border-white/20">
                                <div>
                                    <span class="block text-sm font-medium text-white">Todo o Período ({{ slotData?.turno_nome }})</span>
                                    <span v-if="isPeriodoDisabled" class="text-[10px] text-red-400 font-bold">Indisponível (Conflito)</span>
                                </div>
                            </div>
                        </label>
                        
                        <!-- Dia (Disabled if conflict) -->
                        <label 
                            class="flex items-center justify-between p-3 rounded-lg border border-white/5 transition-colors" 
                            :class="[
                                isDiaDisabled ? 'opacity-50 cursor-not-allowed bg-red-500/5' : 'cursor-pointer hover:bg-white/5',
                                scope === 'dia' ? 'border-primary/50 bg-primary/5' : ''
                            ]"
                        >
                            <div class="flex items-center gap-3">
                                <input type="radio" v-model="scope" value="dia" :disabled="isDiaDisabled" class="text-primary focus:ring-primary bg-transparent border-white/20">
                                <div>
                                    <span class="block text-sm font-medium text-white">Dia Todo</span>
                                    <span v-if="isDiaDisabled" class="text-[10px] text-red-400 font-bold">Indisponível (Conflito)</span>
                                </div>
                            </div>
                        </label>
                     </div>
                </div>
                
            </div>
            <div class="p-6 border-t border-white/5 bg-[#16161E] relative overflow-hidden">
                
                <!-- Standard Footer -->
                <div 
                    class="flex items-center justify-between transition-all duration-300"
                    :class="showConfirmDelete ? 'translate-y-20 opacity-0 absolute inset-x-6' : 'translate-y-0 opacity-100'"
                >
                    <div>
                         <button 
                            v-if="mode === 'edit'"
                            @click="handleDeleteClick"
                            class="text-red-500 hover:text-red-400 text-sm font-bold flex items-center gap-2 transition-colors"
                            :disabled="isSaving"
                        >
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                            Excluir
                        </button>
                    </div>
                    
                    <div class="flex items-center gap-3">
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
                            Salvar
                        </button>
                    </div>
                </div>

                <!-- Confirmation View -->
                <div 
                    class="absolute inset-0 bg-[#291717] flex items-center justify-between px-6 transition-all duration-300"
                    :class="showConfirmDelete ? 'translate-y-0 opacity-100' : 'translate-y-full opacity-0'"
                >
                    <span class="text-sm font-bold text-white flex items-center gap-2">
                        <svg class="w-5 h-5 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                        Confirmar exclusão?
                    </span>
                    <div class="flex items-center gap-3">
                        <button 
                            @click="cancelRemove"
                            class="px-4 py-2 text-xs font-bold uppercase tracking-wider text-secondary hover:text-white transition-colors"
                        >
                            Voltar
                        </button>
                        <button 
                            @click="confirmRemove"
                            :disabled="isSaving"
                            class="bg-red-500 hover:bg-red-600 text-white rounded-lg px-6 py-2 text-xs font-bold uppercase tracking-wider flex items-center gap-2 transition-colors shadow-lg shadow-red-500/20"
                        >
                            <span v-if="isSaving">Excluindo...</span>
                            <span v-else>Excluir</span>
                        </button>
                    </div>
                </div>

            </div>
            
        </div>
    </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 6px; }
.custom-scrollbar::-webkit-scrollbar-track { background: #16161E; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 3px; }
</style>
