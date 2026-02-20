import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event)
    const id = getRouterParam(event, 'id')

    if (!id) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Exam ID is required'
        })
    }

    const { data, error } = await client.rpc('nxt_get_exame_by_id', {
        p_id_exame: id
    } as any)

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    // RPC returns JSONB, so data is already the object or null
    if (!data) {
        throw createError({
            statusCode: 404,
            statusMessage: 'Exam not found'
        })
    }

    return data
})
