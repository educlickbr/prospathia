import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);

    const { data, error } = await client.rpc("nxt_get_produtos", {
        p_busca: query.busca ? String(query.busca) : null,
        p_categoria: query.categoria ? String(query.categoria) : null,
        p_tipo: query.tipo ? String(query.tipo) : null,
        p_pagina: query.page ? Number(query.page) : 1,
        p_limite: query.limit ? Number(query.limit) : 10,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
