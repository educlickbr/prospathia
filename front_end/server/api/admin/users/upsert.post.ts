import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const body = await readBody(event);
    const client = await serverSupabaseClient(event);

    // Validate Body
    if (!body.user_id || !body.produto_id) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing required fields: user_id, produto_id",
        });
    }

    const { data, error } = await client.rpc("nxt_upsert_user_completo", {
        p_user_id: body.user_id,
        p_dados_user: body.dados_user || {},
        p_respostas: body.respostas || [],
        p_produto_id: body.produto_id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return { success: true };
});
