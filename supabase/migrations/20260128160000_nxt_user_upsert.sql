
-- Migration: nxt_user_upsert
-- Description: Implement RPCs for fetching dynamic form questions and upserting user data + answers.

-- 1. nxt_get_perguntas_painel
-- Returns active questions for a given role, ordered by 'ordem'.
-- Used to build the edit form.

CREATE OR REPLACE FUNCTION public.nxt_get_perguntas_painel(p_papel_id uuid)
RETURNS TABLE (
    id uuid,
    pergunta text,
    label text,
    tipo_pergunta text,
    opcoes jsonb,
    largura integer,
    obrigatorio boolean,
    depende boolean,
    depende_de uuid,
    valor_depende text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.pergunta,
        p.label,
        p.tipo_pergunta,
        p.opcoes,
        p.largura,
        p.obrigatorio,
        p.depende,
        p.depende_de,
        p.valor_depende
    FROM public.perguntas_user p
    WHERE 
        p.ativo = true
        AND p.papeis @> to_jsonb(p_papel_id::text) -- Checks if role ID is in the JSONB array
    ORDER BY p.ordem ASC;
END;
$function$;

-- 2. nxt_upsert_user_completo
-- Upserts user profile info and their answers.
-- Assumes unique constraint on respostas_user(id_user, id_pergunta).

CREATE OR REPLACE FUNCTION public.nxt_upsert_user_completo(
    p_user_id uuid, -- user_expandido UUID
    p_dados_user jsonb,
    p_respostas jsonb,
    p_produto_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    r jsonb;
BEGIN
    -- 1. Update User Expandido
    -- Assuming p_dados_user contains keys like: nome_completo, telefone, imagem_user...
    UPDATE public.user_expandido
    SET 
        nome_completo = COALESCE((p_dados_user->>'nome_completo'), nome_completo),
        telefone = COALESCE((p_dados_user->>'telefone'), telefone),
        imagem_user = COALESCE((p_dados_user->>'imagem_user'), imagem_user),
        updated_at = now()
    WHERE id = p_user_id;

    -- 2. Upsert Answers
    -- p_respostas should be an array of objects: 
    -- [{ "pergunta_id": "...", "resposta": "...", "arquivo": "..." }, ...]
    
    IF p_respostas IS NOT NULL AND jsonb_array_length(p_respostas) > 0 THEN
        FOR r IN SELECT * FROM jsonb_array_elements(p_respostas)
        LOOP
            INSERT INTO public.respostas_user (
                id_user,
                id_pergunta,
                resposta,
                nome_arquivo_original,
                updated_at
            )
            VALUES (
                p_user_id,
                (r->>'pergunta_id')::uuid,
                (r->>'resposta'),
                (r->>'arquivo'),
                now()
            )
            ON CONFLICT (id_user, id_pergunta) DO UPDATE
            SET 
                resposta = EXCLUDED.resposta,
                nome_arquivo_original = EXCLUDED.nome_arquivo_original,
                updated_at = EXCLUDED.updated_at;
        END LOOP;
    END IF;

    RETURN true;
END;
$function$;
