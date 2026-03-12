<script setup lang="ts">
import { onMounted, watch, computed, ref } from 'vue';
import type { PropType } from 'vue';
import { useSupabaseUser } from '#imports';
import { useVVSExam } from '~/composables/useVVSExam';
import { sortearOrdemDirecao, gerarMedidasCondicao } from '~/utils/vvsExame';
import type { MedidaExame } from '~/utils/vvsExame';

const user = useSupabaseUser();
const appStore = useAppStore();

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

const emit = defineEmits(['close', 'saved', 'view-report']);

const exameSalvoId = ref<string | null>(null);

const { 
    isConnectedToChannels, 
    pareamentoStatus, 
    controleTela,
    logs, 
    controleRemotoCancelar,
    condicoesExame,
    lastAngleData,
    startPareamento, 
    enviarTela,
    avancarParaBoasVindas,
    fetchCondicoes,
    cleanup,
    logMessage,
    iniciarTrackingVR,
    ajustarAnguloVR,
    pararTrackingVR
} = useVVSExam();

// Estado local do exame - Armazena as 4 medições para cada uma das 7 condições
// Estrutura: { [condicao_id]: [m1, m2, m3, m4] }
const resultadosExame = ref<Record<string, (number | null)[]>>({});

// Inicializa a matriz de resultados quando as condições são carregadas
watch(condicoesExame, (novas) => {
    if (novas && novas.length > 0) {
        novas.forEach(c => {
            if (!resultadosExame.value[c.id]) {
                resultadosExame.value[c.id] = [null, null, null, null];
            }
        });
    }
}, { immediate: true });

// Estado local do exame
const medidasAtuais = ref<MedidaExame[]>([]);
// 180 = posição neutra (exibido como 0°). Direita: +N, Esquerda: -N
const line_rotation = ref(180);
const head_rotation = ref(180);

// Ordenação fixa das condições de exame conforme print
const ordemCondicoes = [
    'neutra',
    'estatica_direita',
    'estatica_esquerda',
    'dinamica_antihorario',
    'dinamica_horario',
    'haptica_direita',
    'haptica_esquerda'
];

const condicoesOrdenadas = computed(() => {
    if (!condicoesExame.value.length) return [];
    return [...condicoesExame.value].sort((a, b) => {
        const idxA = ordemCondicoes.indexOf(a.nome.toLowerCase());
        const idxB = ordemCondicoes.indexOf(b.nome.toLowerCase());
        return idxA - idxB;
    });
});

const CABECA_IMAGEM_EXATA = 'https://otolithics-p.b-cdn.net/cabeca_posicao_exata.png';
const CABECA_IMAGEM_JANELA = 'https://otolithics-p.b-cdn.net/cabeca_posicao.png';
const CABECA_IMAGEM_FORA = 'https://otolithics-p.b-cdn.net/posicao_cabeca_false.png';

// Controle de qual condição e medição estão ativas no momento
const condicaoAtiva = ref<number | null>(null);  // índice na lista condicoesExame
const medicaoAtiva = ref<number | null>(null);   // 0-3 dentro da condição
const isMedindo = ref(false); // VR Tracking Ativo
const stepSize = ref(0.1); // Passo padrão de 0.1 graus

const isSaving = ref(false);

const resetEstadoLocalExame = () => {
    exameSalvoId.value = null;
    resultadosExame.value = {};
    medidasAtuais.value = [];
    condicaoAtiva.value = null;
    medicaoAtiva.value = null;
    isMedindo.value = false;
    isSaving.value = false;
    stepSize.value = 0.1;
    line_rotation.value = 180;
    head_rotation.value = 180;
};

const isExameCompleto = computed(() => {
    if (!condicoesExame.value || condicoesExame.value.length === 0) return false;
    return condicoesExame.value.every(c => {
        const meds = resultadosExame.value[c.id];
        return meds && meds.filter(m => m !== null).length === 4;
    });
});

