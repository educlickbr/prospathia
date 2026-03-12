import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body: { id_turma, eventos: [...], ajuste?, encontros_extras?... }
    // Passed as 'p_resultado' jsonb to the function

    // Note: nxt_upsert_calendario_turma expects (p_id_turma, p_resultado)
    const { id_turma, ...rest } = body;

    const { data, error } = await client.rpc("nxt_upsert_calendario_turma", {
        p_id_turma: id_turma,
        p_resultado: rest,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return data;
});
