-- Migration: Adiciona a RPC nxt_get_oto_condicoes_exame
-- Retorna todos os registros da tabela oto_condicoes_exame ordenados por cod_condicao

CREATE OR REPLACE FUNCTION public.nxt_get_oto_condicoes_exame()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    v_result jsonb;
BEGIN
    SELECT coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',           c.id,
                'nome',         c.nome,
                'label',        c.label,
                'cod_condicao', c.cod_condicao,
                'amaxdir',      c.amaxdir,
                'amaxesq',      c.amaxesq,
                'amindir',      c.amindir,
                'aminesq',      c.aminesq,
                'aidealcab',    c.aidealcab,
                'amincab',      c.amincab,
                'amaxcab',      c.amaxcab,
                'created_at',   c.created_at
            )
            ORDER BY c.cod_condicao ASC
        ),
        '[]'::jsonb
    )
    INTO v_result
    FROM public.oto_condicoes_exame c;

    RETURN v_result;
END;
$function$;
