<script setup lang="ts">
const store = useAppStore()
</script>

<template>
  <div class="min-h-screen flex items-center justify-center bg-[#0a0a0c] p-6 font-sans relative overflow-hidden">
    
    <!-- Background Accents -->
    <div class="absolute inset-0 pointer-events-none">
        <div class="absolute top-[-10%] left-[-5%] w-[600px] h-[600px] bg-primary/20 rounded-full blur-[180px]"></div>
        <div class="absolute bottom-[0%] right-[-10%] w-[500px] h-[500px] bg-primary/15 rounded-full blur-[150px]"></div>
    </div>

    <div class="w-full max-w-md relative z-10">
        
        <!-- Card -->
        <div class="bg-div-15 backdrop-blur-2xl border border-white/5 rounded-[2.5rem] p-8 md:p-12 shadow-2xl text-center">
            
            <div class="flex flex-col items-center mb-8">
                <div class="mb-6">
                    <img src="https://spedppull.b-cdn.net/site/logosp.png" alt="Logo SPED" class="h-20 w-auto object-contain" />
                </div>
                
                <h1 class="text-2xl font-black text-white uppercase tracking-[0.2em]">
                    {{ store.statusMessage.title || 'Mensagem' }}
                </h1>
            </div>

            <div class="bg-white/5 border border-white/10 rounded-xl p-6 mb-8">
                 <p class="text-sm font-bold text-white/80 leading-relaxed">
                    {{ store.statusMessage.message || 'Nenhuma mensagem para exibir.' }}
                </p>
            </div>

            <div v-if="store.statusMessage.actionPath">
                <NuxtLink 
                    :to="store.statusMessage.actionPath" 
                    class="inline-block w-full bg-primary text-white font-black py-4 rounded-xl text-sm uppercase tracking-[0.2em] shadow-lg shadow-primary/20 hover:bg-[#b81151] hover:shadow-primary/40 hover:-translate-y-0.5 transition-all"
                >
                    {{ store.statusMessage.actionLabel || 'Continuar' }}
                </NuxtLink>
            </div>
            <div v-else>
                 <NuxtLink 
                    to="/" 
                    class="inline-block w-full bg-white/10 text-white font-black py-4 rounded-xl text-sm uppercase tracking-[0.2em] hover:bg-white/20 transition-all"
                >
                    Voltar ao Início
                </NuxtLink>
            </div>

        </div>

    </div>
  </div>
</template>
