# Documentação do Projeto Mobile - Prospathia

Este documento descreve a arquitetura e funcionamento do aplicativo mobile do projeto **Prospathia**, focado na integração em tempo real de sensores e interface com a versão Desktop via Supabase Realtime.

O aplicativo é desenvolvido em **Flutter / FlutterFlow** e atua como uma interface de captura de dados de movimento (sensores) e exibição estereoscópica para um exame de vertical visual subjetiva (VR).

## 1. Fluxo de Autenticação e Pareamento

1. **Login (`pages/login`)**: O usuário realiza o login padrão que o autentica via Supabase Auth.
2. **Parear (`pages/parear` / `pages/parear2`)**:
   - Atualiza a tabela `ControlePareamento` modificando a coluna `pareado_dispositivo` para o usuário logado (`id_user`).
   - Inicia canais de comunicação Realtime via Supabase específicos para o UID do usuário.
   - Assim que está "pareado", o app e o Desktop podem trocar mensagens e estados de tela.

## 2. Comunicação em Tempo Real (Supabase Realtime)

O app utiliza extensivamente canais de Broadcast do Supabase (identificados por `${currentUserUid}-[tipo]`) para sincronizar estados instantâneos sem precisar persistir tudo na base de dados.

### 2.1. Canais Escutados pelo Mobile (Recepção)

- **Canais de Tela (`${currentUserUid}-tela`)**:
  - Escutada através de `listen_tela.dart`. O Desktop envia um payload com `event = 'tela'` contendo o nome da tela. O app atualiza `FFAppState().TelaAtual`.
  - Estados processados na `exame_widget.dart` incluem:
    - `sobreposicao`: Mostra dois círculos para ajuste (azul e vermelho).
    - `foco`: Exibe uma imagem de foco estática.
    - `boasvindas` / `aguardando`: Telas de espera.
    - `examenormal`: Exibe a linha vermelha rotacionada, controlada pela posição do aparelho e calibragem do desktop.
- **Canais de Mensagens (`${currentUserUid}-mensagem`)**:
  - Pega dados textuais enviados pelo Desktop para controle secundário (por exemplo, exibição do texto ou cor).
- **Canais de Ângulo de Calibragem (`${currentUserUid}-angulo`)**:
  - Recebe do Desktop o `anguloinicial` (ângulo de referência / ponto zero estabelecido na calibração inicial).

### 2.2 Canais Enviados pelo Mobile (Transmissão)

- **Dados do Sensor (`AnguloUnificadoListener`)**:
  - Escuta os sensores nativos do celular via `dchs_motion_sensors` (`absoluteOrientation.pitch`).
  - Quando a variação do pitch ultrapassa um threshold (0.1 graus), ele envia para o Desktop via Broadcast (canal definido pelo canalId) sob o evento `angulodispositivo`.
  - Este é o dado essencial utilizado pelo Desktop para interpretar a inclinação da cabeça ou do dispositivo do paciente.
- **Heartbeat & Eventos**:
  - O app envia eventos do tipo `heartbeat` e mensagens como `cancelar` no canal `${currentUserUid}-mensagem` para notificar sucesso de conexão, queda, ou cancelamento do pareamento.

## 3. Renderização do Exame (`exame_widget.dart`)

Durante a avaliação (`TelaAtual == 'examenormal'`), o aplicativo se divide em duas partes iguais (split screen 50/50), projetadas para uso em dispositivos de Realidade Virtual (VR).
Nesta tela estereoscópica, é exibida uma `linha_oto.png` rotacionada dinamicamente:

- A rotação leva em conta `anguloinicial` (setado pelo broadcast do desktop) e o `angulosensor` (capturado instantaneamente pelo celular).
- O cálculo da rotação é resolvido utilizando a função `functions.calcularCompensacaoLinha()`.

## 4. Tecnologias / Pacotes Chave

- **Supabase Flutter / Supabase_auth**: Autenticação, gestão de sessão e Broadcast realtime (Presence / Channels).
- **dchs_motion_sensors**: Biblioteca Dart para leitura refinada da orientação absoluta (pitch/roll/yaw) usando os giroscópios e acelerômetros.
- **FlutterFlow Framework**: Ferramental visual de onde derivam as pastas `custom_code`, `app_state` e UI components (`pages`).

---

## 5. Testes Apenas no Desktop (Sem Celular)

Para desenvolver e testar a integração Mobile-Desktop sem precisar de um dispositivo físico, você tem três opções principais:

### 5.1. Simulador HTML (Altamente Recomendado)

Criamos uma ferramenta ultra-leve para simular o comportamento do celular diretamente no browser:

- **Arquivo**: [simulator.html](file:///home/eikmeier/Documentos/dev/nuxt/prospathia/documentacao/mobile/simulator.html)
- **Como usar**:
  1. Abra o arquivo `simulator.html` em uma aba do Chrome.
  2. Insira o UID do usuário que está logado no Desktop.
  3. Use o **Slider** para simular a inclinação do sensor e os botões para eventos de cancelamento ou pareio.
  4. O Desktop (Nuxt) receberá os dados via Realtime como se o celular estivesse enviando.

### 5.2. Flutter Web

O projeto mobile tem suporte para Web:

1. Navegue até a pasta `/mobile`.
2. Execute o comando: `flutter run -d chrome`.
3. O app abrirá no navegador. _Nota: Sensores físicos de giroscópio são limitados no ambiente web desktop._

### 5.3. Dashboard Supabase

Você pode enviar mensagens de teste manualmente:

1. Acesse o Supabase Dashboard -> Realtime -> Inspector.
2. Selecione o canal `${currentUserUid}-mensagem`.
3. Envie um JSON de Broadcast com `event: "angulodispositivo"` e `payload: {"valor": 12.5}`.
