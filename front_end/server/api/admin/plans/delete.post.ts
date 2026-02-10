import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    if (!body.id) {
        throw createError({
            statusCode: 400,
            statusMessage: "ID do plano é obrigatório",
        });
    }

    const { data, error } = await client.rpc("nxt_delete_plano", {
        p_id: body.id,
    });

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    if (data === false) {
        throw createError({
            statusCode: 400,
            statusMessage:
                "Não foi possível excluir o plano. Verifique se existem contratos vinculados.",
        });
    }

    return { success: true };
});
