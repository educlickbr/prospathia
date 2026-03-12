import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event); // Expects { id_produto, quantidade, valor_inicial?, ... }

    const { data, error } = await client.rpc("nxt_adicionar_estoque_lote", {
        p_id_produto: body.id_produto,
        p_quantidade: body.quantidade,
        p_valor_inicial: body.valor_inicial ?? 0,
        p_id_sala: body.id_sala ?? null,
        p_observacoes: body.observacoes ?? null,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
