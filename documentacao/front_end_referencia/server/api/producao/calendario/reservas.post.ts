import { serverSupabaseClient, serverSupabaseUser } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const user = await serverSupabaseUser(event);
    const client = await serverSupabaseClient(event);

    if (!user) {
        throw createError({ statusCode: 401, statusMessage: "Unauthorized" });
    }

    const body = await readBody(event);
    const { reservas, user_id } = body;

    // Use passed ID
    const userExpandidoId = user_id;

    if (!userExpandidoId) {
        throw createError({
            statusCode: 400,
            statusMessage: "Missing User ID",
        });
    }

    // 2. Call Batch Upsert RPC
    const { error } = await client.rpc("nxt_upsert_reserva_batch", {
        p_reservas: reservas,
        p_user_id: userExpandidoId,
    } as any);

    if (error) {
        throw createError({ statusCode: 500, statusMessage: error.message });
    }

    return { success: true };
});
