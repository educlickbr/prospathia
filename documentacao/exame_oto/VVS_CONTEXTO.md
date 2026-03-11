# Implementação do Exame VVS (Otolithics) - Estado Atual

Este documento detalha tudo o que já foi implementado e estruturado para o fluxo do Exame VVS no sistema web (Painel).

## 1. Visão Geral da Arquitetura

A arquitetura do exame VVS segue fortemente o padrão **Thick Database** e uma comunicação **Híbrida de Tempo Real**:

- **Thick Database (BFF + RPCs)**: Nenhuma consulta direta ao banco de dados pelo frontend. O cliente web se comunica com endpoints na camada BFF (Nitro/Nuxt Server), que por sua vez invocam `RPCs` seguras e blindadas no Supabase usando a chave de serviço (`serverSupabaseClient`).
- **Realtime (WebSockets)**: Utilizado estritamente para comandos de tela bidirecionais entre painel web e celular/óculos VR (via canais de `Presence`/`Broadcast` como `uid-tela` e `uid-angulo`).

## 2. Componente Visual e Interface (`ModalNovoExame.vue`)

O modal de exame gerencia as etapas sequenciais (state-machine) do exame VVS, disparando eventos para o dispositivo VR e adaptando a interface no Desktop.

**Fases já implementadas:**

1. **`parear`**: Instruções para conectar o dispositivo móvel com a conta ativa. O pareamento agora acontece via _short-polling_ (BFF), o que eliminou comportamentos não-determinísticos de WebSockets em background.
2. **`boasvindas`**: Instruções para acomodar a máscara do VR.
3. **`foco`**: Ajuste de foco das lentes (envia payload `{"nome": "foco"}` pro VR).
4. **`sobreposicao`**: Calibração com esferas azul/vermelha -> roxa (envia payload `{"nome": "sobreposicao"}`).
5. **`aguardando`**: Tela de pré-setup antes do início das baterias de medições reais.

**Recursos Visuais da Tela `aguardando`**:
Na tela de espera, montamos um dashboard responsivo e detalhado que espelha os dados em tempo real:

- **Painel de Transferidores**: Dois instrumentos com eixos rotativos mapeados para os dados de head tracking/linha. As variáveis visuais mantêm a convenção onde $180^\circ$ (interno) se apresenta como $0^\circ$ (neutro visual), esquerda vira negativo, direita positivo. Tudo dimensionado fluidamente no container CSS (`height: 55%` e `height: 60%`).
- **Tabela de Acompanhamento (Grid do Exame)**: Tabela contendo 7 linhas (as 7 condições: Neutra, Estáticas, Dinâmicas e Hápticas) com células para as 4 medições subsequentes de cada uma e colunas de médias (`MD` e `MND`).
- **Feedback Visual por CSS**: As linhas e células da tabela brilham através de classes CSS que invocam aninmações de `@keyframes` (`condition-pulse` e `measurement-pulse`) de acordo com o estado do fluxo.

## 3. Gestor de Estado (`useVVSExam.ts`)

O composable de VVS organiza todo o ciclo de vida do exame local no cliente:

- Gerencia os ref globais como: `controleTela`, `pareamentoStatus`, `condicaoAtiva`, `medicaoAtiva`.
- Subscrição em canais Supabase (`channel.on('broadcast', ...)`) limitando-se a pacotes rápidos.
- Centraliza lógica de Cleanup (`onUnmounted` / Desconectar) para prevenção assídua de vazamento de memória e listeners fantasmas.

## 4. Utilitários Puros (`utils/vvsExame.ts`)

Para desvincular regras matemáticas pesadas do rendering Vue, criamos o helper assíncrono que rege as gerações aleatórias essenciais de um exame:

