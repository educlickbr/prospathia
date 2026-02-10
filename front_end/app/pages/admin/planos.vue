<script setup lang="ts">
import { useAppStore } from '../../../stores/app'

definePageMeta({
  layout: 'base',
  middleware: 'auth'
})

const store = useAppStore()
const loading = ref(true)
const plans = ref<any[]>([])
const isModalOpen = ref(false)
const currentPlan = ref<any>(null)

const fetchPlans = async () => {
    if (!store.produto?.id) return
    
    loading.value = true
    try {
        const data = await $fetch('/api/admin/plans/list', {
            params: { produto_id: store.produto.id }
        })
        plans.value = data || []
    } catch (e) {
        console.error('Erro ao buscar planos:', e)
    } finally {
        loading.value = false
    }
}

onMounted(() => {
    if (store.produto?.id) {
        fetchPlans()
    } else {
        const unwatch = watch(() => store.produto, (newVal) => {
            if (newVal?.id) {
                fetchPlans()
                unwatch()
            }
        })
    }
})

const openModal = (plan: any | null) => {
    currentPlan.value = plan
    isModalOpen.value = true
}

const handleSave = () => {
    fetchPlans()
}

const handleDelete = async (plan: any) => {
    if (!confirm(`Tem certeza que deseja excluir o plano "${plan.nome}"?`)) return

    try {
        await $fetch('/api/admin/plans/delete', {
            method: 'POST',
            body: { id: plan.id }
        })
        fetchPlans()
    } catch (e: any) {
        alert(e.statusMessage || 'Erro ao excluir plano.')
    }
}

// Helpers
const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(val)
}

const translateInterval = (interval: string) => {
    const map: any = { 'month': 'mês', 'year': 'ano', 'one_time': 'único' }
    return map[interval] || interval
}
</script>

<template>
    <div class="space-y-6">
        
        <!-- Header -->
        <div class="flex items-center justify-between border-b border-white/10 pb-6">
            <div>
                <h2 class="text-xl font-bold text-white">Gerenciar Planos</h2>
                <p class="text-xs text-secondary mt-1">Configure os planos de assinatura e preços do seu produto.</p>
            </div>
            <button 
                @click="openModal(null)"
                class="px-4 py-2 bg-primary text-white text-xs font-bold uppercase tracking-wider rounded-lg hover:bg-primary-dark transition-colors"
            >
                Novo Plano
            </button>
        </div>

        <!-- List -->
        <div v-if="loading" class="space-y-4">
             <div v-for="i in 3" :key="i" class="h-32 bg-white/5 rounded-xl animate-pulse"></div>
        </div>

        <div v-else-if="plans.length > 0" class="space-y-4">
            <div v-for="plan in plans" :key="plan.id" class="group relative bg-[#1A1A23] border border-white/5 rounded-xl p-6 hover:bg-[#20202B] hover:border-primary/30 transition-all duration-300">
                
                <div class="flex items-center justify-between">
                    <!-- Left: Plan Info -->
                    <div class="flex-1">
                        <div class="flex items-center gap-4 mb-2">
                            <h3 class="text-xl font-bold text-white">{{ plan.nome }}</h3>
                            <span class="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-white/5 text-secondary border border-white/10">
                                {{ translateInterval(plan.intervalo) }}
                            </span>
                        </div>
                        <p class="text-sm text-secondary/80 max-w-2xl">
                            {{ plan.descricao || 'Sem descrição.' }}
                        </p>
                    </div>

                    <!-- Center: Price -->
                    <div class="flex items-center gap-8 px-8">
                        <div class="text-center">
                            <span class="block text-3xl font-bold text-primary">{{ formatCurrency(plan.valor) }}</span>
                            <span class="text-xs text-secondary uppercase tracking-wider">por {{ translateInterval(plan.intervalo) }}</span>
                        </div>
                    </div>

                    <!-- Right: Stripe Info + Actions -->
                    <div class="flex items-center gap-6">
                        <div class="flex flex-col gap-2">
                            <span class="text-[10px] text-secondary uppercase font-bold tracking-wider">Stripe IDs</span>
                            <div class="flex flex-col gap-1">
                                 <span 
                                    v-if="plan.stripe_price_id" 
                                    class="text-[10px] px-2 py-1 rounded bg-green-500/10 text-green-400 border border-green-500/20 font-mono" 
                                    title="Price ID"
                                >
                                    {{ plan.stripe_price_id.slice(0, 12) }}...
                                 </span>
                                 <span v-else class="text-[10px] text-red-500/60 font-mono">No Price ID</span>
                            </div>
                        </div>

                        <div class="flex gap-2">
                            <button @click="openModal(plan)" class="p-3 rounded-lg bg-white/5 text-white hover:bg-white/10 transition-colors" title="Editar">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                            </button>
                            <button @click="handleDelete(plan)" class="p-3 rounded-lg bg-red-500/10 text-red-400 hover:bg-red-500/20 transition-colors" title="Excluir">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                            </button>
                        </div>
                    </div>
                </div>

            </div>
        </div>

        <div v-else class="text-center py-20 bg-white/5 rounded-xl border border-white/5 border-dashed">
            <svg class="w-12 h-12 text-secondary/30 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path></svg>
            <h3 class="text-lg font-bold text-white mb-1">Nenhum plano criado</h3>
            <p class="text-secondary text-sm mb-6">Comece criando um plano de assinatura para o seu produto.</p>
            <button 
                @click="openModal(null)"
                class="px-6 py-2 bg-primary text-white text-xs font-bold uppercase tracking-wider rounded-lg hover:bg-primary-dark transition-colors"
            >
                Criar Primeiro Plano
            </button>
        </div>

        <ModalPlano 
            :is-open="isModalOpen"
            :plano="currentPlan"
            @close="isModalOpen = false"
            @save="handleSave"
        />

    </div>
</template>
