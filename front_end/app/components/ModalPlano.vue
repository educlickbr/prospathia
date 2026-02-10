<script setup lang="ts">
import { useAppStore } from '../../stores/app'

const props = defineProps<{
  isOpen: boolean
  plano: any | null // null = create mode
}>()

const emit = defineEmits(['close', 'save'])
const store = useAppStore()

// State
const loading = ref(false)
const form = ref({
    nome: '',
    descricao: '',
    valor: 0,
    intervalo: 'month',
    stripe_price_id: '',
    stripe_product_id: ''
})

const isCreateMode = computed(() => !props.plano)

// Initialize
watch(() => props.isOpen, (val) => {
    if (val) {
        if (props.plano) {
            // Edit Mode
            form.value = {
                nome: props.plano.nome,
                descricao: props.plano.descricao || '',
                valor: props.plano.valor,
                intervalo: props.plano.intervalo || 'month',
                stripe_price_id: props.plano.stripe_price_id || '',
                stripe_product_id: props.plano.stripe_product_id || ''
            }
        } else {
            // Create Mode
            form.value = { nome: '', descricao: '', valor: 0, intervalo: 'month', stripe_price_id: '', stripe_product_id: '' }
        }
    }
})

const handleSave = async () => {
    loading.value = true
    try {
        const payload = {
            id: props.plano?.id,
            produto_id: store.produto?.id,
            ...form.value
        }

        await $fetch('/api/admin/plans/upsert', {
            method: 'POST',
            body: payload
        })

        emit('save')
        emit('close')

    } catch (error: any) {
        console.error('Erro ao salvar plano:', error)
        alert(error.statusMessage || 'Erro ao processar solicitação.')
    } finally {
        loading.value = false
    }
}
</script>

<template>
  <div v-if="isOpen" class="relative z-[100]" aria-labelledby="modal-title" role="dialog" aria-modal="true">
    <!-- Backdrop -->
    <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity" @click="$emit('close')"></div>

    <div class="fixed inset-0 z-10 overflow-y-auto">
      <div class="flex min-h-full items-center justify-center p-4 text-center sm:p-0">
        
        <!-- Modal Panel -->
        <div class="relative transform overflow-hidden rounded-xl bg-[#16161E] border border-white/10 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-md" @click.stop>
            
            <!-- Header -->
            <div class="flex items-center justify-between p-6 border-b border-white/10 bg-[#1A1A23]">
                <h3 class="text-lg font-bold text-white tracking-wide">
                    {{ isCreateMode ? 'Novo Plano' : 'Editar Plano' }}
                </h3>
                <button @click="$emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>

            <!-- Body -->
            <div class="p-6 space-y-4">
                
                <div class="flex flex-col gap-2">
                     <label class="text-xs font-bold text-secondary">Nome do Plano</label>
                     <input v-model="form.nome" type="text" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all" />
                </div>

                <div class="flex flex-col gap-2">
                     <label class="text-xs font-bold text-secondary">Descrição</label>
                     <textarea v-model="form.descricao" rows="3" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all"></textarea>
                </div>

                 <div class="grid grid-cols-2 gap-4">
                    <div class="flex flex-col gap-2">
                         <label class="text-xs font-bold text-secondary">Valor (R$)</label>
                         <input v-model="form.valor" type="number" step="0.01" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all" />
                    </div>
                    <div class="flex flex-col gap-2">
                         <label class="text-xs font-bold text-secondary">Intervalo</label>
                         <select v-model="form.intervalo" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all appearance-none">
                             <option value="month" class="bg-[#16161E]">Mensal</option>
                             <option value="year" class="bg-[#16161E]">Anual</option>
                             <option value="one_time" class="bg-[#16161E]">Único</option>
                         </select>
                    </div>
                </div>

                <div class="p-3 bg-white/5 rounded-lg border border-white/5 space-y-3">
                    <h4 class="text-xs font-bold text-primary uppercase tracking-widest">Integração Stripe</h4>
                    
                    <div class="flex flex-col gap-2">
                         <label class="text-xs font-bold text-secondary">Stripe Price ID</label>
                         <input v-model="form.stripe_price_id" type="text" placeholder="price_..." class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all font-mono" />
                    </div>

                    <div class="flex flex-col gap-2">
                         <label class="text-xs font-bold text-secondary">Stripe Product ID</label>
                         <input v-model="form.stripe_product_id" type="text" placeholder="prod_..." class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all font-mono" />
                    </div>
                </div>

            </div>

            <!-- Footer -->
            <div class="p-6 border-t border-white/10 bg-[#1A1A23] flex justify-end gap-3">
                <button @click="$emit('close')" class="px-4 py-2 rounded-lg text-xs font-bold uppercase tracking-wider text-secondary hover:text-white hover:bg-white/5 transition-all">
                    Cancelar
                </button>
                <button 
                    @click="handleSave" 
                    :disabled="loading"
                    class="px-6 py-2 rounded-lg bg-primary text-white text-xs font-bold uppercase tracking-wider hover:bg-primary-dark transition-all disabled:opacity-50 flex items-center gap-2"
                >
                    <span v-if="loading" class="w-3 h-3 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                    Salvar
                </button>
            </div>

        </div>
      </div>
    </div>
  </div>
</template>
