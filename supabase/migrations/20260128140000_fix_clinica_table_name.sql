
-- Migration: fix_clinica_table_name_in_rpc
-- Description: Fix table name reference from 'clinicas' to 'clinica' in nxt_credenciais_user_front RPC.

-- Re-declaring the function with CREATE OR REPLACE to overwrite the broken version.
-- Uses 'public.clinica' and 'imagem_clinica'.

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
    -- FIXED: public.clinica (singular) and imagem_clinica
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
        'clinicas', v_clinica, 
        'tem_produto', Coalesce(v_tem_produto, false)
    );
END;
$function$;
