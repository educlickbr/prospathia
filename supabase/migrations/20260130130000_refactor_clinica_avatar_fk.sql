
-- Migration: 20260130130000_refactor_clinica_avatar_fk
-- Description: Refactors clinica table to use id_arquivo_imagem_clinica (FK) instead of imagem_clinica text column.

-- 1. Schema Changes
ALTER TABLE public.clinica
ADD COLUMN IF NOT EXISTS id_arquivo_imagem_clinica uuid REFERENCES public.global_arquivos(id) ON DELETE SET NULL;

-- 2. Data Migration
-- Populate FK based on existing paths in global_arquivos
-- We strictly match on path because we just migrated them.
UPDATE public.clinica c
SET id_arquivo_imagem_clinica = ga.id
FROM public.global_arquivos ga
WHERE c.imagem_clinica = ga.path
  AND c.imagem_clinica IS NOT NULL;

-- 3. Drop Old Column
ALTER TABLE public.clinica
DROP COLUMN IF EXISTS imagem_clinica;

-- 4. Function Updates

-- 4.1. nxt_credenciais_user_front (Update 3 - User FK + Clinica FK)
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
    -- user_expandido (User Image FK)
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
            ga.path as imagem_user
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

    -- Clinica Info (Clinica Image FK)
    SELECT jsonb_build_object(
        'id', c.id,
        'nome', c.nome,
        'logo', ga.path -- Return path as logo
    ) INTO v_clinica
    FROM public.clinica_user cu
    JOIN public.clinica c ON cu.id_clinica = c.id
    LEFT JOIN public.global_arquivos ga ON c.id_arquivo_imagem_clinica = ga.id
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
