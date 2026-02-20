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
        FROM 
            public.user_expandido_paciente uep
        WHERE 
            (p_id_clinica IS NULL OR uep.id_clinica = p_id_clinica)
            AND (
                p_search IS NULL 
                OR uep.nome_completo ILIKE '%' || p_search || '%' 
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
        'pacientes', (SELECT coalesce(jsonb_agg(row_to_json(p)), '[]'::jsonb) FROM paginado p)
    )
    INTO v_result;

    RETURN v_result;
END;
$function$;