- **`sortearOrdemDirecao()`**: Seleciona uma das 6 sequências predefinidas validadas de direita ("d") e esquerda ("e").
- **`gerarMedidasCondicao()`**: Com o vetor e os limiares extraídos do banco de dados (por ex: `amaxesq`, `amindir`), gera 4 ângulos aleatórios, **tendo como regra forte e vitalícia** a restrição lógica de uma distância mínima de 10º entre si se os ângulos forem de lados correspondentes, implementando até fallback otimizado para não gerar laços infinitos.

## 5. BFF e Banco de Dados (`Nitro` + `Supabase`)

Foram criadas três integrações sólidas do padrão Thick Database com endpoints Nuxt:

- **`POST /api/vvs/status-exame`**: Muta os status via a RPC correspondente.
- **`GET /api/vvs/check-pareamento`**: Rotina determinística que consulta dados robustos de pareamento via RPC.
- **`GET /api/vvs/condicoes-exame`**: Retorna os parâmetros base das 7 condições de exame requeridas, lendo diretamente do backend, já preparados e organizados pelo RPC recém codificado em migration `20260224100000_vvs_get_condicoes_exame.sql`.

## 6. Evolução Recente e Finalização (Ajustes de Março/2026)

Nas sessões mais recentes, o fluxo foi levado da calibração visual até a persistência real de dados no banco, com refinamentos críticos de UX:

### 6.1 Controles Físicos e Precisão (Teclado 3 Botões)

Implementamos uma lógica de mapeamento para teclados industriais de apenas três teclas (A, B, C), comumente usados em setups de VR:

- **Tecla A / Seta Direita**: Incrementa o ângulo da linha.
- **Tecla C / Seta Esquerda**: Decrementa o ângulo da linha.
- **Tecla B / Space**: Alterna a velocidade do passo entre **0.1°** (precisão cirúrgica) e **1.0°** (ajuste rápido).
- **Tratamento de Arredondamento**: O sistema utiliza `.toFixed(1)` e `parseFloat` em todas as mutações para evitar erros de ponto flutuante do Javascript, garantindo que o banco de dados receba valores decimais exatos.

### 6.2 Persistência de Dados (RPC `nxt_create_oto_exame_paciente`)

Foi desenvolvida uma estrutura de salvamento atômico para garantir a integridade do prontuário:

- **Migration SQL**: Uma nova RPC que recebe um `JSONB` contendo todas as 7 condições e suas 4 medições. Ela insere o registro mestre na tabela `oto_exames` e faz o unnest dos dados para a tabela `oto_condicoes_exame_paciente` em uma única transação.
- **BFF (`/api/vvs/exame.post.ts`)**: Camada de backend que valida os IDs de clínica e paciente, consome o `user_expandido_id` da store do Pinia e dispara o salvamento, retornando o ID do novo exame.

### 6.3 Interface Pós-Exame e Relatório

A experiência de fechamento do exame foi redesenhada para ser intuitiva:

- **Estado `isExameCompleto`**: Uma propriedade computada que monitora o grid de resultados. Quando todas as 28 medições (7x4) são preenchidas, a interface entra em modo de finalização.
- **UI de Conclusão**: O painel de instrumentos (transferidores) é ocultado para dar lugar a uma visão limpa da tabela de resultados e um banner de sucesso.
- **Integração com Relatório**: Ao salvar, o usuário é levado a uma tela de "Exame Salvo" com a opção de abrir imediatamente o `ModalExamReport.vue`. O componente pai (`index.vue`) coordena a troca de modais e o refresh automático do cache de exames do paciente.

### 6.4 Refinamentos de Layout

- **Alinhamento do Pivot**: Ajustamos as coordenadas CSS (`bottom-[17%]`) da agulha do transferidor para que o ponto giratório case perfeitamente com o desenho técnico da imagem de fundo.
- **Z-Index e Visibilidade**: O grid de condições agora expande automaticamente para exibir todas as linhas concluídas ao final do processo, facilitando a revisão antes do clique em "Salvar".

---

_Documento atualizado em 11 de Março de 2026._
