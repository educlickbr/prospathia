import { ref, watch, onUnmounted } from 'vue';

// Estados do exame (Singleton para manter mesma referência no Index e no Modal)
const isConnectedToChannels = ref(false);
const pareamentoStatus = ref<'aguardando_pareamento' | 'pareado'>('aguardando_pareamento');
// Estado de navegação do Modal
const controleTela = ref<'parear' | 'boasvindas' | 'foco' | 'sobreposicao' | 'aguardando' | 'exame' | 'fim' | 'salvo'>('parear');
const logs = ref<any[]>([]);

// Condições de calibração do exame (buscadas do banco)
const condicoesExame = ref<any[]>([]);

// Dados em tempo real dos ângulos (giroscópio)
const lastAngleData = ref({ line: 180, head: 180 });

// Variáveis internas para os canais e polling
const channels = ref<Record<string, any>>({});
let pollingInterval: any = null;
const activeUid = ref<string | null>(null);

// Gatilhos de controle remoto do Modal
const controleRemotoCancelar = ref(0);

export const useVVSExam = () => {
    const supabase = useSupabaseClient();
    const currentUser = useSupabaseUser();

    const ensureTelaChannel = async (uid: string) => {
        const telaChannelName = `${uid}-tela`;
        let telaChannel = channels.value[telaChannelName];

        if (telaChannel) {
            return telaChannel;
        }

        telaChannel = supabase.channel(telaChannelName);
        telaChannel
            .on('broadcast', { event: '*' }, (payload) => {
                logMessage('Broadcast Echo (Tela)', payload);
            })
            .subscribe((status) => {
                if (status === 'SUBSCRIBED') {
                    isConnectedToChannels.value = true;
                } else if (status === 'CLOSED' || status === 'CHANNEL_ERROR') {
                    isConnectedToChannels.value = false;
                }
            });

        channels.value[telaChannelName] = telaChannel;
        return telaChannel;
    };

    const logMessage = (source: string, message: any) => {
        const msg = {
            source,
            ...message,
            received_at: new Date().toISOString()
        };
        logs.value.unshift(msg);
        console.log(`[VVS ${source}]`, message);
    };

    /**
     * Inicia todo o processo de pareamento para o exame.
     * 1. Inscreve-se na tabela controle_pareamento (Postgres Changes)
     * 2. Inscreve-se no canal Broadcast {uid}-tela
     * 3. Faz um Upsert sinalizando que o exame foi iniciado (desktop pronto)
     */
    const startPareamento = async (fallbackUid?: string) => {
        let uid = currentUser.value?.id || fallbackUid || activeUid.value;
        if (!uid) {
            const { data } = await supabase.auth.getUser();
            uid = data?.user?.id;
        }
        console.log('[VVS_DEBUG] startPareamento called, resolved uid =', uid);
        
        if (!uid) {
            console.error('[VVS_DEBUG] UID não fornecido para iniciar pareamento. Cancelando execução.');
            return;
        }
        
        // Salva na memória global
        activeUid.value = uid;
        
        // Puxa as métricas de calibração do exame do banco em background
        fetchCondicoes();

        // --- 1. Polling Deterministico (BFF) ---
        // Aqui o Desktop checa de 2 em 2 segundos se o mobile disparou pareado_dispositivo = true
        // Cortamos o WebSocket problemático do Vue.
        if (pollingInterval) clearInterval(pollingInterval);
        
        pollingInterval = setInterval(async () => {
            if (pareamentoStatus.value === 'pareado') {
                 clearInterval(pollingInterval);
                 return;
            }
            try {
                const res = await $fetch<any>('/api/vvs/check-pareamento');
                if (res && res.success === false && res.error) {
                    console.log('[VVS_DEBUG] Polling recusado pelo banco:', res.error);
                } else if (res && res.pareado === true) {
                    pareamentoStatus.value = 'pareado';
                    logMessage('System', { text: 'Dispositivo pareado com sucesso (BFF Polling)!' });
                    clearInterval(pollingInterval);
                    pollingInterval = null;
                }
            } catch (err) {
                console.error('Erro silencioso no polling BFF:', err);
            }
        }, 2000);

        // --- 2. Subscrição de Broadcast (Canal de Tela e Mensagens) ---
        // Aqui o Desktop vai enviar os comandos para o mobile
        await ensureTelaChannel(uid);

        // --- 3. Atualização de controle_pareamento ---
        // Dizemos ao banco que o desktop está pronto através da API (BFF)
        try {
            await $fetch('/api/vvs/status-exame', {
                method: 'POST',
                body: { status: true }
            });
            logMessage('System', { text: 'Aguardando dispositivo...' });
            pareamentoStatus.value = 'aguardando_pareamento';
        } catch (e: any) {
            console.error('Erro ao modificar o controle_pareamento (BFF):', e);
            logMessage('Erro', { text: 'Falha ao registrar início do exame no banco.' });
        }

        // Canais de Tracking da Cabeça serão criados apenas na hora da Medição
    };

    /**
     * Envia um evento de mudança de tela para o mobile.
     */
    const enviarTela = async (fallbackUid: string | undefined, tela: string) => {
        let uid = fallbackUid || activeUid.value || currentUser.value?.id;
        if (!uid) {
            const { data } = await supabase.auth.getUser();
            uid = data?.user?.id;
        }
        
        if (!uid) return;
        
        const channel = await ensureTelaChannel(uid);
        
        console.log('[VVS_DEBUG] enviarTela called with', tela, 'channel exists?', !!channel, 'isConnected?', isConnectedToChannels.value);
        if (channel) {
            logMessage('Enviando (Tela)', { nome: tela });
            channel.send({
                type: 'broadcast',
                event: 'tela',
                payload: { nome: tela }
            }).then((resp: string) => {
                console.log(`[VVS_DEBUG] Response from enviarTela (${tela}):`, resp);
                if (resp !== 'ok') logMessage('Alerta Socket', { text: `Erro ao enviar tela: ${resp}` });
            });
            console.log('[VVS_DEBUG] enviarTela comando submetido ->', tela);
        } else {
             console.error('Canal de tela não está conectado.');
             logMessage('Erro', { text: 'Canal de tela não conectado para enviar: ' + tela });
        }
    };

    /**
     * Busca os parâmetros base de condição do exame no BFF
     */
    const fetchCondicoes = async () => {
        try {
            const res = await $fetch<any>('/api/vvs/condicoes-exame');
            if (res && res.success && res.data) {
                condicoesExame.value = res.data;
                console.log('[VVS_DEBUG] Condições de Exame carregadas:', res.data.length);
            } else {
                console.error('[VVS_DEBUG] Falha ao carregar condições:', res?.error);
            }
        } catch (e) {
            console.error('[VVS_DEBUG] Erro de rede ao buscar condições:', e);
        }
    };

    /**
     * Avança a view para Boas Vindas, configurando o canal de mensagem e exibindo o nome do paciente no mobile.
     */
    const avancarParaBoasVindas = async (fallbackUid: string | undefined, nomePaciente: string) => {
        let uid = fallbackUid || activeUid.value || currentUser.value?.id;
        if (!uid) {
            const { data } = await supabase.auth.getUser();
            uid = data?.user?.id;
        }
        
        console.log('[VVS_DEBUG] avancarParaBoasVindas chamado. resolved uid:', uid);
        if (!uid) {
            console.warn('[VVS_DEBUG] Usuário não disponível, abortando!');
            return;
        }

        // 1 - Mudar o estado local imediatamente (antes de qualquer await)
        controleTela.value = 'boasvindas';

        // Mandar a tela mudar para o app focar e se preparar para as próximas views
        enviarTela(uid, 'parear');

        // 2 e 3 - Inscrever no canal de mensagens
        const mensagemChannelName = `${uid}-mensagem`;
        
        // Se já existir não precisa recriar, mas o ideal é garantir a instância
        if (!channels.value[mensagemChannelName]) {
            const mensagemChannel = supabase.channel(mensagemChannelName);
            mensagemChannel
                .on('broadcast', { event: '*' }, (payload) => {
                    logMessage('Broadcast Echo (Mensagem)', payload);
                    
                    // Escuta eventos de 'cancelar' vindo do Óculos/Celular
                    const pEvent = payload.event;
                    const pValor = payload.payload?.valor || payload.payload?.mensagem;
                    
                    console.log(`[VVS_DEBUG] RX event: ${pEvent}, valor: ${pValor}`);
                    
                    if ((pEvent === 'mensagem' || pEvent === 'mensagens') && String(pValor).toLowerCase() === 'cancelar') {
                         console.log('[VVS_DEBUG] RECEBIDO CANCELAMENTO REMOTO DO DISPOSITIVO! Ativando Gatilho...');
                         controleRemotoCancelar.value++; // Força gatilho reativo do Vue
                    }
                })
                .subscribe(async (status) => {
                    if (status === 'SUBSCRIBED') {
                        // 4 - Enviar dado do paciente quando abrir o canal com sucesso
                        logMessage('System', { text: `Canal de mensagens conectado. Enviando paciente: ${nomePaciente}` });
                        mensagemChannel.send({
                             type: 'broadcast',
                             event: 'mensagens',
                             payload: { mensagem: nomePaciente }
                        }).then((resp: string) => {
                             console.log('[VVS_DEBUG] Response form enviarMensagem:', resp);
                             if (resp !== 'ok') logMessage('Alerta Socket', { text: `Erro de rede NSG: ${resp}` });
                        });
                        console.log('[VVS_DEBUG] mensagem submetida na inscrição.');
                    }
                });

            channels.value[mensagemChannelName] = mensagemChannel;
        } else {
            // Se já estava conectado, basta enviar direto
            channels.value[mensagemChannelName].send({
                 type: 'broadcast',
                 event: 'mensagens',
                 payload: { mensagem: nomePaciente }
            });
            console.log('[VVS_DEBUG] mensagem enviada no canal existente.');
        }

        controleTela.value = 'boasvindas';
    };

    /**
     * Inicia as subscrições para a captura de medidas em Tempo Real
     */
    const iniciarTrackingVR = (anguloInicial: number) => {
        const uid = activeUid.value || currentUser.value?.id;
        if (!uid) return;

        logMessage('System', { text: `[VR] Modo de medição ativado. Enviando ângulo base: ${anguloInicial}º` });

        const anguloChannelName = `${uid}-angulo`;
        const dispositivoChannelName = `${uid}-dispositivo`;

        // 1. Prepara Canal de Ângulo (Seta) para enviar as correções/início
        if (!channels.value[anguloChannelName]) {
            channels.value[anguloChannelName] = supabase.channel(anguloChannelName);
        }
        
        // Emite o ângulo inicial pro Mobile deitar a seta
        channels.value[anguloChannelName].subscribe((status: string) => {
            if (status === 'SUBSCRIBED') {
                channels.value[anguloChannelName].send({
                    type: 'broadcast',
                    event: 'angulo',
                    payload: { valor: anguloInicial }
                });
            }
        });

        // 2. Prepara e Assina o Canal de Dispositivo (Giroscópio da Cabeça vindo do Celular)
        if (!channels.value[dispositivoChannelName]) {
            channels.value[dispositivoChannelName] = supabase.channel(dispositivoChannelName);
        }

        channels.value[dispositivoChannelName]
            .on('broadcast', { event: 'angulodispositivo' }, (payload: any) => {
                console.log(`[VVS_DEBUG] RX (angulodispositivo):`, payload);
                
                // Baseado nos logs de Rede do app legado do usuário, o objeto chega limpo:
                // {event: 'angulodispositivo', type: 'broadcast', valor: -7.7729}
                // Opcionalmente podemos suportar o wrapper do payload.payload caso a web SDK encapsule
                const valorCru = payload.valor ?? payload.payload?.valor ?? payload.data?.valor;
                
                if (valorCru !== undefined && valorCru !== null) {
                    const giroDegrees = parseFloat(valorCru);
                    // Os logs mostraram que o valor JÁ VEM EM GRAUS (ex: 15.98, -36.04)
                    // Então pulamos a conversão de Radianos.
                    
                    // Como a variável head local é base 180 visualmente no transferidor do front:
                    lastAngleData.value.head = 180 + giroDegrees;
                }
            })
            .subscribe((status: string) => {
                if (status === 'SUBSCRIBED') {
                    console.log(`[VVS_DEBUG] Dispositivo Channel conectado. Escutando giroscópio...`);
                }
            });
    };

    /**
     * Envia pequenos ajustes da seta (teclado) diretamente para o Mobile
     */
    const ajustarAnguloVR = (novoValor: number) => {
        const uid = activeUid.value || currentUser.value?.id;
        if (!uid) return;
        const angChannel = channels.value[`${uid}-angulo`];
        if (angChannel) {
            angChannel.send({
                type: 'broadcast',
                event: 'angulo',
                payload: { valor: novoValor }
            });
        }
    };

    /**
     * Para as transmissões pesadas do tracking de giroscópio e envios de seta,
     * economizando CPU e banda entre medidas
     */
    const pararTrackingVR = async () => {
        const uid = activeUid.value || currentUser.value?.id;
        if (!uid) return;

        console.log('[VVS_DEBUG] Medição pausada, limpando canais de tracking para economizar processamento...');
        const angChannel = channels.value[`${uid}-angulo`];
        const dispChannel = channels.value[`${uid}-dispositivo`];

        if (angChannel) {
            await angChannel.unsubscribe();
            delete channels.value[`${uid}-angulo`];
        }
        if (dispChannel) {
            await dispChannel.unsubscribe();
            delete channels.value[`${uid}-dispositivo`];
        }
    };

    /**
     * Limpa os canais e sinaliza o cancelamento do exame.
     */
    const cleanup = async (fallbackUid?: string) => {
        let uid = fallbackUid || activeUid.value || currentUser.value?.id;
        if (!uid) {
            const { data } = await supabase.auth.getUser();
            uid = data?.user?.id;
        }
        
        if (!uid) return;

        logMessage('System', { text: 'Limpando canais de exame e cancelando...' });
        
        // 1. Enviar comando de cancelar via tela (Antes de nos desinscrevermos)
        const telaChannelName = `${uid}-tela`;
        const telaChannel = channels.value[telaChannelName];
        if (telaChannel) {
            try {
                telaChannel.send({
                    type: 'broadcast',
                    event: 'tela',
                    payload: { nome: 'cancelar' }
                });
                logMessage('Cancelamento', { text: 'Enviado comando de cancelar para o mobile.' });
            } catch (e) {
                console.error('Erro ao enviar evento de cancelar:', e);
            }
        }

        // 2. Desinscrever de todos os canais específicos deste cliente
        // Vamos garantir que se a gente se inscreveu em algum deles antes, vão ser dropados agora
        const canaisParaRemover = [
            `${uid}-angulo`,
            `${uid}-dispositivo`,
            `${uid}-tela`,
            `${uid}-mensagem`
        ];

        // O SupabaseClient rastreia os canais ativos. Varremos para remover os que dão 'match'
        const activeChannels = supabase.getChannels();
        activeChannels.forEach((channel) => {
            // O topic retorna o formato do canal. Se bater com os do VVS, dropamos.
            const topicBase = channel.topic.replace('realtime:', '');
            if (canaisParaRemover.includes(topicBase) || canaisParaRemover.some(name => channel.topic.includes(name))) {
                supabase.removeChannel(channel);
            }
        });

        // Limpa estado isolado da store
        channels.value = {};
        isConnectedToChannels.value = false;
        activeUid.value = null;
        lastAngleData.value = { line: 180, head: 180 };
        controleRemotoCancelar.value = 0;
        if (pollingInterval) {
            clearInterval(pollingInterval);
            pollingInterval = null;
        }

        // 3. Informar ao banco que o desktop cancelou/fechou a tela
        // 3. Informar ao banco que o desktop cancelou/fechou a tela via BFF
        try {
            await $fetch('/api/vvs/status-exame', {
                method: 'POST',
                body: { status: false }
            });
            logMessage('System', { text: 'Exame desativado no banco (via BFF).' });
        } catch (e) {
            console.error('Erro ao atualizar exame_iniciado para false (BFF):', e);
        }
        
        // Reset state final
        pareamentoStatus.value = 'aguardando_pareamento';
        controleTela.value = 'parear';
    };

    // Auto-cleanup no unmount - Omitimos uid aqui pois unmounted não tem ref garantido,
    // mas ModalNovoExame já cuida disso antes do unmount visual pelo watcher
    onUnmounted(() => {
        // cleanup(unknown)
    });

    return {
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
        iniciarTrackingVR,
        ajustarAnguloVR,
        pararTrackingVR,
        fetchCondicoes,
        cleanup,
        logMessage
    };
};