const condicaoAtualParaCabeca = computed(() => {
    if (!condicoesOrdenadas.value.length) return null;
    if (condicaoAtiva.value === null) return condicoesOrdenadas.value[0];
    return condicoesOrdenadas.value[condicaoAtiva.value] || null;
});

const imagemCabecaAtual = computed(() => {
    const condicao = condicaoAtualParaCabeca.value;
    if (!condicao) return CABECA_IMAGEM_JANELA;

    const ideal = Number(condicao.aidealcab);
    const minimo = Number(condicao.amincab);
    const maximo = Number(condicao.amaxcab);
    const anguloAtual = Number(head_rotation.value);

    if ([ideal, minimo, maximo, anguloAtual].some(v => Number.isNaN(v))) {
        return CABECA_IMAGEM_JANELA;
    }

    if (Math.abs(anguloAtual - ideal) <= 0.1) {
        return CABECA_IMAGEM_EXATA;
    }

    if (anguloAtual >= minimo && anguloAtual <= maximo) {
        return CABECA_IMAGEM_JANELA;
    }

    return CABECA_IMAGEM_FORA;
});

const podeRegistrarMedida = computed(() => imagemCabecaAtual.value !== CABECA_IMAGEM_FORA);

// Ouve disparos de cancelamento do Óculos/Mobile via WebSockets
watch(controleRemotoCancelar, (novoValor) => {
    if (novoValor > 0 && props.isOpen) {
        console.log('[VVS_DEBUG] Gatilho remoto de cancelar ativado! Fechando o modal.');
        closeModal();
    }
});

// Sincroniza a rotação visual com os dados de giro recebidos
watch(lastAngleData, (data) => {
    if (data) {
        head_rotation.value = data.head;
        // line_rotation agora é controlado localmente pelo médico (Setas) e sincronizado no VR,
        // portanto não atualizamos a linha visual pelos dados recebidos.
    }
}, { deep: true });

// Controle da linha via Teclado com suporte ao Mini Teclado 3 Botões (A, B, C)
const handleKeyDown = (e: KeyboardEvent) => {
    if (!props.isOpen || controleTela.value !== 'aguardando' || !isMedindo.value) return;

    const key = e.key.toLowerCase();
    
    // Botão Central do mini teclado (ou Barra de Espaço) -> Alternar velocidade do passo
    if (key === 'b' || e.code === 'Space') {
        e.preventDefault();
        stepSize.value = stepSize.value === 0.1 ? 1 : 0.1;
        return; // Não envia ajuste de rotação
    }
    
    // Botão Direito / Esquerdo
    if (key === 'c' || key === 'a' || e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
        e.preventDefault();
        
        // A / Seta Direita -> Incrementa
        if (key === 'c' || e.key === 'ArrowRight') {
            line_rotation.value = parseFloat((line_rotation.value + stepSize.value).toFixed(1));
        } 
        // C / Seta Esquerda -> Decrementa
        else if (key === 'a' || e.key === 'ArrowLeft') {
            line_rotation.value = parseFloat((line_rotation.value - stepSize.value).toFixed(1));
        }
        
        // Dispara o novo valor para o VR espelhar instantaneamente
        ajustarAnguloVR(line_rotation.value);
    }
};

onMounted(() => {
    window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
    window.removeEventListener('keydown', handleKeyDown);
});

const closeModal = async () => {
    console.log('[VVS_DEBUG] Botão de fechar pressionado. Limpando canais ativamente antes de desmontar.');

    // Segurança extra: se cancelar no meio da medição, encerra tracking imediatamente.
    await pararTrackingVR();
    await cleanup();

    // Resetar memórias locais para o próximo paciente
    resetEstadoLocalExame();
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
        
        // 2. Garante condições carregadas do backend
        await fetchCondicoes();
        // Não geramos nada aqui. Apenas aguardamos o botão Iniciar Exame.
        condicaoAtiva.value = null;
        medicaoAtiva.value = null;
        medidasAtuais.value = [];
        resultadosExame.value = {};
        console.log('[VVS_DEBUG] Tela aguardando pronta, dados de condições no state.');
    }
};

