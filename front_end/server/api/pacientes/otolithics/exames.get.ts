import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event)
    const { patient_id } = getQuery(event)

    if (!patient_id) {
        throw createError({
            statusCode: 400,
            statusMessage: 'Patient ID is required'
        })
    }

    const { data, error } = await client.rpc('nxt_get_exames_paciente', {
        p_id_paciente: patient_id
    } as any)

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    return data
})
