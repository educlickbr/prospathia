CREATE OR REPLACE FUNCTION public.nxt_upsert_paciente(
    p_id uuid DEFAULT NULL,
    p_nome_completo text DEFAULT NULL,
    p_email text DEFAULT NULL,
    p_telefone text DEFAULT NULL,
    p_sexo text DEFAULT NULL,
    p_data_nascimento date DEFAULT NULL,
    p_id_clinica uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_id uuid;
BEGIN
    -- Validation
    IF p_nome_completo IS NULL OR p_id_clinica IS NULL THEN
        RAISE EXCEPTION 'Nome completo and ID Clinica are required';
    END IF;

    IF p_id IS NOT NULL THEN
        -- UPDATE
        UPDATE public.user_expandido_paciente
        SET
            nome_completo = p_nome_completo,
            email = p_email,
            telefone = p_telefone,
            sexo = p_sexo,
            data_nascimento = p_data_nascimento
        WHERE id = p_id AND id_clinica = p_id_clinica
        RETURNING id INTO v_id;
        
        IF v_id IS NULL THEN
             RAISE EXCEPTION 'Patient not found or permission denied';
        END IF;
    ELSE
        -- INSERT
        INSERT INTO public.user_expandido_paciente (
            nome_completo,
            email,
            telefone,
            sexo,
            data_nascimento,
            id_clinica,
            status
        ) VALUES (
            p_nome_completo,
            p_email,
            p_telefone,
            p_sexo,
            p_data_nascimento,
            p_id_clinica,
            true
        )
        RETURNING id INTO v_id;
    END IF;

    RETURN v_id;
END;
$function$;
