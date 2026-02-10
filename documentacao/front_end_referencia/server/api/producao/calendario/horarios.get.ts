import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);

    const { data, error } = await client.rpc("nxt_get_salas_horarios");

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return data;
});
