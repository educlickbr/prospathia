import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event)
    const { id_clinica, search, page, limit } = getQuery(event)

    const { data, error } = await client.rpc('nxt_get_pacientes', {
        p_id_clinica: id_clinica || null,
        p_search: search || null,
        p_page: page ? parseInt(page as string) : 1,
        p_limit: limit ? parseInt(limit as string) : 20
    } as any)

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    return data
})
