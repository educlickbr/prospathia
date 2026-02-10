import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);
    const busca = query.busca ? String(query.busca) : null;

    const { data, error } = await client.rpc("nxt_get_produtos_disponiveis", {
        p_busca: busca,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