const obterTelaExamePorCondicao = (nomeCondicao: string) => {
    const nomeLower = nomeCondicao.toLowerCase();
    let telaNome = 'examenormal';

    if (nomeLower.includes('dinâmica') || nomeLower.includes('dinamica')) {
        if (nomeLower.includes('anti')) {
            telaNome = 'examedinamicaamtihorario';
        } else {
            telaNome = 'examedinamicahorario';
        }
    }

    return telaNome;
};

const iniciarCondicaoAction = () => {
    // Se for o painel muito inicial (ainda sem exibir nenhuma condição formalmente ativa)
    if (condicaoAtiva.value === null) {
        condicaoAtiva.value = 0;
    }

    const condicao = condicoesOrdenadas.value[condicaoAtiva.value];
    
    if (condicao) {
        // Ao iniciar uma nova condição, garante que o VR volte para a tela de exame.
        const telaNome = obterTelaExamePorCondicao(condicao.nome);
        enviarTela(undefined, telaNome);

        // 1. Sorteia uma das ordens (ex: Direita, Direita, Esquerda, Esquerda)
        const ordem = sortearOrdemDirecao();
        
        // 2. Transforma as matrizes base do banco em 4 ângulos aleatórios já validados para o paciente
        medidasAtuais.value = gerarMedidasCondicao(condicao, ordem);
        
        console.log(`[VVS_DEBUG] ----> LISTA DE 4 MEDIÇÕES GERADA (Condição Inicial: ${condicao.nome}): `, medidasAtuais.value);
        logMessage('System', { text: `Iniciando condição ${condicao.label}. Sequência de ângulos gerada.` });

        // 3. Marca que a primeira medida desta condição está pronta para ser iniciada
        medicaoAtiva.value = 0;
        isMedindo.value = false; // Preparado, mas aguardando o clique explicitamente para "Iniciar Medição"

    } else {
        console.warn(`[VVS_DEBUG] Condição ativa inválida ou não encontrada na matriz de condições!`);
        logMessage('Erro', { text: 'Condição ativa ausente nos dados do banco.' });
    }
};

const iniciarMedicaoVRAction = () => {
    if (condicaoAtiva.value === null || medicaoAtiva.value === null) return;
    
    const condicao = condicoesOrdenadas.value[condicaoAtiva.value];
    if (!condicao) return;
    
    // 1. Determina qual tela o VR deve carregar
    const telaNome = obterTelaExamePorCondicao(condicao.nome);
    
    // 2. Envia visual / comando de tela
    enviarTela(undefined, telaNome);
    
    // 3. Pega o ângulo sorteado gerado matematicamente
    const anguloSorteado = medidasAtuais.value[medicaoAtiva.value]?.angulo ?? 180;
    line_rotation.value = anguloSorteado;
    
    // 4. Inicia Tracking de Giroscópio e Posicionamento VR
    iniciarTrackingVR(anguloSorteado);
    isMedindo.value = true;
};

