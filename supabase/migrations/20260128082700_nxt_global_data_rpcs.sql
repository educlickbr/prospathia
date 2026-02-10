
-- Migration: nxt_global_data_rpcs
-- Description: Implement RPCs for product verification and fetching user frontend credentials.

-- 1. nxt_verificar_produto
CREATE OR REPLACE FUNCTION public.nxt_verificar_produto(p_dominio text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_dominio text := p_dominio;
    v_produto record;
BEGIN
    -- Fallback Logic for Localhost
    IF v_dominio ILIKE '%localhost%' OR v_dominio ILIKE '%127.0.0.1%' THEN
        v_dominio := 'https://otolithics.com/';
    END IF;

    -- Fetch product details
    SELECT id, nome, logo_maior, logo_menor, ativo 
    INTO v_produto
    FROM public.produtos
    WHERE dominio = v_dominio
    LIMIT 1;

    IF v_produto IS NULL THEN
        RETURN jsonb_build_object('encontrado', false);
    END IF;

    RETURN jsonb_build_object(
        'encontrado', true,
        'id', v_produto.id,
        'nome', v_produto.nome,
        'logo_maior', v_produto.logo_maior,
        'logo_menor', v_produto.logo_menor,
        'ativo', v_produto.ativo
    );
END;
$function$;

-- 2. nxt_credenciais_user_front
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
    -- Get User Expandido
    SELECT to_jsonb(ue.*) INTO v_user_expandido
    FROM public.user_expandido ue
    WHERE ue.user_id = v_user_id
    LIMIT 1;

    -- Get Roles
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

    -- Get Clinica Info (Primary)
    -- Assuming join with public.clinica
    SELECT jsonb_build_object(
        'id', c.id,
        'nome', c.nome,
        'logo', c.imagem_clinica
    ) INTO v_clinica
    FROM public.clinica_user cu
    JOIN public.clinica c ON cu.id_clinica = c.id
    WHERE cu.id_user = v_user_id
    LIMIT 1;

    -- Check Product Access
    SELECT EXISTS (
        SELECT 1 FROM public.produtos_user pu
        WHERE pu.user_id = v_user_id AND pu.produto_id = p_produto_id AND pu.status = true
    ) INTO v_tem_produto;

    RETURN jsonb_build_object(
        'user', v_user_expandido,
        'roles', COALESCE(v_roles, '[]'::jsonb),
        'clinicas', v_clinica, -- User might have multiple but we pick one for now or change to list if needed. Assuming single context.
        'tem_produto', Coalesce(v_tem_produto, false)
    );
END;
$function$;
