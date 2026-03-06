import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
    try {
        const user = await serverSupabaseUser(event)
        if (!user) {
            return { success: false, data: null, error: 'Não autorizado' }
        }

        const supabase = await serverSupabaseClient(event)

        // Chamamos a RPC em vez da tabela direta para garantir a abstração "Thick Database"
        const { data, error } = await (supabase as any)
            .rpc('vvs_get_condicoes_exame')

        if (error) {
            console.error('Erro ao buscar condicoes_exame:', error)
            return { success: false, data: null, error: error.message }
        }

        return { success: true, data }

    } catch (error: any) {
        console.error('BFF Error [vvs/condicoes-exame]:', error)
        return {
            success: false,
            data: null,
            error: error.message || 'Erro Interno'
        }
    }
})
