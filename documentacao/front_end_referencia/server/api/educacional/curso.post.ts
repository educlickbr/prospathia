import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const body = await readBody(event);

    // We could validate the body here using Zod if needed, but for now we pass to RPC
    // The structure is expected to be { dados_curso: {...}, encontros_curso: [...] } inside body

    // RPC expects one parameter `p_dados` which is the whole JSONB object
    // So if the frontend sends the payload directly as the body, we wrap it or pass it.
    // The frontend logic constructs `payload` which matches `p_dados` structure.

    const { data, error } = await client.rpc("nxt_upsert_curso", {
        p_dados: body,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return data;
});
