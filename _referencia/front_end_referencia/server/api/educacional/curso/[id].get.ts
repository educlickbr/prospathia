import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const { id } = event.context.params as { id: string };
    const client = await serverSupabaseClient(event);

    const { data, error } = await client.rpc("nxt_get_dados_curso", {
        p_curso_id: id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
