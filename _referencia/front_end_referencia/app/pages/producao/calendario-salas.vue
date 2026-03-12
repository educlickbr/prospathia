<script setup lang="ts">
import { useToast } from "../../../composables/useToast";
import { startOfWeek, endOfWeek, addWeeks, subWeeks, format, addDays, isSameDay } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { formatInTimeZone } from 'date-fns-tz';

import BaseSelect from '~/components/BaseSelect.vue';
import ModalReservaSala from '~/components/producao/ModalReservaSala.vue';

const { showToast } = useToast();

const currentDate = ref(new Date());
const weekDays = computed(() => {
    const start = startOfWeek(currentDate.value, { weekStartsOn: 1 }); // Monday
    return Array.from({ length: 7 }).map((_, i) => addDays(start, i));
});

const horarios = ref<any[]>([]);
const reservas = ref<any[]>([]);
const isLoading = ref(false);
const selectedSala = ref<string>('all');
const dateInput = ref<HTMLInputElement | null>(null);
const filteredHorarios = computed(() => {
    if (selectedSala.value === 'all') return horarios.value;
    return horarios.value.filter(h => h.nome === selectedSala.value);
});

// Dropdown options
const availableSalas = computed(() => {
    const unique = new Set(horarios.value.map(h => h.nome));
    return Array.from(unique);
});

onMounted(() => {
    fetchHorarios();
    fetchReservas();
});

const fetchHorarios = async () => {
    try {
        const data = await $fetch('/api/producao/calendario/horarios');
        horarios.value = data || [];
    } catch (e: any) {
        showToast('Erro ao carregar horários: ' + e.message, { type: 'error' });
    }
};

const fetchReservas = async () => {
    isLoading.value = true;
    if (!weekDays.value.length) return;
    const start = format(weekDays.value[0]!, 'yyyy-MM-dd');
    const end = format(weekDays.value[6]!, 'yyyy-MM-dd');
    
    try {
        const data = await $fetch(`/api/producao/calendario/reservas?start=${start}&end=${end}`);
        reservas.value = data || [];
    } catch (e: any) {
        showToast('Erro ao carregar reservas: ' + e.message, { type: 'error' });
    } finally {
        isLoading.value = false;
    }
};

const navigateWeek = (direction: 'prev' | 'next' | 'today') => {
    if (direction === 'today') currentDate.value = new Date();
    else if (direction === 'next') currentDate.value = addWeeks(currentDate.value, 1);
    else currentDate.value = subWeeks(currentDate.value, 1);
};

watch(currentDate, () => {
    fetchReservas();
});


const getReservaForSlot = (slotId: string, day: Date) => {
    const targetDate = formatInTimeZone(day, 'America/Sao_Paulo', 'yyyy-MM-dd');
    return reservas.value.find(r => 
        r.sala_horario_id === slotId && 
        r.data === targetDate
    );
};

const getBackgroundColor = (salaColor: string) => {
    return {
        borderColor: salaColor,
        backgroundColor: `${salaColor}10` // 10% opacity
    };
};

const handleCellClick = (slot: any, day: Date) => {
    const reserva = getReservaForSlot(slot.id, day);
    
    selectedSlot.value = slot;
    selectedDay.value = day;
    selectedExistingReserva.value = reserva || null;
    
    // If there is an existing reservation, only open if it is 'confirmed' or 'reservado' (which is implied by existence)
    // But we might want to check permissions later. For now, just open.
    showReservationModal.value = true;
};

// Modal State
const showReservationModal = ref(false);
const selectedSlot = ref<any>(null);
const selectedDay = ref(new Date());
const selectedExistingReserva = ref<any>(null);

// Tooltip Logic
const hoveredInfo = ref<any>(null);
const tooltipPos = ref({ x: 0, y: 0 });

const handleMouseEnter = (event: MouseEvent, slot: any, day: Date) => {
    const reserva = getReservaForSlot(slot.id, day);
    if (!reserva) return;
    
    hoveredInfo.value = reserva;
    const target = event.currentTarget as HTMLElement;
    const rect = target.getBoundingClientRect();
    
    // Position to the right (rect.right + 10px) and top aligned (rect.top)
    tooltipPos.value = {
        x: rect.right + 10,
        y: rect.top
    };
};

const handleMouseLeave = () => {
    hoveredInfo.value = null;
};
</script>

