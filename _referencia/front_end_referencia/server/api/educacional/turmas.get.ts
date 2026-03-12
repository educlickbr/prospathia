import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    const { data, error } = await client.rpc("nxt_get_turmas_admin", {
        p_area: query.area ? String(query.area) : null,
        p_ano_semestre: query.ano_semestre ? String(query.ano_semestre) : null,
        p_nome_curso: query.nome ? String(query.nome) : null,
        p_pagina: query.pagina ? Number(query.pagina) : 1,
        p_limite: query.limite ? Number(query.limite) : 20,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
