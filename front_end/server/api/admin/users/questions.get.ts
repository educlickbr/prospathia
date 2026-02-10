import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    const papel_id = query.papel_id as string;

    if (!papel_id) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing required parameter: papel_id",
        });
    }

    const { data, error } = await client.rpc("nxt_get_perguntas_painel", {
        p_papel_id: papel_id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
