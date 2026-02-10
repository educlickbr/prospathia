import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);
    const produto_id = query.produto_id as string;

    if (!produto_id) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing produto_id",
        });
    }

    const { data, error } = await client.rpc("nxt_get_planos", {
        p_produto_id: produto_id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
