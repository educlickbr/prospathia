import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // Body expected: { id }
    // Passed as 'p_id' uuid to the function

    const { data, error } = await client.rpc("nxt_delete_calendario_evento", {
        p_id: body.id,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return data;
});
