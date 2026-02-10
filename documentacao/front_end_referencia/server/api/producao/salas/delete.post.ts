import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    const { error } = await client.rpc("nxt_delete_sala", {
        id_sala: body.id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return { success: true };
});
