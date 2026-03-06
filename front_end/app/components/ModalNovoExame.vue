<script setup lang="ts">
import { onMounted, watch, computed, ref } from 'vue';
import type { PropType } from 'vue';
import { useSupabaseUser } from '#imports';
import { useVVSExam } from '~/composables/useVVSExam';
import { sortearOrdemDirecao, gerarMedidasCondicao } from '~/utils/vvsExame';
import type { MedidaExame } from '~/utils/vvsExame';

const user = useSupabaseUser();

const props = defineProps({
    isOpen: {
        type: Boolean,
        required: true
    },
    patient: {
        type: [Object, null] as PropType<any | null>,
        default: null
    }
});

const emit = defineEmits(['close']);

const { 
    isConnectedToChannels, 
    pareamentoStatus, 
    controleTela,
    logs, 
    controleRemotoCancelar,
    condicoesExame,
    startPareamento, 
    enviarTela,
    avancarParaBoasVindas,
    fetchCondicoes,
    cleanup 
} = useVVSExam();

// Estado local do exame
const medidasAtuais = ref<MedidaExame[]>([]);
// 180 = posição neutra (exibido como 0°). Direita: +N, Esquerda: -N
const line_rotation = ref(180);
const head_rotation = ref(180);

// Controle de qual condição e medição estão ativas no momento
const condicaoAtiva = ref<number | null>(null);  // índice na lista condicoesExame
const medicaoAtiva = ref<number | null>(null);   // 0-3 dentro da condição

// Ouve disparos de cancelamento do Óculos/Mobile via WebSockets
watch(controleRemotoCancelar, (novoValor) => {
    if (novoValor > 0 && props.isOpen) {
        console.log('[VVS_DEBUG] Gatilho remoto de cancelar ativado! Fechando o modal.');
        closeModal();
    }
});

const closeModal = async () => {
    console.log('[VVS_DEBUG] Botão de fechar pressionado. Limpando canais ativamente antes de desmontar.');
    await cleanup();
    emit('close');
};

const formatTime = (isoString: string) => {
    if (!isoString) return '';
    return new Date(isoString).toLocaleTimeString();
};

const isPareado = computed(() => pareamentoStatus.value === 'pareado');

const handleMainAction = async () => {
    console.log('[VVS_DEBUG] handleMainAction chamado. controleTela:', controleTela.value);
    
    if (controleTela.value === 'parear') {
        const nomePaciente = props.patient?.nome_completo || 'Paciente';
        console.log('[VVS_DEBUG] Chamando avancarParaBoasVindas com:', nomePaciente);
        avancarParaBoasVindas(undefined, nomePaciente);
    } else if (controleTela.value === 'boasvindas') {
        console.log('[VVS_DEBUG] Avançando para etapa de Ajuste de Foco.');
        controleTela.value = 'foco';
        enviarTela(undefined, 'foco');
    } else if (controleTela.value === 'foco') {
        console.log('[VVS_DEBUG] Avançando para etapa de Sobreposição.');
        controleTela.value = 'sobreposicao';
        enviarTela(undefined, 'sobreposicao');
    } else if (controleTela.value === 'sobreposicao') {
        console.log('[VVS_DEBUG] Avançando para etapa de Aguardando / Pre-Setup.');
        
        // 1. Atualiza estado local e envia payload ao VR
        controleTela.value = 'aguardando';
        enviarTela(undefined, 'aguardando');
        
        // 2. Garante condições carregadas e gera medidas da condição neutra
        await fetchCondicoes();
        const condicaoNeutra = condicoesExame.value.find((c: any) => c.nome === 'neutra');
        if (condicaoNeutra) {
            const ordem = sortearOrdemDirecao();
            medidasAtuais.value = gerarMedidasCondicao(condicaoNeutra, ordem);
            console.log('[VVS_DEBUG] Medidas da condição neutra geradas:', medidasAtuais.value);
        }
    }
};

</script>

