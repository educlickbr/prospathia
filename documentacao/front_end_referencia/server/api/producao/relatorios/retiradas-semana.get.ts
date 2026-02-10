import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);

    // Default to current date if not provided
    const dataRef = query.data || new Date().toISOString().split("T")[0];
    const turno = query.turno || "Todos";

    const { data, error } = await client.rpc(
        "nxt_get_relatorio_retiradas_dia",
        {
            p_data_ref: dataRef,
            p_turno: turno,
        } as any,
    );

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message,
        });
    }

    return data;
});
