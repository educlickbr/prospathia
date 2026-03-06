# Exame de Vertical Visual Subjetiva (VVS) — Documentação Técnica

> **Status**: Em desenvolvimento (Nuxt) — App mobile operacional (FlutterFlow)  
> **Última atualização**: 2026-02-27

---

## 1. O Que É Este Exame

O **VVS (Vertical Visual Subjetiva)** avalia como o cérebro do paciente percebe o eixo vertical da gravidade. É um exame fundamental para diagnóstico de problemas de equilíbrio e disfunções vestibulares.

**Na prática:**

- O paciente usa uma máscara VR com o celular acoplado
- O celular captura a orientação da cabeça via giroscópio/acelerômetro
- O paciente tenta alinhar uma linha virtual ao que julga ser o "vertical absoluto"
- O avaliador controla e monitora o exame pelo desktop (Nuxt)

---

## 2. Arquitetura do Sistema

O sistema é dividido em dois agentes que se comunicam em tempo real:

```
┌────────────────────────────────────────────────────────────────┐
│                     SUPABASE REALTIME                          │
│                   (ponte de comunicação)                       │
└──────────────────────┬─────────────────────┬───────────────────┘
                       │                     │
          ┌────────────▼──────┐   ┌──────────▼────────────┐
          │  DESKTOP (Nuxt)   │   │  MOBILE (Flutter)     │
          │                   │   │                       │
          │ - Controla o exame│   │ - Captura sensores    │
          │ - Visualiza dados │   │ - Exibe a linha VR    │
          │ - Registra no DB  │   │ - Reporta ângulos     │
          └───────────────────┘   └───────────────────────┘
```

### 2.1 Canais Supabase Realtime em Uso

Todos os canais são **Broadcast** (sem persistência no DB) e são **específicos por usuário (UID)**:

| Canal                  | Direção          | Evento              | Payload                                                                               |
| ---------------------- | ---------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `{uid}-tela`           | Desktop → Mobile | `tela`              | `{ tela: 'boasvindas' \| 'foco' \| 'examenormal' \| 'sobreposicao' \| 'aguardando' }` |
| `{uid}-mensagem`       | Desktop → Mobile | `mensagem`          | texto livre / controle                                                                |
| `{uid}-mensagem`       | Mobile → Desktop | `heartbeat`         | sinal de conexão ativa                                                                |
| `{uid}-mensagem`       | Mobile → Desktop | `cancelar`          | paciente cancelou / desconectou                                                       |
| `{uid}-angulo`         | Desktop → Mobile | `angulo`            | `{ anguloinicial: number }` (calibração)                                              |
| `{canalId}` (dinâmico) | Mobile → Desktop | `angulodispositivo` | `{ valor: number }` (pitch em graus)                                                  |

### 2.2 Tabela de Controle de Pareamento

```sql
-- Tabela: ControlePareamento
-- Quando o celular faz login e acessa a tela "parear",
-- ele escreve o UID do usuário logado nessa tabela.
-- O desktop escuta por postgres_changes nessa tabela
-- para detectar que o celular está pronto.

pareado_dispositivo: uuid  -- UID do usuário que pareou
```

---

## 3. Fluxo do Exame — Passo a Passo

### 3.1 Pré-exame (Pareamento)

```
DESKTOP                              MOBILE (FlutterFlow)
   │                                      │
   │  [1] Clica "Novo Exame"              │
   │  → Abre modal do exame               │
   │  → Subscreve em ControlePareamento   │
   │    (postgres_changes) aguardando     │
   │    celular parear                    │
   │                                      │
   │                      [2] Login no app│
   │                      → Acessa /parear│
   │        ← ← ← ← ← ← ← ← ← ← ← ← ← │
   │  [3] DB muda → Desktop detecta!      │
   │  → Abre canais Broadcast             │
   │  → Tela: "boasvindas"                │
   │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─► │
   │                     Mobile muda tela │
```

### 3.2 Calibração

```
DESKTOP                              MOBILE
   │                                      │
   │  [1] Envia tela: "sobreposicao"      │
   │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─► │
   │        Mobile exibe dois círculos    │
   │        (azul e vermelho) p/ ajuste   │
   │                                      │
   │  [2] Avaliador ajusta calibração     │
   │  → Envia "anguloinicial" (zero ref.) │
   │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─► │
   │        Mobile salva ângulo base      │
```

