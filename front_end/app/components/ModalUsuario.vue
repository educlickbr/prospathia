<script setup lang="ts">
import { useAppStore } from '../../stores/app'

const props = defineProps<{
  isOpen: boolean
  user: any | null // null = create mode
  roleId: string // Role ID for creation context
  questions: any[]
}>()

const emit = defineEmits(['close', 'save'])
const store = useAppStore()

// State
const loading = ref(false)
const answers = ref<Record<string, any>>({})
const form = ref({
    nome_completo: '',
    telefone: '',
    email: '',
    password: '',
    id_arquivo_imagem_user: null as string | null
})
const avatarPreview = ref<string | null>(null)
const uploadingAvatar = ref(false)

const isCreateMode = computed(() => !props.user)
const fileInputRef = ref<HTMLInputElement | null>(null)

const triggerFileInput = () => {
    fileInputRef.value?.click()
}

// Initialize
watch(() => props.isOpen, (val) => {
        resetForm()
        if (props.user) {
            // Edit Mode
            form.value.nome_completo = props.user.nome_completo
            form.value.telefone = props.user.telefone || ''
            form.value.email = props.user.email // Read-only usually
            form.value.id_arquivo_imagem_user = props.user.id_arquivo_imagem_user || null
            
            // Set initial preview if exists
            if (props.user.imagem_user) {
                // If it's a full URL (legacy or external), use it. 
                // If it's a path, use getSignedUrl from store
                form.value.id_arquivo_imagem_user = props.user.id_arquivo_imagem_user // Ensure we have the ID if available
                avatarPreview.value = store.getSignedUrl(props.user.imagem_user)
            }
            
            // Populate answers
            if (props.user.respostas) {
                props.user.respostas.forEach((r: any) => {
                    let val = r.resposta
                    
                    // Specific fix for "Tipo de Pessoa" case mismatch
                    // If the question is an option type, we might want to find the matching option ignoring case
                    const question = props.questions.find(q => q.id === r.pergunta_id)
                    if (question && question.tipo_pergunta === 'opcao' && question.opcoes) {
                         const match = question.opcoes.find((opt: string) => opt.toLowerCase() === val?.toLowerCase())
                         if (match) val = match
                    }

                    answers.value[r.pergunta_id] = val
                })
            }
        }
})

const resetForm = () => {
    form.value = { nome_completo: '', telefone: '', email: '', password: '', id_arquivo_imagem_user: null }
    answers.value = {}
    avatarPreview.value = null
    loading.value = false
    uploadingAvatar.value = false
}

// Actions
const handleAvatarChange = async (event: Event) => {
    const input = event.target as HTMLInputElement
    // Typed file access
    if (!input.files || input.files.length === 0) return

    const file = input.files[0]
    if (!file) return
    
    // Validate
    if (!['image/jpeg', 'image/png', 'image/jpg'].includes(file.type)) {
        alert('Apenas imagens JPG ou PNG são permitidas.')
        return
    }

    uploadingAvatar.value = true
    try {
        // If replacing an existing image, delete it first
        if (form.value.id_arquivo_imagem_user) {
            try {
                await $fetch('/api/upload/delete', {
                    method: 'POST',
                    body: { file_id: form.value.id_arquivo_imagem_user }
                })
            } catch (delErr) {
                console.warn('Falha ao deletar imagem anterior', delErr)
                // Proceed anyway
            }
        }

        const formData = new FormData()
        formData.append('file', file)

        const res: any = await $fetch('/api/upload/files', {
            method: 'POST',
            body: formData
        })

        if (res && res.success && res.file) {
            // Store ID for the form
            form.value.id_arquivo_imagem_user = res.file.id
            
            // Update preview immediately
            // We can use the signed URL from store if we have the path, or just a blob url for speed
            // Since we have the path from response, let's try to get a signed URL or blob
            // For simplicity and speed, let's use a local blob preview
            avatarPreview.value = URL.createObjectURL(file)
        }

    } catch (e: any) {
        console.error('Upload avatar error:', e)
        alert('Erro ao enviar imagem.')
    } finally {
        uploadingAvatar.value = false
    }
}

const handleRemoveAvatar = async () => {
    if (!form.value.id_arquivo_imagem_user) return

    if (!confirm('Tem certeza que deseja remover a foto?')) return

    uploadingAvatar.value = true
    try {
        await $fetch('/api/upload/delete', {
            method: 'POST',
            body: { file_id: form.value.id_arquivo_imagem_user }
        })

        form.value.id_arquivo_imagem_user = null
        avatarPreview.value = null
        
        // Reset file input
        if (fileInputRef.value) fileInputRef.value.value = ''

    } catch (e: any) {
        console.error('Erro ao deletar avatar:', e)
        alert('Erro ao remover imagem.')
    } finally {
        uploadingAvatar.value = false
    }
}



// Helper: Visibility Logic
const isVisible = (q: any) => {
    // If not dependent, always show
    if (!q.depende) return true
    
    // Check master question value
    const masterValue = answers.value[q.depende_de]
    
    // Compare
    return masterValue === q.valor_depende
}

