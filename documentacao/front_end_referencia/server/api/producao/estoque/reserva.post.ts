import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { id_usuario, id_produto, quantidade, data_retirada, data_devolucao }

    const { data, error } = await client.rpc("nxt_create_reserva_batch", {
        p_id_usuario: body.id_usuario,
        p_id_produto: body.id_produto,
        p_quantidade: body.quantidade,
        p_data_retirada: body.data_retirada,
        p_data_devolucao: body.data_devolucao,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
