import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const body = await readBody(event);
    const client = await serverSupabaseClient(event);

    const { data, error } = await client.rpc("nxt_upsert_turma", {
        p_dados: body.dados_turma,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