### 3.3 Execução do Exame

```
DESKTOP                              MOBILE
   │                                      │
   │  [1] Envia tela: "foco"              │
   │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─► │
   │        Mobile exibe ponto de foco    │
   │                                      │
   │  [2] Envia tela: "examenormal"       │
   │  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─► │
   │        Mobile exibe linha VR         │
   │        (split screen 50/50 para VR)  │
   │        linha rotaciona com pitch     │
   │                                      │
   │  ◄ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
   │    [3] Mobile stream: angulodispositivo
   │        { valor: -2.3 } (graus)       │
   │  → Desktop exibe em tempo real       │
   │                                      │
   │  [4] Avaliador registra leitura      │
   │  → Salva no banco (definitivo)       │
```

---

## 4. Estado do Desenvolvimento

### 4.1 O que já existe no Nuxt

| Arquivo                             | Status        | Descrição                                               |
| ----------------------------------- | ------------- | ------------------------------------------------------- |
| `pages/exames/otolithics/index.vue` | ✅ Funcional  | Lista de pacientes, histórico de exames                 |
| `components/ModalExamReport.vue`    | ✅ Funcional  | Visualização de relatório de exame existente            |
| `components/ModalPaciente.vue`      | ✅ Funcional  | Criação/edição de paciente                              |
| `composables/useRealtime.ts`        | ⚠️ Genérico   | Composable de teste, precisa ser especializado para VVS |
| `pages/teste-realtime.vue`          | ✅ Referência | Página de teste de canais (uso em dev)                  |

### 4.2 O que falta construir

- [ ] **`composables/useVVSExam.ts`** — Composable especializado com toda a lógica do exame VVS
  - Gerenciar múltiplos canais (tela, mensagem, angulo, angulodispositivo)
  - Subscrição em `ControlePareamento` (postgres_changes)
  - Máquina de estados do exame
- [ ] **`components/ModalNovoExame.vue`** — Modal que abre ao clicar "Novo Exame"
  - Tela de aguardando pareamento
  - Painel de controle (envio de comandos de tela)
  - Visualização do ângulo em tempo real
  - Botão de registrar leitura
- [ ] Conectar `performExam(patient.id)` em `otolithics/index.vue` ao novo modal

### 4.3 App Mobile (FlutterFlow) — Référência

O app mobile está **operacional** e é a referência. Para testar sem celular físico:

- Use o **Simulador HTML**: `documentacao/mobile/simulator.html`
- Execute Flutter Web: `cd mobile && flutter run -d chrome`

---

## 5. Telas do Mobile (TelaAtual)

O desktop controla a tela exibida no mobile enviando o nome da tela via broadcast:

| Valor `tela`   | O que o mobile exibe                                           |
| -------------- | -------------------------------------------------------------- |
| `boasvindas`   | Tela de boas-vindas / aguardando início                        |
| `aguardando`   | Tela de espera genérica                                        |
| `sobreposicao` | Dois círculos (azul e vermelho) para ajuste de sobreposição VR |
| `foco`         | Imagem estática de ponto de foco                               |
| `examenormal`  | Split screen 50/50 com linha rotacionada (o exame em si)       |

---

## 6. Cálculo da Linha (Mobile)

```dart
// No mobile, a rotação da linha é calculada assim:
// (simplificado da função calcularCompensacaoLinha do FlutterFlow)

rotacao = anguloinicial - angulosensor

// anguloinicial: recebido do desktop via canal {uid}-angulo
// angulosensor: leitura instantânea do absoluteOrientation.pitch
//               via pacote dchs_motion_sensors
```

O threshold de envio é **0.1 graus** — abaixo disso, não envia para economizar banda.

---

## 7. Notas para o Desenvolvedor

- **Nunca** usar `useRealtime.ts` genérico para o VVS — criar composable dedicado
- Os canais **devem ser desinscritos** quando o modal fecha (cleanup)
- O `angulodispositivo` pode vir em alta frequência — usar `throttle` no desktop se necessário
- O `ControlePareamento` é uma tabela real no Supabase — verificar migrations
- O exame salvo no banco é definitivo; o broadcast é apenas efêmero/tempo real
