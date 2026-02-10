import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const id = getRouterParam(event, "id");
    const client = await serverSupabaseClient(event);

    if (!id) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing user ID",
        });
    }

    const { data, error } = await client.rpc("nxt_get_user_detalhes", {
        p_user_id: id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
