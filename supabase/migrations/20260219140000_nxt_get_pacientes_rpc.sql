CREATE OR REPLACE FUNCTION public.nxt_get_pacientes(
    p_id_clinica uuid DEFAULT NULL,
    p_search text DEFAULT NULL,
    p_limit integer DEFAULT 50,
    p_offset integer DEFAULT 0
)
RETURNS TABLE(
    id uuid,
    nome_completo text,
    ultima_interacao date,
    data_nascimento date,
    status boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
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
    ORDER BY 
        uep.nome_completo ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$;
