import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { ids: string[] }

    const { error } = await client.rpc("nxt_delete_reserva", {
        p_ids: body.ids,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return { success: true };
});
