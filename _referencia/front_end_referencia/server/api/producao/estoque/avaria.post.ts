import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { id_produto_estoque, id_produto, descricao, observacoes, status_reparo, tipo_avaria }

    const { data: newAvaria, error } = await client.rpc("nxt_create_avaria", {
        p_id_produto_estoque: body.id_produto_estoque,
        p_id_produto: body.id_produto,
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

    return { success: true, avaria: newAvaria };
});
