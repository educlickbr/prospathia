-- Drop function to ensure clean replacement (though OR REPLACE handles it, param names changed so DROP is safer if signature varies)
DROP FUNCTION IF EXISTS public.nxt_get_pacientes(uuid, text, integer, integer);

CREATE OR REPLACE FUNCTION public.nxt_get_pacientes(
    p_id_clinica uuid DEFAULT NULL,
    p_search text DEFAULT NULL,
    p_page integer DEFAULT 1,
    p_limit integer DEFAULT 20
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
BEGIN
    WITH dados AS (
        SELECT 
            uep.id,
            uep.nome_completo,
            uep.ultima_interacao,
            uep.data_nascimento,
            uep.status
            -- Removed columns that don't exist in user_expandido_paciente: imagem_user, email, telefone, sexo
            -- If email is needed, check if it exists in the view first. The previous working version didn't select it, 
            -- but the filter used it: OR uep.email ILIKE ... 
            -- Wait, the previous working version DID have: OR uep.email ILIKE ... in the WHERE clause?
            -- Let's check the user provided "working" version.
            -- YES, the user provided working version has: OR uep.email ILIKE ... in WHERE.
            -- BUT it only SELECTs: id, nome_completo, ultima_interacao, data_nascimento, status.
            -- So the view MUST have email, but maybe we shouldn't SELECT it if we don't need it or if it causes issues?
            -- However, the error was "uep.imagem_user does not exist". 
            -- So email likely exists, but imagem_user/telefone/sexo do not. 
            -- I will strictly SELECT only what was in the working version + maybe email if we want to display it?
            -- The working version didn't select email. I'll stick to the working version's SELECT list to be safe.
        FROM 
            public.user_expandido_paciente uep
        WHERE 
            (p_id_clinica IS NULL OR uep.id_clinica = p_id_clinica)
            AND (
                p_search IS NULL 
                OR uep.nome_completo ILIKE '%' || p_search || '%' 
                -- The previous version HAD this email filter, so email column must exist in the source, 
                -- even if not selected. I'll keep the filter if it was there.
                 OR uep.email ILIKE '%' || p_search || '%'
            )
    ),
    total AS (
        SELECT count(*) AS total FROM dados
    ),
    paginado AS (
        SELECT * FROM dados
        ORDER BY nome_completo ASC
        LIMIT p_limit OFFSET (p_page - 1) * p_limit
    )
    SELECT jsonb_build_object(
        'total', (SELECT total FROM total),
        'page', p_page,
        'limit', p_limit,
        'pages', ceil((SELECT total FROM total)::numeric / p_limit),
        'pacientes', coalesce(jsonb_agg(to_jsonb(paginado)), '[]'::jsonb)
    )
    INTO v_result
    FROM total;

    RETURN v_result;
END;
$function$;
