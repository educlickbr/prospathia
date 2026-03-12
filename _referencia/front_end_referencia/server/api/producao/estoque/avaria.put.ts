import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { id, descricao, observacoes, status_reparo, tipo_avaria }

    const { error } = await client.rpc("nxt_update_avaria", {
        p_id: body.id,
        p_descricao: body.descricao,
        p_observacoes: body.observacoes,
        p_status_reparo: body.status_reparo,
        p_tipo_avaria: body.tipo_avaria || null,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return { success: true };
});
