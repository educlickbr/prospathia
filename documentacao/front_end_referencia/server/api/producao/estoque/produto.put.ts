import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    const { data, error } = await client.rpc("nxt_atualizar_produto", {
        p_id: body.id,
        p_nome: body.nome,
        p_id_categoria_produto: body.id_categoria_produto,
        p_id_tipo_produto: body.id_tipo_produto,
        p_id_unidade: body.id_unidade,
        p_treshold: Number(body.treshold),
        p_valor_inicial: Number(body.valor_inicial),
        p_codigo_barras: body.codigo_barras || null,
        p_observacoes: body.observacoes || null,
        p_imagem_produto: body.imagem_produto || null,
        p_mostrar_mais: body.mostrar_mais ?? false,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