const capturarMedida = async () => {
    if (condicaoAtiva.value === null || medicaoAtiva.value === null || !isMedindo.value) return;
    if (!podeRegistrarMedida.value) {
        logMessage('Exam Flow', { text: 'Ajuste a posição da cabeça antes de registrar a medida.' });
        return;
    }
    
    const condicao = condicoesOrdenadas.value[condicaoAtiva.value];
    if (!condicao) return;
    
    // Captura o valor atual (corrigindo para a escala de 0 central)
    const valorCapturado = parseFloat((line_rotation.value - 180).toFixed(1));
    
    if (!resultadosExame.value[condicao.id]) {
        resultadosExame.value[condicao.id] = [null, null, null, null];
    }
    
    const base = resultadosExame.value[condicao.id];
    if (base) {
        base[medicaoAtiva.value] = valorCapturado;
    }
    console.log(`[VVS_DEBUG] Medida capturada: ${valorCapturado}° na condição ${condicao.nome}`);

    // Como salvamos a captura, desligamos o fluxo de WebSockets Pesados até a próxima medida.
    await pararTrackingVR();
    isMedindo.value = false;

    // Avança para a próxima medição
    if (medicaoAtiva.value < 3) {
        medicaoAtiva.value++;
    } else {
        // Fim das 4 medições desta condição -> Avança para próxima condição e esvazia o estado
        if (condicaoAtiva.value < condicoesOrdenadas.value.length - 1) {
            // Ao finalizar uma condição, envia a tela de aguardando para o VR.
            controleTela.value = 'aguardando';
            enviarTela(undefined, 'aguardando');

            condicaoAtiva.value++;
            medicaoAtiva.value = null; // Trava aqui em Null para forçar o botão "Iniciar Condição" aparecer novamente
            medidasAtuais.value = []; // Limpa sujeira anterior
            
            const proxCond = condicoesOrdenadas.value[condicaoAtiva.value];
            logMessage('Exam Flow', { text: `Aguardando permissão para iniciar a condição: ${proxCond.label}` });
        } else {
            // Fim de todas as condições - Mantemos em 'aguardando' para exibir o botão Salvar Exame
            console.log('[VVS_DEBUG] Fim de todas as repetições! Exibindo painel de Salvar Exame.');
            enviarTela(undefined, 'parear'); // Volta pra tela inicial no VR
        }
    }
};

const reiniciarExame = () => {
    if (!confirm('Deseja descartar todos os resultados e reiniciar o exame a partir do zero?')) return;
    resetEstadoLocalExame();
};

// Cálculo de MD (Média dos Desvios)
// Formula: Média Direcional return (ang1 + ang2 + ang3 + ang4) / 4;
const calcularMD = (condId: string) => {
    const meds = resultadosExame.value[condId];
    if (!meds) return '—';
    const validas = meds.filter(m => m !== null) as number[];
    if (validas.length === 0) return '—';
    const soma = validas.reduce((a, b) => a + b, 0);
    return (soma / validas.length).toFixed(1);
};

// Cálculo de MND (Média Numérica/Não-Direcional Absoluta)
// Formula: MédiaNão Dircional return (Math.abs(ang1) + Math.abs(ang2) + Math.abs(ang3) + Math.abs(ang4)) / 4;
const calcularMND = (condId: string) => {
    const meds = resultadosExame.value[condId];
    if (!meds) return '—';
    const validas = meds.filter(m => m !== null) as number[];
    if (validas.length === 0) return '—';
    const somaAbsoluta = validas.reduce((a, b) => a + Math.abs(b), 0);
    return (somaAbsoluta / validas.length).toFixed(1);
};

const formatarMedidaTabela = (valor: number | null | undefined) => {
    if (valor === null || valor === undefined) return '—';
    return valor.toFixed(1);
};