<template>
     <div v-if="isOpen" class="fixed inset-x-0 -top-[32px] bottom-0 z-[100] flex flex-col bg-background font-sans text-text">
            
            <!-- Header -->
        <header class="flex items-center justify-between px-6 py-4 bg-div-15 border-b border-secondary/10 shrink-0">
             <div class="flex items-center gap-4">
                 <h1 class="text-xl font-bold text-text tracking-widest uppercase">Exame de VVS</h1>
                 <div class="h-6 w-px bg-secondary/10"></div>
                 <div v-if="patient" class="flex items-center gap-2">
                     <div class="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-sm">
                         {{ patient.nome_completo ? patient.nome_completo.charAt(0) : 'P' }}
                     </div>
                     <div>
                         <p class="text-sm font-semibold text-text leading-tight">{{ patient.nome_completo }}</p>
                         <p class="text-xs text-secondary">Paciente</p>
                     </div>
                 </div>
             </div>

             <div class="flex items-center gap-6">
                <button 
                   @click="handleMainAction" 
                   class="px-5 py-2 min-w-40 bg-primary hover:bg-primary-dark text-white rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2 shadow-lg shadow-primary/20"
                >
                  <svg class="w-4 h-4" v-if="controleTela === 'parear'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
                  <svg class="w-4 h-4" v-else fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7"></path></svg>
                  {{ controleTela === 'parear' ? 'Parear Dispositivo' : 'Avançar' }}
               </button>

                <div class="h-6 w-px bg-secondary/20"></div>

                <!-- Connection Status -->
                <div class="flex items-center gap-2 bg-div-30 px-3 py-1.5 rounded-full border border-secondary/10 shadow-sm">
                    <span class="relative flex h-3 w-3">
                      <span v-if="isPareado" class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                      <span 
                          class="relative inline-flex rounded-full h-3 w-3"
                          :class="[isPareado ? 'bg-emerald-500' : 'bg-warning']"
                      ></span>
                    </span>
                    <span class="text-xs font-bold tracking-widest uppercase" :class="isPareado ? 'text-emerald-400' : 'text-warning'">
                        {{ isPareado ? 'Pareado' : 'Aguardando Pareamento' }}
                    </span>
                </div>

                <button @click="closeModal" class="p-2 hover:bg-danger/10 hover:text-danger text-secondary rounded-lg transition-colors flex items-center gap-2 text-sm font-medium">
                     <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                     Cancelar / Fechar
                </button>
             </div>
        </header>

        <!-- Main Content -->
        <div class="flex-1 relative flex flex-col items-center justify-center p-8 lg:p-12 overflow-hidden bg-background">
            
            <!-- Instruções por etapa -->
            <div v-if="controleTela === 'parear'" class="mb-10 text-center max-w-2xl">
                 <h2 class="text-2xl font-bold tracking-widest uppercase text-text mb-4">Conecte o Dispositivo VR</h2>
                 <p class="text-secondary text-sm">Abra o aplicativo Otolithics no celular, faça login e acesse a tela de pareamento. O sistema sincronizará automaticamente quando as credenciais baterem.</p>
            </div>
            <div v-else-if="controleTela === 'boasvindas'" class="mb-10 text-center max-w-2xl">
                 <h2 class="text-2xl font-bold tracking-widest uppercase text-text mb-4">Acomode a Máscara</h2>
                 <p class="text-warning text-sm font-medium">Acomode a máscara no rosto do cliente antes de dar início ao exame.<br>Certifique-se de que está confortável, sem vazar luz externa, e foca nitidamente na tela. Em seguida clique em "Avançar".</p>
            </div>
            <div v-else-if="controleTela === 'foco'" class="mb-10 text-center max-w-2xl">
                 <h2 class="text-2xl font-bold tracking-widest uppercase text-text mb-4">Ajuste de Foco</h2>
                 <p class="text-secondary text-sm">Peça para o paciente ajustar as lentes até que a imagem na tela esteja nítida. Em seguida clique em "Avançar".</p>
            </div>
            <div v-else-if="controleTela === 'sobreposicao'" class="mb-10 text-center max-w-2xl">
                 <h2 class="text-2xl font-bold tracking-widest uppercase text-text mb-4">Calibração de Sobreposição</h2>
                 <p class="text-warning text-sm font-medium">Instrua o paciente: Há uma esfera azul de um lado e uma vermelha do outro. <br/>Eles devem visualizar <b>apenas uma única esfera roxa</b> no centro. Quando confirmarem, clique em "Avançar".</p>
            </div>

                 
            <!-- Simulator Frame (para etapas com imagem mobile) -->
            <div
                v-if="controleTela !== 'aguardando'"
                class="relative w-full max-w-4xl aspect-[16/9] bg-[#1A1A23] rounded-[2rem] border border-secondary/20 shadow-2xl overflow-hidden flex items-center justify-center"
            >
                <div v-if="controleTela === 'parear'" class="relative w-full h-full flex items-center justify-center">
                     <img src="https://otolithics-p.b-cdn.net/tela_parear_mobile_nxt.png" alt="Tela Parear Mobile" class="w-full h-full object-contain pointer-events-none select-none p-4" />
                </div>
                <div v-else-if="controleTela === 'boasvindas'" class="relative w-full h-full flex items-center justify-center">
                     <img src="https://otolithics-p.b-cdn.net/tela_bem_vindo_mobile.png" alt="Tela Bem Vindo Mobile" class="w-full h-full object-contain pointer-events-none select-none p-4" />
                </div>
                <div v-else-if="controleTela === 'foco'" class="relative w-full h-full flex items-center justify-center">
                     <img src="https://otolithics-p.b-cdn.net/tela_foco_mobile.png" alt="Tela de Foco Mobile" class="w-full h-full object-contain pointer-events-none select-none p-4" />
                </div>
                <div v-else-if="controleTela === 'sobreposicao'" class="relative w-full h-full flex items-center justify-center">
                     <img src="https://otolithics-p.b-cdn.net/tela_sobrepor_mobile.gif" alt="Tela de Sobreposição Mobile" class="w-full h-full object-contain pointer-events-none select-none p-4" />
                </div>
            </div>

            <!-- Painel de Instrumentos (apenas na etapa 'aguardando') -->
            <div v-if="controleTela === 'aguardando'" class="w-full flex gap-6">

                <!-- Instrumento 1: Transferidor de Linha -->
                <div class="flex-1 flex flex-col items-center gap-3">
                    <div
                        class="relative w-full bg-white/90 border border-secondary/20 rounded-2xl overflow-hidden"
                        style="aspect-ratio: 2/1; min-height: 200px;"
                    >
                        <!-- Fundo: transferidor -->
                        <img
                            src="https://otolithics-p.b-cdn.net/transferidor_oto.png"
                            alt="Transferidor"
                            class="absolute inset-0 w-full h-full object-contain pointer-events-none select-none p-3"
                        />
                        <!-- Linha com pivot no eixo inferior central -->
                        <div
                            class="absolute bottom-[10%] left-1/2 origin-bottom transition-transform duration-500 ease-out"
                            :style="{ transform: `translateX(-50%) rotate(${line_rotation - 180}deg)`, height: '55%' }"
                        >
                            <div class="w-[3px] h-full bg-primary rounded-t-full shadow-lg shadow-primary/60"></div>
                            <!-- Ponto de pivô -->
                            <div class="w-4 h-4 rounded-full bg-primary/30 border-2 border-primary absolute -bottom-2 -left-[7px]"></div>
                        </div>
                    </div>
                    <span class="px-5 py-1.5 bg-div-15 rounded-full border border-secondary/10 text-sm font-bold tracking-widest text-secondary tabular-nums">
                        {{ line_rotation - 180 }}°
                    </span>
                </div>

                <!-- Instrumento 2: Posição da Cabeça -->
                <div class="flex-1 flex flex-col items-center gap-3">
                    <div
                        class="relative w-full bg-white/90 border border-secondary/20 rounded-2xl overflow-hidden"
                        style="aspect-ratio: 2/1; min-height: 200px;"
                    >
                        <!-- Fundo: semicírculo do transferidor de cabeça -->
                        <img
                            src="https://otolithics-p.b-cdn.net/transferidor_cabeca.png"
                            alt="Transferidor Cabeça"
                            class="absolute inset-0 w-full h-full object-contain pointer-events-none select-none p-3"
                        />
                        <!-- Cabeça com pivot no eixo inferior central -->
                        <div
                            class="absolute bottom-[10%] left-1/2 origin-bottom transition-transform duration-500 ease-out"
                            :style="{ transform: `translateX(-50%) rotate(${head_rotation - 180}deg)`, height: '60%' }"
                        >
                            <img
                                src="https://otolithics-p.b-cdn.net/cabeca_posicao.png"
                                alt="Posição da Cabeça"
                                class="h-full w-auto select-none pointer-events-none"
                            />
                        </div>
                    </div>
                    <span class="px-5 py-1.5 bg-div-15 rounded-full border border-secondary/10 text-sm font-bold tracking-widest text-secondary tabular-nums">
                        {{ head_rotation - 180 }}°
                    </span>
                </div>

            </div>

            <!-- Grade de Condições de Exame -->
            <div v-if="controleTela === 'aguardando'" class="w-full mt-6 overflow-x-auto custom-scrollbar">
                <table class="w-full min-w-[900px] border-separate" style="border-spacing: 0 6px;">
                    <!-- Cabeçalho -->
                    <thead>
                        <tr class="text-xs font-bold tracking-widest uppercase text-secondary">
                            <th class="text-left px-4 py-2 w-48">Condição</th>
                            <th class="text-center px-3 py-2" v-for="n in 4" :key="n">Medição {{ n }}</th>
                            <th class="text-center px-3 py-2 text-primary/80">Médias</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr
                            v-for="(cond, idx) in condicoesExame"
                            :key="cond.id"
                            class="transition-all duration-300"
                        >
                            <!-- Célula da Condição -->
                            <td class="py-1 pr-2">
                                <div
                                    class="flex items-center gap-3 px-3 py-2.5 rounded-xl border-2 transition-all duration-300"
                                    :class="condicaoAtiva === idx
                                        ? 'border-primary bg-primary/10 shadow-lg shadow-primary/20 condition-pulse'
                                        : 'border-secondary/10 bg-div-10'"
                                >
                                    <span
                                        class="flex-shrink-0 w-4 h-4 rounded-full border-2 transition-colors duration-300"
                                        :class="condicaoAtiva === idx ? 'border-primary bg-primary' : 'border-secondary/30 bg-transparent'"
                                    ></span>
                                    <span class="text-xs font-semibold truncate" :class="condicaoAtiva === idx ? 'text-text' : 'text-secondary'">{{ cond.label }}</span>
                                </div>
                            </td>

                            <!-- Células de Medição (1-4) -->
                            <td v-for="m in 4" :key="m" class="py-1 px-1">
                                <div
                                    class="flex items-center gap-1.5 px-2.5 py-2 rounded-lg border-2 transition-all duration-300"
                                    :class="condicaoAtiva === idx && medicaoAtiva === (m - 1)
                                        ? 'border-primary bg-primary/10 shadow-md shadow-primary/20 measurement-pulse'
                                        : condicaoAtiva === idx
                                            ? 'border-secondary/20 bg-div-15'
                                            : 'border-secondary/10 bg-div-10'"
                                >
                                    <span class="text-[10px] font-bold tracking-wide" :class="condicaoAtiva === idx ? 'text-secondary' : 'text-secondary/40'">
                                        {{ ['ANGD', 'ANGD', 'ANGD', 'ANGD', 'ANGD', 'HTPG', 'HTPG'][idx] }}
                                    </span>
                                    <span class="flex-1 text-center text-xs font-bold tabular-nums" :class="condicaoAtiva === idx && medicaoAtiva === (m - 1) ? 'text-primary' : 'text-secondary/50'">
                                        &mdash;
                                    </span>
                                    <span class="text-[10px] text-secondary/40">°</span>
                                </div>
                            </td>

                            <!-- Célula de Médias -->
                            <td class="py-1 pl-2">
                                <div
                                    class="flex items-center gap-1.5 px-2.5 py-2 rounded-xl border-2 transition-all duration-300"
                                    :class="condicaoAtiva === idx ? 'border-primary/30 bg-primary/5' : 'border-secondary/10 bg-div-10'"
                                >
                                    <span class="text-[10px] font-bold text-primary/60">MD</span>
                                    <span class="text-xs font-bold tabular-nums text-secondary/50">&mdash;</span>
                                    <span class="text-[10px] text-secondary/30">°</span>
                                    <span class="mx-1 text-secondary/20">/</span>
                                    <span class="text-[10px] font-bold text-primary/40">MND</span>
                                    <span class="text-xs font-bold tabular-nums text-secondary/50">&mdash;</span>
                                    <span class="text-[10px] text-secondary/30">°</span>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

        </div>
     </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--color-secondary-rgb), 0.1);
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

/* Pulso suave da borda quando condição está ativa */
@keyframes conditionPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(var(--color-primary-rgb), 0.4); }
  50%       { box-shadow: 0 0 0 6px rgba(var(--color-primary-rgb), 0); }
}
.condition-pulse {
  animation: conditionPulse 2s ease-in-out infinite;
}

/* Pulso mais intenso para a célula de medição ativa */
@keyframes measurementPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(var(--color-primary-rgb), 0.6); }
  50%       { box-shadow: 0 0 0 4px rgba(var(--color-primary-rgb), 0); }
}
.measurement-pulse {
  animation: measurementPulse 1s ease-in-out infinite;
}
</style>
