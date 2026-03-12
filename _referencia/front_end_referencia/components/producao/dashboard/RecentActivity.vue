<script setup lang="ts">
// Recent Activity Component
import { formatDistanceToNow } from 'date-fns';
import { ptBR } from 'date-fns/locale';

defineProps<{
    activity: any[];
}>();

const formatTimeAgo = (date: string) => {
    return formatDistanceToNow(new Date(date), { addSuffix: true, locale: ptBR });
};
</script>

<template>
    <div class="bg-[#1A1B26] border border-white/5 rounded-xl p-6 flex-1">
        <h3 class="text-lg font-bold text-white mb-4 flex items-center gap-2">
            <svg class="w-5 h-5 text-secondary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            Atividade Recente
        </h3>

        <div class="space-y-4">
            <div 
                v-for="item in activity" 
                :key="item.id" 
                class="flex gap-3 items-start"
            >
                <div class="mt-1 w-2 h-2 rounded-full shrink-0" :class="item.tipo === 'reserva' ? 'bg-primary' : 'bg-red-500'"></div>
                <div>
                    <div class="text-sm text-white/90 leading-snug">{{ item.descricao }}</div>
                    <div class="flex items-center gap-2 mt-1">
                        <span class="text-[10px] uppercase font-bold text-secondary bg-white/5 px-1.5 py-0.5 rounded">{{ item.usuario.split(' ')[0] }}</span>
                        <span class="text-[10px] text-white/40">{{ formatTimeAgo(item.data_evento) }}</span>
                    </div>
                </div>
            </div>

            <div v-if="activity.length === 0" class="text-center py-8 text-secondary text-sm">
                Nenhuma atividade recente.
            </div>
        </div>
    </div>
</template>
