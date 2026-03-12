import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const query = getQuery(event);
    const id_turma = query.id_turma;
    const client = await serverSupabaseClient(event);

    if (!id_turma) {
        throw createError({
            statusCode: 400,
            statusMessage: "id_turma required",
        });
    }

    const { data, error } = await client.rpc("nxt_get_turma_calendario", {
        p_id_turma: id_turma,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
