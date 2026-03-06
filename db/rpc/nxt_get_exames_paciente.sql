CREATE OR REPLACE FUNCTION public.nxt_get_exames_paciente(
    p_id_paciente uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
BEGIN
    WITH dados_condicoes AS (
        SELECT
            c.id_exame,
            ce.nome AS nome_condicao,
            c.md,
            c.mnd
        FROM
            public.oto_condicoes_exame_paciente c
            JOIN public.oto_condicoes_exame ce ON ce.id = c.id_condicao
    ),
    condicoes_pivot AS (
        SELECT
            dados_condicoes.id_exame,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'neutra' THEN dados_condicoes.md ELSE NULL END) AS neutra_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'neutra' THEN dados_condicoes.mnd ELSE NULL END) AS neutra_mnd,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'estatica_direita' THEN dados_condicoes.md ELSE NULL END) AS estatica_direita_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'estatica_direita' THEN dados_condicoes.mnd ELSE NULL END) AS estatica_direita_mnd,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'estatica_esquerda' THEN dados_condicoes.md ELSE NULL END) AS estatica_esquerda_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'estatica_esquerda' THEN dados_condicoes.mnd ELSE NULL END) AS estatica_esquerda_mnd,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'dinamica_horario' THEN dados_condicoes.md ELSE NULL END) AS dinamica_horario_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'dinamica_horario' THEN dados_condicoes.mnd ELSE NULL END) AS dinamica_horario_mnd,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'dinamica_antihorario' THEN dados_condicoes.md ELSE NULL END) AS dinamica_antihorario_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'dinamica_antihorario' THEN dados_condicoes.mnd ELSE NULL END) AS dinamica_antihorario_mnd,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'haptica_direita' THEN dados_condicoes.md ELSE NULL END) AS haptica_direita_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'haptica_direita' THEN dados_condicoes.mnd ELSE NULL END) AS haptica_direita_mnd,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'haptica_esquerda' THEN dados_condicoes.md ELSE NULL END) AS haptica_esquerda_md,
            MAX(CASE WHEN dados_condicoes.nome_condicao = 'haptica_esquerda' THEN dados_condicoes.mnd ELSE NULL END) AS haptica_esquerda_mnd
        FROM
            dados_condicoes
        GROUP BY
            dados_condicoes.id_exame
    ),
    exames_completos AS (
        SELECT
            e.id,
            e.id_paciente,
            e.id_profissional,
            e.id_user_clinica,
            e.id_clinica,
            e.tipo,
            e.criado_em,
            e.criado_por,
            e.modificado_em,
            e.modificado_por,
            e.deletado,
            e.laudo,
            COALESCE(p.nome_completo, uc.nome_completo) AS nome_profissional_ou_userclinica,
            cp.neutra_md,
            cp.neutra_mnd,
            cp.estatica_direita_md,
            cp.estatica_direita_mnd,
            cp.estatica_esquerda_md,
            cp.estatica_esquerda_mnd,
            cp.dinamica_horario_md,
            cp.dinamica_horario_mnd,
            cp.dinamica_antihorario_md,
            cp.dinamica_antihorario_mnd,
            cp.haptica_direita_md,
            cp.haptica_direita_mnd,
            cp.haptica_esquerda_md,
            cp.haptica_esquerda_mnd
        FROM
            public.oto_exames e
            LEFT JOIN public.user_expandido_cliente p ON p.id = e.id_profissional
            LEFT JOIN public.user_expandido_userclinica uc ON uc.id = e.id_user_clinica
            LEFT JOIN condicoes_pivot cp ON cp.id_exame = e.id
        WHERE
            e.id_paciente = p_id_paciente
            AND (e.deletado IS NULL OR e.deletado = false)
        ORDER BY
            e.criado_em DESC
    )
    SELECT coalesce(jsonb_agg(to_jsonb(exames_completos)), '[]'::jsonb)
    INTO v_result
    FROM exames_completos;

    RETURN v_result;
END;
$function$;
