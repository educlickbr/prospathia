
-- Migration: 20260130120000_refactor_user_avatar_fk
-- Description: Refactors user_expandido to use id_arquivo_imagem_user (FK to global_arquivos).

-- 1. Schema Changes
ALTER TABLE public.user_expandido
ADD COLUMN IF NOT EXISTS id_arquivo_imagem_user uuid REFERENCES public.global_arquivos(id) ON DELETE SET NULL;

-- 2. Data Migration
-- Populate FK based on existing paths
UPDATE public.user_expandido ue
SET id_arquivo_imagem_user = ga.id
FROM public.global_arquivos ga
WHERE ue.imagem_user = ga.path
  AND ue.imagem_user IS NOT NULL;

-- 3. Drop Old Column
ALTER TABLE public.user_expandido
DROP COLUMN IF EXISTS imagem_user;

-- 4. Function Updates

-- 4.1. nxt_credenciais_user_front (Session Load)
DROP FUNCTION IF EXISTS public.nxt_credenciais_user_front(uuid);

CREATE OR REPLACE FUNCTION public.nxt_credenciais_user_front(p_produto_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_user_id uuid := auth.uid();
    v_user_expandido jsonb;
    v_roles jsonb;
    v_clinica jsonb;
    v_tem_produto boolean;
BEGIN
    SELECT to_jsonb(u_final.*) INTO v_user_expandido
    FROM (
        SELECT 
            ue.id,
            ue.user_id,
            ue.nome_completo,
            ue.email,
            ue.telefone,
            ue.status,
            ue.created_at,
            ue.updated_at,
            ue.id_arquivo_imagem_user,
            ga.path as imagem_user -- Frontend expects this
        FROM public.user_expandido ue
        LEFT JOIN public.global_arquivos ga ON ue.id_arquivo_imagem_user = ga.id
        WHERE ue.user_id = v_user_id
    ) u_final;

    SELECT jsonb_agg(
        jsonb_build_object(
            'role_id', ura.role_id,
            'clinica_id', ura.clinica_id,
            'nome_role', ra.nome_role
        )
    ) INTO v_roles
    FROM public.user_role_auth ura
    LEFT JOIN public.role_auth ra ON ura.role_id = ra.id
    WHERE ura.user_id = v_user_id;

    SELECT jsonb_build_object(
        'id', c.id,
        'nome', c.nome,
        'logo', c.imagem_clinica
    ) INTO v_clinica
    FROM public.clinica_user cu
    JOIN public.clinica c ON cu.id_clinica = c.id
    WHERE cu.id_user = v_user_id
    LIMIT 1;

    SELECT EXISTS (
        SELECT 1 FROM public.produtos_user pu
        WHERE pu.user_id = v_user_id AND pu.produto_id = p_produto_id AND pu.status = true
    ) INTO v_tem_produto;

    RETURN jsonb_build_object(
        'user', v_user_expandido,
        'roles', COALESCE(v_roles, '[]'::jsonb),
        'clinicas', v_clinica, 
        'tem_produto', Coalesce(v_tem_produto, false)
    );
END;
$function$;

-- 4.2. nxt_upsert_user_completo (Upsert)
DROP FUNCTION IF EXISTS public.nxt_upsert_user_completo(uuid, jsonb, jsonb, uuid);

CREATE OR REPLACE FUNCTION public.nxt_upsert_user_completo(
    p_user_id uuid,
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
    UPDATE public.user_expandido
    SET 
        nome_completo = COALESCE((p_dados_user->>'nome_completo'), nome_completo),
        telefone = COALESCE((p_dados_user->>'telefone'), telefone),
        id_arquivo_imagem_user = COALESCE((p_dados_user->>'id_arquivo_imagem_user')::uuid, id_arquivo_imagem_user),
        updated_at = now()
    WHERE id = p_user_id;

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

-- 4.3. nxt_get_users (List)
DROP FUNCTION IF EXISTS public.nxt_get_users(uuid, uuid, uuid);

CREATE OR REPLACE FUNCTION public.nxt_get_users(
    p_papel_id uuid,
    p_produto_id uuid,
    p_empresa_id uuid DEFAULT NULL
)
RETURNS TABLE(
    id uuid,
    nome_completo text,
    email text,
    telefone text,
    imagem_user text,
    status boolean,
    created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ue.id,
        ue.nome_completo,
        ue.email,
        ue.telefone,
        ga.path as imagem_user, -- Joined path
        ue.status,
        ue.created_at
    FROM public.user_expandido ue
    JOIN public.user_role_auth ura ON ue.user_id = ura.user_id
    JOIN public.produtos_user pu ON ue.user_id = pu.user_id
    LEFT JOIN public.global_arquivos ga ON ue.id_arquivo_imagem_user = ga.id
    WHERE 
        ura.role_id = p_papel_id
        AND pu.produto_id = p_produto_id
        AND pu.status = true
        AND (p_empresa_id IS NULL OR ura.clinica_id = p_empresa_id)
    ORDER BY ue.nome_completo ASC;
END;
$function$;

-- 4.4. nxt_get_user_detalhes (Details)
DROP FUNCTION IF EXISTS public.nxt_get_user_detalhes(uuid);

CREATE OR REPLACE FUNCTION public.nxt_get_user_detalhes(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_user_expandido jsonb;
    v_respostas jsonb;
BEGIN
    -- Get User Expandido with JOIN
    SELECT to_jsonb(u_final.*) INTO v_user_expandido
    FROM (
        SELECT 
           ue.*,
           ga.path as imagem_user
        FROM public.user_expandido ue
        LEFT JOIN public.global_arquivos ga ON ue.id_arquivo_imagem_user = ga.id
        WHERE ue.id = p_user_id
        LIMIT 1
    ) u_final;

    IF v_user_expandido IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id', r.id,
            'pergunta_id', r.id_pergunta,
            'pergunta_label', p.label,
            'resposta', r.resposta,
            'resposta_data', r.resposta_data,
            'arquivo', r.nome_arquivo_original,
            'updated_at', r.updated_at
        )
    ) INTO v_respostas
    FROM public.respostas_user r
    LEFT JOIN public.perguntas_user p ON r.id_pergunta = p.id
    WHERE r.id_user = p_user_id;

    RETURN jsonb_build_object(
        'user', v_user_expandido,
        'respostas', COALESCE(v_respostas, '[]'::jsonb)
    );
END;
$function$;
