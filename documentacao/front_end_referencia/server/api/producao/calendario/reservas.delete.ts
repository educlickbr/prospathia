import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);
    const client = await serverSupabaseClient(event);

    if (!user) {
        throw createError({ statusCode: 401, statusMessage: "Unauthorized" });
    }

    const body = await readBody(event);
    const { id } = body;

    if (!id) {
        throw createError({ statusCode: 400, statusMessage: "Missing ID" });
    }

    const { error } = await client.rpc("nxt_delete_reserva", {
        p_id: id,
    } as any);

    if (error) {
        throw createError({ statusCode: 500, statusMessage: error.message });
    }

    return { success: true };
});
