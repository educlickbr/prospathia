import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { ids: string[], status: string }

    const { data, error } = await client.rpc("nxt_update_reserva_status", {
        p_ids: body.ids,
        p_new_status: body.status,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
