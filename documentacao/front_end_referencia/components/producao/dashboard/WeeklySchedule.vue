<script setup lang="ts">
// Weekly Schedule Component
import { format, addDays, startOfWeek, isSameDay } from 'date-fns';
import { computed } from 'vue';

const props = defineProps<{
    events: any[]; // List of events for the week
}>();

// Generate current week dates (Mon-Sun)
const weekDates = computed(() => {
    // startOfWeek defaults to Sunday, pass weekStartsOn: 1 for Monday
    const start = startOfWeek(new Date(), { weekStartsOn: 1 });
    return Array.from({ length: 7 }).map((_, i) => addDays(start, i));
});

const getEventsForDay = (date: Date) => {
    return props.events.filter(e => isSameDay(new Date(e.data_evento), date));
};

const formatDayName = (date: Date) => {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return days[date.getDay()];
};

const formatDayNumber = (date: Date) => {
    return format(date, 'd');
};

const isToday = (date: Date) => {
    return isSameDay(date, new Date());
};
</script>

<template>
    <div class="bg-[#1A1B26] border border-white/5 rounded-xl p-6 flex-1">
        <h3 class="text-lg font-bold text-white mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
            Agenda da Semana
        </h3>
        
        <div class="grid grid-cols-7 gap-2">
            <div 
                v-for="date in weekDates" 
                :key="date.toString()"
                class="flex flex-col h-full min-h-[160px] rounded-lg border p-2 transition-colors relative"
                :class="isToday(date) ? 'bg-primary/5 border-primary/50' : 'bg-black/20 border-white/5'"
            >
                <div class="text-center mb-3">
                    <span class="text-[10px] uppercase font-bold block mb-1" :class="isToday(date) ? 'text-primary' : 'text-secondary'">{{ formatDayName(date) }}</span>
                    <span class="text-xl font-bold" :class="isToday(date) ? 'text-white' : 'text-white/80'">{{ formatDayNumber(date) }}</span>
                </div>

                <!-- Events -->
                <div class="space-y-1.5 overflow-y-auto max-h-[120px] custom-scrollbar">
                    <div 
                        v-for="event in getEventsForDay(date)" 
                        :key="event.id_reserva + event.tipo_evento"
                        class="p-1.5 rounded text-[10px] border border-l-2 truncate cursor-pointer hover:opacity-80 transition-opacity"
                        :class="event.tipo_evento === 'retirada' ? 'bg-blue-500/10 border-blue-500/20 border-l-blue-500 text-blue-200' : 'bg-purple-500/10 border-purple-500/20 border-l-purple-500 text-purple-200'"
                        :title="`${event.tipo_evento === 'retirada' ? 'Retirada' : 'Devolução'}: ${event.produto_nome} - ${event.usuario_nome}`"
                    >
                        <div class="font-bold mb-0.5">{{ event.tipo_evento === 'retirada' ? 'Retirada' : 'Devolução' }}</div>
                        <div class="text-white/80 truncate">{{ event.usuario_nome.split(' ')[0] }}</div>
                        <div class="truncate opacity-75">{{ event.produto_nome }}</div>
                    </div>
                    
                    <div v-if="getEventsForDay(date).length === 0" class="text-center py-4">
                        <span class="text-[10px] text-white/10">-</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 2px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 2px;
}
</style>
