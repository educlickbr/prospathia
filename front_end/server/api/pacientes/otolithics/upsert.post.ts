import { serverSupabaseClient } from '#supabase/server'

export default defineEventHandler(async (event) => {
    const client = await serverSupabaseClient(event)
    const body = await readBody(event)
    const { id, nome_completo, email, telefone, sexo, data_nascimento, id_clinica } = body

    if (!id_clinica || !nome_completo) {
        throw createError({
            statusCode: 400,
            statusMessage: 'ID Clínica and Nome Completo are required'
        })
    }

    const { data, error } = await client.rpc('nxt_upsert_paciente', {
        p_id: id || null,
        p_nome_completo: nome_completo,
        p_email: email || null,
        p_telefone: telefone || null,
        p_sexo: sexo || null,
        p_data_nascimento: data_nascimento || null,
        p_id_clinica: id_clinica
    }as any)

    if (error) {
        throw createError({
            statusCode: 500,
            statusMessage: error.message
        })
    }

    return { id: data }
})
