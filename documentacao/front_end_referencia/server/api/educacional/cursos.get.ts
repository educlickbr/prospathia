import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);

    const { data, error } = await client.rpc("nxt_get_cursos", {
        p_area: query.area || null,
        p_nome: query.nome || null,
        p_pagina: query.pagina ? parseInt(String(query.pagina)) : 1,
        p_limite: query.limite ? parseInt(String(query.limite)) : 20,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
