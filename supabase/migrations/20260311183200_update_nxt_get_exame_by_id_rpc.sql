drop function if exists public.nxt_get_exame_by_id;
CREATE OR REPLACE FUNCTION public.nxt_get_exame_by_id(
    p_id_exame uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object(
        'id', e.id,
        'id_paciente', e.id_paciente,
        'id_profissional', e.id_profissional,
        'id_user_expandido', e.id_user_expandido,
        'id_user_clinica', e.id_user_clinica,
        'id_clinica', e.id_clinica,
        'tipo', e.tipo,
        'criado_em', e.criado_em,
        'laudo', e.laudo,
        'paciente_nome', p.nome_completo,
        'profissional_nome', COALESCE(prof.nome_completo, uc.nome_completo),
        'condicoes', COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'id', c.id,
                'id_condicao', c.id_condicao,
                'nome_condicao', ce.nome,
                'm1', c.m1,
                'm2', c.m2,
                'm3', c.m3,
                'm4', c.m4,
                'md', c.md,
                'mnd', c.mnd
            ) ORDER BY ce.nome)
            FROM public.oto_condicoes_exame_paciente c
            JOIN public.oto_condicoes_exame ce ON ce.id = c.id_condicao
            WHERE c.id_exame = e.id
            AND (c.deletado IS NULL OR c.deletado = false)
        ), '[]'::jsonb)
    )
    INTO v_result
    FROM public.oto_exames e
    LEFT JOIN public.user_expandido_paciente p ON p.id = e.id_paciente
    LEFT JOIN public.user_expandido prof ON prof.id = e.id_user_expandido
    LEFT JOIN public.user_expandido_userclinica uc ON uc.id = e.id_user_clinica
    WHERE e.id = p_id_exame;

    RETURN v_result;
END;
$function$;
