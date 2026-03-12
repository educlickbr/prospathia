<script setup lang="ts">
// Dashboard Metrics Component
defineProps<{
    stats: {
        total_produtos: number;
        total_itens: number;
        itens_disponiveis: number;
        itens_manutencao: number;
        reservas_ativas: number;
        reservas_atrasadas: number;
    } | null
}>();
</script>

<template>
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <!-- Stock Items -->
        <div class="bg-[#1A1B26] border border-white/5 rounded-xl p-4 flex flex-col justify-between h-24">
            <div class="text-secondary text-xs font-bold uppercase tracking-wider">Itens em Estoque</div>
            <div class="flex items-end justify-between">
                <div class="text-3xl font-bold text-white">{{ stats ? stats.total_itens : '-' }}</div>
                <div class="text-xs text-primary bg-primary/10 px-2 py-0.5 rounded">{{ stats ? stats.itens_disponiveis : '-' }} Disp.</div>
            </div>
        </div>

        <!-- Active Reservations -->
        <div class="bg-[#1A1B26] border border-white/5 rounded-xl p-4 flex flex-col justify-between h-24">
            <div class="text-secondary text-xs font-bold uppercase tracking-wider">Reservas Ativas</div>
            <div class="flex items-end justify-between">
                <div class="text-3xl font-bold text-white">{{ stats ? stats.reservas_ativas : '-' }}</div>
                <div class="w-8 h-8 rounded-full bg-blue-500/10 flex items-center justify-center text-blue-500">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                </div>
            </div>
        </div>

        <!-- Overdue -->
        <div class="bg-[#1A1B26] border border-white/5 rounded-xl p-4 flex flex-col justify-between h-24" :class="{'border-red-500/30 bg-red-500/5': stats && stats.reservas_atrasadas > 0}">
            <div class="text-secondary text-xs font-bold uppercase tracking-wider" :class="{'text-red-400': stats && stats.reservas_atrasadas > 0}">Atrasados</div>
            <div class="flex items-end justify-between">
                <div class="text-3xl font-bold" :class="stats && stats.reservas_atrasadas > 0 ? 'text-red-500' : 'text-white'">{{ stats ? stats.reservas_atrasadas : '-' }}</div>
                <div class="w-8 h-8 rounded-full bg-red-500/10 flex items-center justify-center text-red-500" v-if="stats && stats.reservas_atrasadas > 0">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                </div>
            </div>
        </div>

        <!-- Maintenance -->
        <div class="bg-[#1A1B26] border border-white/5 rounded-xl p-4 flex flex-col justify-between h-24">
            <div class="text-secondary text-xs font-bold uppercase tracking-wider">Manutenção</div>
            <div class="flex items-end justify-between">
                <div class="text-3xl font-bold text-white">{{ stats ? stats.itens_manutencao : '-' }}</div>
                <div class="w-8 h-8 rounded-full bg-orange-500/10 flex items-center justify-center text-orange-500">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                </div>
            </div>
        </div>
    </div>
</template>