const salvarExame = async () => {
    if (!isExameCompleto.value || !props.patient || !appStore.company?.id) return;
    
    isSaving.value = true;
    try {
        const payloadCondicoes = condicoesExame.value.map(c => {
            const meds = resultadosExame.value[c.id] || [];
            return {
                id_condicao: c.id,
                m1: meds[0] ?? 0,
                m2: meds[1] ?? 0,
                m3: meds[2] ?? 0,
                m4: meds[3] ?? 0,
                md: parseFloat(calcularMD(c.id)),
                mnd: parseFloat(calcularMND(c.id))
            };
        });

        const response = await $fetch('/api/vvs/exame', {
            method: 'POST',
            body: {
                id_paciente: props.patient.id,
                id_clinica: appStore.company.id,
                id_user_expandido: appStore.user_expandido_id,
                condicoes: payloadCondicoes
            }
        }) as any;

        if (response && response.sucesso) {
            console.log('[VVS_BFF] Exame salvo com sucesso. ID:', response.id_exame);
            exameSalvoId.value = response.id_exame;
            controleTela.value = 'salvo';
            emit('saved', response.id_exame); // Avise o pai para recarregar a lista silenciosamente
        } else {
            throw new Error('Retorno inconsistente da API');
        }
    } catch (e) {
        console.error('[VVS_BFF] Erro ao salvar exame:', e);
        // Fallback em caso de erro, idealmente um Toast seria melhor
        alert('Ocorreu um erro ao salvar os dados do exame.');
    } finally {
        isSaving.value = false;
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
                <!-- Botões para etapas Iniciais -->
                <button 
                   v-if="controleTela !== 'aguardando'"
                   @click="handleMainAction" 
                   class="px-5 py-2 min-w-40 bg-primary hover:bg-primary-dark text-white rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2 shadow-lg shadow-primary/20"
                >
                  <svg class="w-4 h-4" v-if="controleTela === 'parear'" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 0 00-5.656-5.656l-1.1 1.1"></path></svg>
                  <svg class="w-4 h-4" v-else fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7"></path></svg>
                  {{ controleTela === 'parear' ? 'Parear Dispositivo' : 'Avançar' }}
               </button>

                <!-- Botão 1 da etapa aguardando (Start Condição Inteira) -->
                <button 
                   v-if="controleTela === 'aguardando' && medicaoAtiva === null && !isExameCompleto"
                   @click="iniciarCondicaoAction" 
                   class="px-5 py-2 min-w-40 bg-emerald-500 hover:bg-emerald-600 text-white rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2 shadow-lg shadow-emerald-500/20"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                  Iniciar Condição: {{ condicoesOrdenadas[condicaoAtiva ?? 0]?.label }}
               </button>

               <!-- Botão 2 da etapa aguardando (Iniciar Ciclo de Medição e Tracking VR) -->
                <button 
                   v-if="controleTela === 'aguardando' && medicaoAtiva !== null && !isMedindo && !isExameCompleto"
                   @click="iniciarMedicaoVRAction" 
                   class="px-5 py-2 min-w-40 bg-indigo-500 hover:bg-indigo-600 text-white rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2 shadow-lg shadow-indigo-500/20"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                  Iniciar Medição {{ medicaoAtiva + 1 }}
               </button>

               <!-- Botão 3 da etapa aguardando (Registrar Medida já no fluxo do exame) -->
                <button 
                   v-if="controleTela === 'aguardando' && medicaoAtiva !== null && isMedindo && !isExameCompleto"
                   @click="capturarMedida" 
                         :disabled="!podeRegistrarMedida"
                         class="px-5 py-2 min-w-40 rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2 shadow-lg disabled:cursor-not-allowed disabled:bg-secondary/30 disabled:text-secondary/60 disabled:shadow-none"
                         :class="podeRegistrarMedida ? 'bg-primary hover:bg-primary-dark text-white shadow-primary/20' : 'bg-secondary/30 text-secondary/60'"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                        {{ podeRegistrarMedida ? `Registrar Medida ${medicaoAtiva + 1}` : 'Corrigir Cabeça' }}
               </button>

               <!-- Botão Reiniciar Exame (aparece quando o exame termina caso o usuário queira recomeçar do zero) -->
                <button 
                   v-if="controleTela === 'aguardando' && isExameCompleto"
                   @click="reiniciarExame" 
                   class="px-5 py-2 min-w-40 bg-transparent hover:bg-secondary/10 border border-secondary/50 text-secondary rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                  Reiniciar Exame
               </button>

               <!-- Botão 4 da etapa aguardando (Salvar Exame) -->
                <button 
                   v-if="controleTela === 'aguardando' && isExameCompleto"
                   @click="salvarExame" 
                   :disabled="isSaving"
                   class="px-5 py-2 min-w-40 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-bold uppercase tracking-widest transition-colors flex items-center justify-center gap-2 shadow-lg shadow-emerald-500/20 disabled:opacity-50"
                >
                  <svg v-if="isSaving" class="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                  <svg v-else class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                  {{ isSaving ? 'Salvando...' : 'Salvar Exame' }}
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
                
                <!-- Etapa: Exame Salvo (Tela de Sucesso Final) -->
                <div v-else-if="controleTela === 'salvo'" class="relative w-full h-full flex flex-col items-center justify-center p-10 text-center">
                     <div class="w-24 h-24 bg-emerald-500/10 rounded-full flex items-center justify-center mb-6 border-4 border-emerald-500/30">
                          <svg class="w-12 h-12 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                     </div>
                     <h2 class="text-3xl font-bold tracking-widest uppercase text-white mb-4">Exame Salvo!</h2>
                     <p class="text-secondary text-base mb-10 max-w-md">O exame de VVS foi finalizado e salvo com segurança em nosso banco de dados. Você já pode visualizar o relatório completo dele.</p>
                     
                     <div class="flex items-center gap-6">
                         <button 
                             @click="emit('view-report', exameSalvoId); closeModal()" 
                             class="px-8 py-4 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-sm font-bold uppercase tracking-widest transition-colors flex items-center gap-3 shadow-lg shadow-emerald-500/30"
                         >
                             <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path></svg>
                             Ver Exame
                         </button>
                         <button 
                             @click="closeModal" 
                             class="px-8 py-4 bg-white/5 hover:bg-white/10 text-white rounded-xl border border-white/10 text-sm font-bold uppercase tracking-widest transition-colors flex items-center gap-3"
                         >
                             Concluir
                         </button>
                     </div>
                </div>
            </div>

            <!-- Painel de Instrumentos (apenas na etapa 'aguardando' e se o exame não estiver completo) -->
            <div v-if="controleTela === 'aguardando' && !isExameCompleto" class="w-full flex gap-6">

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
                            class="absolute bottom-[17%] left-1/2 origin-bottom transition-transform duration-500 ease-out"
                            :style="{ transform: `translateX(-50%) rotate(${line_rotation - 180}deg)`, height: '50%' }"
                        >
                            <div class="w-[3px] h-full bg-primary rounded-t-full shadow-lg shadow-primary/60"></div>
                            <!-- Ponto de pivô -->
                            <div class="w-4 h-4 rounded-full bg-primary/30 border-2 border-primary absolute -bottom-2 -left-[7px]"></div>
                        </div>
                    </div>
                    <div class="flex items-center gap-3">
                        <span class="px-5 py-1.5 bg-div-15 rounded-full border border-secondary/10 text-sm font-bold tracking-widest text-secondary tabular-nums" title="Ângulo de Medição">
                            {{ (line_rotation - 180).toFixed(1) }}°
                        </span>
                        <span class="px-3 py-1 rounded-full border text-[10px] font-bold tracking-widest uppercase transition-colors" 
                              :class="stepSize === 1 ? 'bg-primary/20 border-primary/40 text-primary' : 'bg-secondary/10 border-secondary/20 text-secondary/60'"
                              title="Tamanho do Passo (Tecla B)">
                            Passo {{ stepSize === 1 ? '1.0' : '0.1' }}°
                        </span>
                    </div>
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
                            class="absolute bottom-[20%] left-1/2 transition-transform duration-200 ease-out"
                            :style="{ transform: `translateX(-50%) rotate(${head_rotation - 180}deg)`, transformOrigin: 'bottom center', height: '60%' }"
                        >
                            <img
                                :src="imagemCabecaAtual"
                                alt="Posição da Cabeça"
                                class="h-full w-auto select-none pointer-events-none"
                            />
                        </div>
                    </div>
                    <span class="px-5 py-1.5 bg-div-15 rounded-full border border-secondary/10 text-sm font-bold tracking-widest text-secondary tabular-nums">
                        {{ (head_rotation - 180).toFixed(1) }}°
                    </span>
                </div>

            </div>

            <!-- Grade de Condições de Exame -->
            <div v-if="controleTela === 'aguardando'" class="w-full overflow-x-auto custom-scrollbar">
                <table class="w-full min-w-[900px] border-separate" style="border-spacing: 0 6px;">
                    <!-- Cabeçalho -->
                    <thead>
                        <tr class="text-xs font-bold tracking-widest uppercase text-secondary">
                            <th class="text-left px-4 py-2 w-[20%]">Condição</th>
                            <th class="text-center px-1 py-2 w-[15%]" v-for="n in 4" :key="n">Medição {{ n }}</th>
                            <th class="text-center px-3 py-2 text-primary/80 w-[20%]">Médias</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr
                            v-for="(cond, idx) in condicoesOrdenadas"
                            :key="cond.id"
                            v-show="isExameCompleto || condicaoAtiva === null || medicaoAtiva === null || condicaoAtiva === idx"
                            class="transition-all duration-300"
                        >

                            <!-- Célula da Condição -->
                            <td class="py-1 pr-2">
                                <div
                                    class="flex items-center gap-3 px-3 h-[32px] rounded-lg border-2 transition-all duration-300"
                                    :class="condicaoAtiva === idx
                                        ? 'border-primary bg-primary/10 shadow-lg shadow-primary/20 condition-pulse'
                                        : 'border-secondary/10 bg-div-10'"
                                >
                                    <span
                                        class="flex-shrink-0 w-3 h-3 rounded-full border-2 transition-colors duration-300"
                                        :class="condicaoAtiva === idx ? 'border-primary bg-primary' : 'border-secondary/30 bg-transparent'"
                                    ></span>
                                    <span class="text-xs font-semibold truncate mt-0.5" :class="condicaoAtiva === idx ? 'text-text' : 'text-secondary'">{{ cond.label }}</span>
                                </div>
                            </td>

                            <!-- Células de Medição (1-4) -->
                            <td v-for="m in 4" :key="m" class="py-1 px-1">
                                <div
                                    class="flex items-center gap-1.5 px-2.5 h-[32px] rounded-lg border-2 transition-all duration-300"
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
                                        {{ formatarMedidaTabela(resultadosExame[cond.id]?.[m-1]) }}
                                    </span>
                                    <span class="text-[10px] text-secondary/40">°</span>
                                </div>
                            </td>

                            <!-- Célula de Médias -->
                            <td class="py-1 pl-1 pr-2">
                                <div
                                    class="flex items-center justify-center gap-1.5 px-2 h-[32px] rounded-lg border-2 transition-all duration-300"
                                    :class="condicaoAtiva === idx ? 'border-primary/30 bg-primary/5' : 'border-secondary/10 bg-div-10'"
                                >
                                    <span class="text-[10px] font-bold text-primary/60 mt-0.5">MD</span>
                                    <span class="text-xs font-bold tabular-nums" :class="condicaoAtiva === idx ? 'text-primary' : 'text-secondary/50'">
                                        {{ calcularMD(cond.id) }}
                                    </span>
                                    <span class="text-[10px] text-secondary/30">°</span>
                                    <span class="mx-0.5 text-secondary/20">/</span>
                                    <span class="text-[10px] font-bold text-primary/40 mt-0.5">MND</span>
                                    <span class="text-xs font-bold tabular-nums" :class="condicaoAtiva === idx ? 'text-primary' : 'text-secondary/50'">
                                        {{ calcularMND(cond.id) }}
                                    </span>
                                    <span class="text-[10px] text-secondary/30">°</span>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Tela de Parabéns / Salvar (Renderiza quando grid for completo, abaixo da tabela) -->
            <div v-if="controleTela === 'aguardando' && isExameCompleto" class="w-full flex-col items-center justify-center text-center mt-8">
                 <div class="w-12 h-12 bg-emerald-500/10 rounded-full flex items-center justify-center mx-auto mb-4 border border-emerald-500/20">
                      <svg class="w-6 h-6 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                 </div>
                 <h2 class="text-xl font-bold tracking-widest uppercase text-text">Exame Concluído</h2>
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
