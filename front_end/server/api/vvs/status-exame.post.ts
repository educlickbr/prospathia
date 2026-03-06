import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
    try {
        const body = await readBody(event)
        const newStatus = body.status

        if (typeof newStatus !== 'boolean') {
            throw createError({ statusCode: 400, statusMessage: 'Status do exame (booleano) é obrigatório.' })
        }

        // Verifica o cookie e autentica
        const user = await serverSupabaseUser(event)
        const userId = user?.id || (user as any)?.sub || (user as any)?.user?.id;
        
        if (!user || !userId || userId === 'undefined') {
            throw createError({ statusCode: 401, statusMessage: 'Não autorizado ou sessão corrompida.' })
        }

        // Usa o cliente de server protegido (Service Role se configurado, ou role authenticada)
        const supabase = await serverSupabaseClient(event)

        // Verificamos antes para não quebrar constraints
        const { data: existingRecords, error: fetchError } = await (supabase as any)
            .from('controle_pareamento')
            .select('id')
            .eq('id_user', userId)
            .limit(1)

        if (fetchError) {
             console.error('BFF Fetch Error:', fetchError)
             throw createError({ statusCode: 500, statusMessage: 'Erro ao buscar controle de pareamento' })
        }

        if (existingRecords && existingRecords.length > 0) {
            const { error: updateError } = await (supabase as any)
                .from('controle_pareamento')
                .update({ exame_iniciado: newStatus })
                .eq('id_user', userId)
            
            if (updateError) throw createError({ statusCode: 500, statusMessage: 'Erro ao atualizar controle de pareamento' })
        } else {
            const { error: insertError } = await (supabase as any)
                .from('controle_pareamento')
                .insert({ id_user: userId, exame_iniciado: newStatus })
            
            if (insertError) throw createError({ statusCode: 500, statusMessage: 'Erro ao criar controle de pareamento' })
        }

        return { success: true, status: newStatus }

    } catch (error: any) {
        console.error('BFF Error [vvs/status-exame]:', error)
        throw createError({
            statusCode: error.statusCode || 500,
            statusMessage: error.message || 'Erro Interno no Servidor',
        })
    }
})
