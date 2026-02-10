<script setup lang="ts">
definePageMeta({
    layout: 'base',
    middleware: 'auth'
})

const file = ref<File | null>(null)
const uploading = ref(false)
const uploadResult = ref<any>(null)

const onFileChange = (e: Event) => {
    const target = e.target as HTMLInputElement
    if (target.files && target.files.length > 0) {
        file.value = target.files[0] as File
    }
}

const handleUpload = async () => {
    if (!file.value) return
    uploading.value = true
    uploadResult.value = null

    try {
        const formData = new FormData()
        formData.append('file', file.value)

        const res = await $fetch('/api/upload/files', {
            method: 'POST',
            body: formData
        })

        uploadResult.value = res
        file.value = null // reset

    } catch (e: any) {
        console.error(e)
        alert('Upload Failed: ' + e.message)
    } finally {
        uploading.value = false
    }
}

// Migration Logic
const migrating = ref(false)
const migrationResult = ref<any>(null)

const handleMigration = async () => {
    if (!confirm('Tem certeza? Isso pode levar alguns segundos.')) return

    migrating.value = true
    migrationResult.value = null

    try {
        const res = await $fetch('/api/migration/bunny-to-r2', { method: 'POST' })
        migrationResult.value = res
    } catch (e: any) {
        console.error(e)
        alert('Erro na migração: ' + e.message)
    } finally {
        migrating.value = false
    }
}

// Migration Clinica Logic
const migratingClinica = ref(false)
const migrationClinicaResult = ref<any>(null)

const handleClinicaMigration = async () => {
    if (!confirm('Tem certeza? Isso migrará as Clínicas.')) return

    migratingClinica.value = true
    migrationClinicaResult.value = null

    try {
        const res = await $fetch('/api/migration/clinica-bunny-to-r2', { method: 'POST' })
        migrationClinicaResult.value = res
    } catch (e: any) {
        console.error(e)
        alert('Erro na migração: ' + e.message)
    } finally {
        migratingClinica.value = false
    }
}
</script>

<template>
    <div class="p-10 max-w-2xl mx-auto space-y-6">
        <h1 class="text-2xl font-bold text-white">Teste de Upload R2</h1>
        
        <div class="bg-div-15 p-6 rounded-xl border border-white/10 space-y-4">
            <input 
                type="file" 
                @change="onFileChange"
                class="block w-full text-sm text-secondary
                    file:mr-4 file:py-2 file:px-4
                    file:rounded-full file:border-0
                    file:text-xs file:font-semibold
                    file:bg-primary file:text-white
                    hover:file:bg-primary-dark
                "
            />
            
            <button 
                @click="handleUpload"
                :disabled="!file || uploading"
                class="px-6 py-2 bg-emerald-500 text-white rounded-lg font-bold disabled:opacity-50"
            >
                {{ uploading ? 'Enviando...' : 'Enviar para R2' }}
            </button>
        </div>

        <div v-if="uploadResult" class="bg-green-500/10 border border-green-500/20 p-4 rounded-xl text-green-300">
            <h3 class="font-bold mb-2">Sucesso!</h3>
            <pre class="text-xs overflow-auto">{{ uploadResult }}</pre>
        </div>

        <!-- MIGRATION SECTION -->
        <hr class="border-white/10" />
        
        <div class="space-y-4">
            <h2 class="text-xl font-bold text-white">Migração (Bunny -> R2)</h2>
            <p class="text-xs text-secondary">Isso irá baixar as fotos dos usuários do Bunny e subir para o R2.</p>
            
            <button 
                @click="handleMigration"
                :disabled="migrating"
                class="px-6 py-2 bg-blue-600 text-white rounded-lg font-bold disabled:opacity-50 hover:bg-blue-700 transition-colors"
            >
                {{ migrating ? 'Migrando...' : 'Iniciar Migração' }}
            </button>

            <div v-if="migrationResult" class="bg-div-15 border border-white/10 p-4 rounded-xl text-xs font-mono">
                <p>Total: {{ migrationResult.total }}</p>
                <p class="text-green-400">Sucesso: {{ migrationResult.migrated }}</p>
                <p class="text-red-400">Falhas: {{ migrationResult.failed }}</p>
                
                <div v-if="migrationResult.errors.length > 0" class="mt-2 text-red-300">
                    <p class="font-bold">Erros:</p>
                    <ul>
                        <li v-for="err in migrationResult.errors" :key="err">{{ err }}</li>
                    </ul>
                </div>
            </div>
        </div>

        <!-- MIGRATION CLINICA SECTION -->
        <hr class="border-white/10" />
        
        <div class="space-y-4">
            <h2 class="text-xl font-bold text-white">Migração Clínicas (Bunny -> R2)</h2>
            <p class="text-xs text-secondary">Isso irá baixar as logos das clínicas do Bunny e subir para o R2.</p>
            
            <button 
                @click="handleClinicaMigration"
                :disabled="migratingClinica"
                class="px-6 py-2 bg-purple-600 text-white rounded-lg font-bold disabled:opacity-50 hover:bg-purple-700 transition-colors"
            >
                {{ migratingClinica ? 'Migrando...' : 'Iniciar Migração Clínicas' }}
            </button>

            <div v-if="migrationClinicaResult" class="bg-div-15 border border-white/10 p-4 rounded-xl text-xs font-mono">
                <p>Total: {{ migrationClinicaResult.total }}</p>
                <p class="text-green-400">Sucesso: {{ migrationClinicaResult.migrated }}</p>
                <p class="text-red-400">Falhas: {{ migrationClinicaResult.failed }}</p>
                
                <div v-if="migrationClinicaResult.errors.length > 0" class="mt-2 text-red-300">
                    <p class="font-bold">Erros:</p>
                    <ul>
                        <li v-for="err in migrationClinicaResult.errors" :key="err">{{ err }}</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</template>
