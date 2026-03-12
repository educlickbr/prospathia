import { serverSupabaseClient } from "#supabase/server";

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event);
    const query = getQuery(event);

    const start = query.start as string;
    const end = query.end as string;

    if (!start || !end) {
        throw createError({
            statusCode: 400,
            message: "Start and End dates are required",
        });
    }

    const { data, error } = await client.rpc("nxt_get_reservas_range", {
        data_inicio: start,
        data_fim: end,
    } as any);

    if (error) {
        throw createError({
            statusCode: 500,
            message: error.message,
        });
    }

    return data;
});
