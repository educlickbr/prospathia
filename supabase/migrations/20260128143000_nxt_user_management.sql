
-- Migration: nxt_user_management
-- Description: Implement RPCs for listing users (nxt_get_users) and fetching user details (nxt_get_user_detalhes).

-- 1. nxt_get_users
-- Returns a lightweight list of users filtered by Role and Product.
-- Optional: Filter by specific Empresa/Clinica context.

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
        ue.imagem_user,
        ue.status,
        ue.created_at
    FROM public.user_expandido ue
    JOIN public.user_role_auth ura ON ue.user_id = ura.user_id
    JOIN public.produtos_user pu ON ue.user_id = pu.user_id
    WHERE 
        ura.role_id = p_papel_id
        AND pu.produto_id = p_produto_id
        AND pu.status = true -- Valid product access
        AND (p_empresa_id IS NULL OR ura.clinica_id = p_empresa_id) -- Optional context filter
    ORDER BY ue.nome_completo ASC;
END;
$function$;

-- 2. nxt_get_user_detalhes
-- Returns full user details including answers to questions.

CREATE OR REPLACE FUNCTION public.nxt_get_user_detalhes(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_user_expandido jsonb;
    v_respostas jsonb;
BEGIN
    -- Get User Expandido (Full Record)
    SELECT to_jsonb(ue.*) INTO v_user_expandido
    FROM public.user_expandido ue
    WHERE ue.id = p_user_id -- Note: Input is user_expandido UUID, not auth.users UUID? 
                            -- If p_user_id is user_expandido.id, use ue.id. 
                            -- If it is auth.users.id, use ue.user_id.
                            -- Standardizing on user_expandido.id for frontend lists usually.
    LIMIT 1;

    -- If searching by auth_id is needed, logic would change. 
    -- Assuming p_user_id is user_expandido.id passed from nxt_get_users list.

    IF v_user_expandido IS NULL THEN
        RETURN NULL;
    END IF;

    -- Get Respostas
    -- JSON structure: { "pergunta_id": "...", "resposta": "...", "label": "..." }
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
    WHERE r.id_user = p_user_id; -- user_expandido foreign key

    RETURN jsonb_build_object(
        'user', v_user_expandido,
        'respostas', COALESCE(v_respostas, '[]'::jsonb)
    );
END;
$function$;
