import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body expected: { id_turma, data, hora_ini, hora_fim, observacoes? }
    // Passed as 'p_dados' jsonb to the function

    const { data, error } = await client.rpc(
        "nxt_upsert_calendario_turma_dia_extra",
        {
            p_dados: body,
        } as any,
    );

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return data;
});
