import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    const { data, error } = await client.rpc("nxt_criar_produto_com_estoque", {
        p_nome: body.nome,
        p_id_categoria: body.id_categoria,
        p_id_tipo: body.id_tipo,
        p_id_unidade: body.id_unidade,
        p_treshold: Number(body.treshold),
        p_quantidade_inicial: Number(body.quantidade_inicial),
        p_valor_inicial: Number(body.valor_inicial ?? 0),
        p_codigo_barras: body.codigo_barras || null,
        p_imagem_produto: body.imagem_produto || null,
        p_observacoes: body.observacoes || null,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
