import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { id_item, id_kit }

    const { error } = await client.rpc("nxt_associate_kit", {
        p_id_item: body.id_item,
        p_id_kit: body.id_kit,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return { success: true };
});
