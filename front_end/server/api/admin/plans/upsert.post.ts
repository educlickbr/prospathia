import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Validate essential fields
    if (!body.produto_id || !body.nome || !body.valor) {
        throw createError({
            statusCode: 400,
            statusMessage: "Campos obrigatórios: produto_id, nome, valor",
        });
    }

    const { data, error } = await client.rpc("nxt_upsert_plano", {
        p_id: body.id || null, // null for create
        p_produto_id: body.produto_id,
        p_nome: body.nome,
        p_descricao: body.descricao || null,
        p_valor: body.valor,
        p_intervalo: body.intervalo || "month",
        p_stripe_price_id: body.stripe_price_id || null,
        p_stripe_product_id: body.stripe_product_id || null,
    });

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return { success: true, id: data };
});
