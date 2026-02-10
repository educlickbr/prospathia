import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const client = await serverSupabaseClient(event);

    const papel_id = query.papel_id as string;
    const produto_id = query.produto_id as string;
    const empresa_id = query.empresa_id as string || null;

    if (!papel_id || !produto_id) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing required parameters: papel_id, produto_id",
        });
    }

    const { data, error } = await client.rpc("nxt_get_users", {
        p_papel_id: papel_id,
        p_produto_id: produto_id,
        p_empresa_id: empresa_id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
