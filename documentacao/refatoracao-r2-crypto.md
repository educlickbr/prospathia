# Refatoração: Uso de Web Crypto API para Cloudflare Pages

Este documento resume as alterações realizadas para corrigir o erro `500 Server Error` que ocorria no ambiente do Cloudflare Pages ao tentar gerar tokens de acesso para imagens (R2).

## O Problema

O componente backend do Nuxt estava utilizando o módulo interno do Node.js `crypto` (`import crypto from "crypto"`). O Cloudflare Pages (ambiente Workers/V8) não suporta módulos internos do Node.js por padrão sem flags específicas de compatibilidade, o que causava o travamento da API.

## A Solução (Web Crypto API)

Refatoramos a geração de assinaturas (HMAC SHA-256) e UUIDs para utilizar a **Web Crypto API** (`globalThis.crypto`). Esta API é:

1. **Nativa**: Já vem embutida tanto no Node.js (v18+) quanto no Cloudflare Workers/Pages.
2. **Performática**: Otimizada para ambientes de borda (Edge).
3. **Compatível**: Funciona perfeitamente em localhost e produção sem necessidade de flags extras (`nodejs_compat`).

## Arquivos Alterados

### 1. `server/api/storage/token.get.ts`

- **Removido**: `import crypto from "crypto"`.
- **Implementado**: Geração de assinatura HMAC usando `crypto.subtle.importKey` e `crypto.subtle.sign`.
- **Resultado**: Gera o token de acesso para o Worker de imagens de forma estável.

### 2. `server/api/migration/bunny-to-r2.post.ts`

- **Removido**: `import crypto from "crypto"`.
- **Alterado**: Substituído `crypto.randomUUID()` por `globalThis.crypto.randomUUID()`.

## Benefícios

- **Arquitetura Signed URLs**: Mantemos o download das imagens direto do Worker R2 (mais rápido), sem sobrecarregar o servidor Nuxt como um proxy.
- **Portabilidade**: O código agora é agnóstico ao ambiente de execução.

---

_Data: 11 de Março de 2026_
