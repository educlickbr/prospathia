import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);

    const page = parseInt(query.page as string) || 1;
    const limit = parseInt(query.limit as string) || 12;
    const busca = query.busca as string;
    const status = query.status as string;
    const userId = query.userId as string;

    const { data, error } = await client.rpc("nxt_get_produto_reservas", {
        p_busca: busca || null,
        p_status: status || null,
        p_pagina: page,
        p_limite: limit,
        p_id_usuario: userId || null,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