const handleSave = async () => {
    loading.value = true
    try {
        const respostasArray = Object.entries(answers.value).map(([pId, val]) => ({
            pergunta_id: pId,
            resposta: val,
            arquivo: null
        }))

        // Payload
        const payload: any = {
             produto_id: store.produto?.id,
             respostas: respostasArray
        }

        if (isCreateMode.value) {
            // Create
             payload.email = form.value.email
             payload.password = form.value.password
             payload.nome_completo = form.value.nome_completo
             payload.telefone = form.value.telefone
             payload.id_arquivo_imagem_user = form.value.id_arquivo_imagem_user
             payload.papel_id = props.roleId // Assign role

             await $fetch('/api/admin/users/create', {
                 method: 'POST',
                 body: payload
             })
        } else {
            // Edit
            payload.user_id = props.user.id
            payload.dados_user = {
                nome_completo: form.value.nome_completo,
                telefone: form.value.telefone,
                id_arquivo_imagem_user: form.value.id_arquivo_imagem_user
            }
            
            await $fetch('/api/admin/users/upsert', {
                 method: 'POST',
                 body: payload
             })
        }

        emit('save')
        emit('close')

    } catch (error: any) {
        console.error('Erro ao salvar:', error)
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
        <div class="relative transform overflow-hidden rounded-xl bg-[#16161E] border border-white/10 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-2xl" @click.stop>
            
            <!-- Header -->
            <div class="flex items-center justify-between p-6 border-b border-white/10 bg-[#1A1A23]">
                <h3 class="text-lg font-bold text-white tracking-wide">
                    {{ isCreateMode ? 'Novo Usuário' : 'Editar Usuário' }}
                </h3>
                <button @click="$emit('close')" class="text-secondary hover:text-white transition-colors">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                </button>
            </div>

            <!-- Body -->
            <div class="p-6 space-y-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
                
                <!-- Static Profile Fields -->
                <div class="space-y-4">
                    <h4 class="text-xs font-bold text-primary uppercase tracking-widest mb-4">Dados de Acesso</h4>
                    
                    <!-- Avatar Upload -->
                    <div class="flex items-center gap-4 mb-6">
                        <div class="relative group">
                            <div class="w-20 h-20 rounded-full border-2 border-white/10 bg-black/20 overflow-hidden flex items-center justify-center">
                                <img v-if="avatarPreview" :src="avatarPreview" class="w-full h-full object-cover" />
                                <svg v-else class="w-8 h-8 text-secondary/50" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                                
                                <div class="absolute inset-0 bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer" @click="triggerFileInput">
                                    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                </div>
                                
                                <!-- Loading overlay -->
                                <div v-if="uploadingAvatar" class="absolute inset-0 bg-black/80 flex items-center justify-center">
                                    <div class="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin"></div>
                                </div>
                            </div>
                            <input type="file" ref="fileInputRef" class="hidden" accept="image/jpeg,image/png,image/jpg" @change="handleAvatarChange" />
                        </div>
                        
                        <div class="flex flex-col gap-1">
                            <span class="text-sm font-bold text-white">Foto de Perfil</span>
                            <span class="text-xs text-secondary">JPG ou PNG, máx 5MB</span>
                            <button v-if="avatarPreview" @click="handleRemoveAvatar" class="text-xs text-red-400 hover:text-red-300 text-left mt-1">Remover foto</button>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="flex flex-col gap-2">
                             <label class="text-xs font-bold text-secondary">Nome Completo <span class="text-primary">*</span></label>
                             <input v-model="form.nome_completo" type="text" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all" />
                        </div>
                        <div class="flex flex-col gap-2">
                             <label class="text-xs font-bold text-secondary">Telefone</label>
                             <input v-model="form.telefone" type="text" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all" />
                        </div>
                        <div class="flex flex-col gap-2">
                             <label class="text-xs font-bold text-secondary">Email <span v-if="isCreateMode" class="text-primary">*</span></label>
                             <input 
                                v-model="form.email" 
                                type="email" 
                                :disabled="!isCreateMode"
                                class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all disabled:opacity-50 disabled:cursor-not-allowed" 
                            />
                        </div>
                        <div v-if="isCreateMode" class="flex flex-col gap-2">
                             <label class="text-xs font-bold text-secondary">Senha <span class="text-primary">*</span></label>
                             <input v-model="form.password" type="password" class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all" />
                        </div>
                    </div>
                </div>

                <hr class="border-white/5" />

                <!-- Dynamic Questions -->
                <div v-if="questions.length > 0" class="space-y-4">
                     <h4 class="text-xs font-bold text-primary uppercase tracking-widest mb-4">Informações Adicionais</h4>
                     
                     <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <template v-for="q in questions" :key="q.id">
                            <div 
                                v-if="isVisible(q)" 
                                class="flex flex-col gap-2 transition-all duration-300"
                                :class="[q.largura === 2 ? 'md:col-span-2' : '']"
                            >
                                <label class="text-xs font-bold text-secondary">{{ q.label }}</label>
                                
                                <!-- Input Types -->
                                <input 
                                    v-if="q.tipo_pergunta === 'texto'" 
                                    v-model="answers[q.id]" 
                                    type="text" 
                                    class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all"
                                />

                                <select 
                                    v-else-if="q.tipo_pergunta === 'opcao'" 
                                    v-model="answers[q.id]"
                                    class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all appearance-none"
                                >
                                    <option value="" disabled selected>Selecione...</option>
                                    <option v-for="opt in q.opcoes" :key="opt" :value="opt" class="bg-[#16161E]">{{ opt }}</option>
                                </select>

                                <input 
                                    v-else-if="q.tipo_pergunta === 'data'" 
                                    v-model="answers[q.id]" 
                                    type="date" 
                                    class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all"
                                />
                                
                                <input 
                                    v-else
                                    v-model="answers[q.id]" 
                                    type="text" 
                                    class="w-full bg-black/20 border border-white/10 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-primary transition-all"
                                />
                            </div>
                        </template>
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
                    {{ isCreateMode ? 'Criar Usuário' : 'Salvar Alterações' }}
                </button>
            </div>

        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.05);
}
.custom-scrollbar::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
}
</style>
