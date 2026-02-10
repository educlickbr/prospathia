# Migração Storage: BunnyCDN para Cloudflare R2

**Data:** 30/01/2026 **Responsável:** Equipe de Desenvolvimento **Status:**
Concluído ✅

---

## 1. Contexto

O projeto migrou o armazenamento de arquivos estáticos (avatares de usuários e
logos de clínicas) do antigo provedor **BunnyCDN** para o **Cloudflare R2**. O
objetivo foi consolidar a infraestrutura, aumentar a segurança (buckets privados
com URLs assinadas) e melhorar a integridade dos dados no banco.

---

## 2. Nova Arquitetura

### 2.1. Cloudflare R2 + Worker

- **Storage:** Cloudflare R2 (Compatível com S3).
- **Acesso:** Via Cloudflare Worker (Gateway de Segurança).
  - Arquivos não são públicos.
  - Acesso requer URL assinada (Signed URL) gerada pelo backend/frontend com
    token.
- **Worker URL:** Configurada em variável de ambiente `WORKER_URL`.

### 2.2. Banco de Dados (PostgreSQL)

Introduzimos o conceito de **Single Source of Truth** para arquivos.

- **Tabela `global_arquivos`:**
  - Centraliza metadados de TODOS os arquivos do sistema.
  - Colunas: `id`, `path` (nome no bucket), `bucket`, `mimetype`,
    `tamanho_bytes`, `criado_por`.
  - Sem coluna `metadata` genérica (removida durante migração).

- **Foreign Keys (Refatoração):**
  - **`user_expandido`**:
    - DE: `imagem_user` (texto/path solto).
    - PARA: `id_arquivo_imagem_user` (UUID -> FK para `global_arquivos`).
  - **`clinica`**:
    - DE: `imagem_clinica` (texto/path solto).
    - PARA: `id_arquivo_imagem_clinica` (UUID -> FK para `global_arquivos`).

### 2.3. Frontend (Nuxt) e RPCs

- **RPCs (`nxt_credenciais_user_front`, etc.):** Foram atualizadas para fazer
  `JOIN` com `global_arquivos` e retornar o `path` transparentemente para o
  frontend (mantendo compatibilidade com `imagem_user` no JSON de resposta).
- **Stores (`stores/app.ts`):** Adicionada action `getSignedUrl(path)` que monta
  a URL segura chamando o Worker com os tokens de autenticação.

---

## 3. Processo de Migração Realizado

A migração foi dividida em duas grandes etapas (Usuários e Clínicas), seguindo o
mesmo padrão:

### Etapa 1: Migração de Arquivos (Físico)

Scripts em `server/api/migration/` foram criados para:

1. Ler registros com imagens antigas (Bunny).
2. Baixar a imagem do BunnyCDN.
3. Fazer upload para o R2.
4. Criar registro em `global_arquivos`.
5. Atualizar a tabela de origem com o novo nome do arquivo.

**Scripts Usados:**

- `server/api/migration/bunny-to-r2.post.ts` (Usuários)
- `server/api/migration/clinica-bunny-to-r2.post.ts` (Clínicas)

### Etapa 2: Refatoração do Banco (Lógico)

Migrations SQL foram aplicadas para transformar as colunas de texto em chaves
estrangeiras.

**Migrations SQL:**

- `20260130090000_create_global_arquivos.sql`: Cria tabela central.
- `20260130120000_refactor_user_avatar_fk.sql`: Refatora User.
- `20260130130000_refactor_clinica_avatar_fk.sql`: Refatora Clinica.

---

## 4. Como Usar (Dev Guide)

### 4.1. Upload de Novos Arquivos

O fluxo de upload já está integrado ao R2 via endpoint `/api/upload/files`.

### 4.2. Exibição de Imagens

No Frontend (Vue/Nuxt), nunca concatene strings manualmente. Use a store:

```typescript
// Exemplo em componente Vue
const store = useAppStore()

// No template
<img :src="store.getSignedUrl(user.imagem_user)" />
```

### 4.3. Manutenção

Para adicionar novas entidades com arquivos (ex: `exames`):

1. Adicione a coluna `id_arquivo_exame` (FK) na tabela.
2. Ao salvar, faça insert em `global_arquivos` primeiro.
3. Vincule o ID retornado na sua tabela.

---

**Fim da Documentação**