<template>
    <NuxtLayout name="base">
        <div class="bg-transparent md:bg-div-15 rounded-none md:rounded-xl p-0 md:p-8 flex-1 w-full relative h-[calc(100vh-2rem)] flex flex-col">
            
            <!-- HEADER -->
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6 shrink-0">
                <div>
                    <h1 class="text-2xl font-bold text-white mb-2">Calendário de Salas</h1>
                    <p class="text-secondary text-sm">Visualize e gerencie a ocupação das salas.</p>
                </div>
                
                <div class="flex items-center gap-3 w-full md:w-auto">
                    <!-- Sala Filter -->
                    <div class="w-48">
                        <BaseSelect
                            v-model="selectedSala"
                            :options="[{ id: 'all', nome: 'Todas as Salas' }, ...availableSalas.map(s => ({ id: s, nome: s }))]"
                            labelKey="nome"
                            valueKey="id"
                            placeholder="Selecione a Sala"
                        />
                    </div>

                    <div class="h-8 w-px bg-white/10 mx-2"></div>

                    <!-- Date Picker -->
                    <div class="relative">
                        <input 
                            ref="dateInput"
                            type="date" 
                            :value="format(currentDate, 'yyyy-MM-dd')" 
                            @input="(e) => currentDate = new Date((e.target as HTMLInputElement).value)"
                            class="absolute inset-0 w-0 h-0 opacity-0"
                            style="visibility: hidden;"
                        />
                         <button 
                            @click="() => dateInput?.showPicker()"
                            class="bg-[#16161E] border border-white/10 rounded-lg px-4 py-2 text-xs font-bold text-white flex items-center gap-2 h-[42px] hover:border-primary/50 transition-colors w-full"
                        >
                            <svg class="w-4 h-4 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                            <span>{{ format(currentDate, 'dd/MM/yyyy') }}</span>
                         </button>
                    </div>

                    <!-- Navigation -->
                    <div class="flex items-center bg-[#16161E] rounded-lg border border-white/10 h-[42px]">
                        <button @click="navigateWeek('prev')" class="px-3 text-secondary hover:text-white border-r border-white/10 h-full flex items-center transition-colors">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path></svg>
                        </button>
                        <button @click="navigateWeek('today')" class="px-4 text-xs font-bold text-white h-full flex items-center hover:bg-white/5 transition-colors uppercase tracking-wider">
                            Hoje
                        </button>
                        <button @click="navigateWeek('next')" class="px-3 text-secondary hover:text-white border-l border-white/10 h-full flex items-center transition-colors">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
                        </button>
                    </div>
                </div>
            </div>

            <!-- CALENDAR GRID -->
            <div class="flex-1 overflow-auto bg-[#16161E] border border-white/5 rounded-xl relative custom-scrollbar">
                
                <!-- Date Headers Sticky -->
                <div 
                    class="border-b border-white/10 sticky top-0 bg-[#16161E] z-20 grid"
                    style="grid-template-columns: 200px repeat(7, minmax(140px, 1fr));"
                >
                    <div class="p-4 flex flex-col justify-center items-center border-r border-white/5 font-bold text-secondary text-xs bg-[#16161E] sticky left-0 z-30 shadow-[4px_0_12px_rgba(0,0,0,0.5)]">
                        <span class="uppercase tracking-wider">Sala / Horário</span>
                    </div>
                    <div 
                        v-for="day in weekDays" 
                        :key="day.toString()" 
                        class="p-3 text-center border-r border-white/5 last:border-0 bg-[#16161E]"
                        :class="isSameDay(day, new Date()) ? 'bg-primary/5' : ''"
                    >
                        <div class="text-[10px] uppercase font-bold text-secondary mb-1">{{ format(day, 'EEE', { locale: ptBR }) }}</div>
                        <div class="text-xl font-bold text-white" :class="isSameDay(day, new Date()) ? 'text-primary' : ''">{{ format(day, 'dd/MM') }}</div>
                    </div>
                </div>

                <!-- Loading State -->
                <div v-if="isLoading && !horarios.length" class="flex justify-center py-20">
                     <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                </div>
                
                <!-- Flat Rows -->
                <template v-else>
                    <div 
                        v-for="slot in filteredHorarios" 
                        :key="slot.id" 
                        class="border-b border-white/5 hover:bg-white/[0.02] transition-colors grid"
                        style="grid-template-columns: 200px repeat(7, minmax(140px, 1fr));"
                    >
                        <!-- Left Header (Sticky) -->
                        <div 
                            class="sticky left-0 bg-[#16161E] border-r border-white/5 p-4 flex flex-col justify-center z-10 shadow-[4px_0_12px_rgba(0,0,0,0.2)] group"
                            :style="{ borderLeft: `4px solid ${slot.cor}` }"
                        >
                            <span class="text-sm font-bold text-white mb-1">{{ slot.nome }}</span>
                            <span class="text-xs font-medium text-secondary">{{ slot.horario_total }}</span>
                        </div>

                        <!-- Days Cells -->
                        <div 
                            v-for="day in weekDays" 
                            :key="slot.id + day.toString()" 
                            class="border-r border-white/5 last:border-0 p-1 min-h-[80px] relative"
                            :style="{ backgroundColor: getReservaForSlot(slot.id, day) ? '' : `${slot.cor}08` }" 
                        >
                            <button 
                                @click="handleCellClick(slot, day)"
                                @mouseenter="handleMouseEnter($event, slot, day)"
                                @mouseleave="handleMouseLeave"
                                class="w-full h-full rounded flex flex-col items-center justify-center p-2 transition-all hover:bg-white/10 relative group"
                            >
                                <template v-if="getReservaForSlot(slot.id, day)">
                                    <div 
                                        class="absolute inset-1 rounded border-l-4 flex flex-col items-start justify-center px-3 shadow-lg z-0 overflow-hidden"
                                        :class="getReservaForSlot(slot.id, day)?.tipo_calculado === 'turma' ? 'bg-[#1A1B26]/90' : 'bg-[#1A1B26]'"
                                        :style="getReservaForSlot(slot.id, day)?.tipo_calculado === 'turma' 
                                            ? { borderLeftColor: '#4B5563' } 
                                            : { borderLeftColor: slot.cor, backgroundColor: slot.cor + '20' }"
                                    >
                                        <span 
                                            class="text-xs font-bold w-full z-10 relative line-clamp-2 text-left"
                                            :class="getReservaForSlot(slot.id, day)?.tipo_calculado === 'turma' ? 'text-white' : 'text-white'"
                                        >
                                            {{ getReservaForSlot(slot.id, day)?.tipo_calculado === 'turma' 
                                                ? getReservaForSlot(slot.id, day)?.turma_info_completa 
                                                : getReservaForSlot(slot.id, day)?.evento 
                                            }}
                                        </span>
                                        <span class="text-[10px] text-left w-full truncate z-10 relative mt-0.5 text-secondary">
                                            {{ getReservaForSlot(slot.id, day)?.observacoes || '' }}
                                        </span>
                                    </div>
                                </template>
                                <template v-else>
                                    <span class="opacity-0 group-hover:opacity-100 text-secondary text-xs font-bold transition-opacity">+</span>
                                </template>
                            </button>
                        </div>
                    </div>
                </template>

            </div>

        </div>

    </NuxtLayout>
    
    <ModalReservaSala
        :isOpen="showReservationModal"
        :slotData="selectedSlot"
        :day="selectedDay"
        :existingReserva="selectedExistingReserva"
        :allHorarios="horarios"
        :allReservas="reservas"
        @close="showReservationModal = false"
        @refresh="fetchReservas"
    />

    <Teleport to="body">
        <div 
            v-if="hoveredInfo"
            class="fixed z-50 bg-[#1A1B26] border border-white/10 rounded-xl shadow-2xl p-4 w-64 pointer-events-none transition-opacity duration-200"
            :style="{ top: `${tooltipPos.y}px`, left: `${tooltipPos.x}px` }"
        >
            <div class="flex items-center gap-2 mb-2 pb-2 border-b border-white/5">
                <div class="w-1.5 h-4 rounded" :class="hoveredInfo.tipo_calculado === 'turma' ? 'bg-[#4B5563]' : 'bg-primary'"></div>
                <span class="text-xs font-bold text-white uppercase tracking-wider">
                    {{ hoveredInfo.tipo_calculado === 'turma' ? 'Turma' : 'Evento' }}
                </span>
            </div>
            
            <h4 class="text-sm font-bold text-white mb-2 leading-tight">
                {{ hoveredInfo.tipo_calculado === 'turma' ? hoveredInfo.turma_info_completa : hoveredInfo.evento }}
            </h4>
            
            <div v-if="hoveredInfo.observacoes" class="text-xs text-secondary/80 bg-black/20 p-2 rounded-lg leading-relaxed">
                {{ hoveredInfo.observacoes }}
            </div>
        </div>
    </Teleport>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar { width: 8px; height: 8px; }
.custom-scrollbar::-webkit-scrollbar-track { background: #16161E; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 4px; }
.custom-scrollbar::-webkit-scrollbar-corner { background: #16161E; }
</style>
