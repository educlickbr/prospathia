import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);

    // Params: id_turma, data (ISO string)
    if (!query.id_turma || !query.data) {
        throw createError({
            statusCode: 400,
            message: "Parâmetros id_turma e data são obrigatórios",
        });
    }

    const { data, error } = await client.rpc("nxt_get_diario_turma_data", {
        p_id_turma: query.id_turma,
        p_data: query.data,
    } as any);

    if (error) {
        throw createError({ statusCode: 500, message: error.message });
    }

    return data;
});
