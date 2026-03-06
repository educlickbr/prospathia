import { serverSupabaseClient, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
    try {
        // Autentica via cookie
        const user = await serverSupabaseUser(event)
        const userId = user?.id || (user as any)?.sub || (user as any)?.user?.id;
        
        if (!user || !userId || userId === 'undefined') {
            return { success: false, pareado: false, error: 'Não autorizado ou sessão corrompida' }
        }

        // Cliente Server-Side protegido (tem by-pass ou role-auth limpa pelo Nuxt)
        const supabase = await serverSupabaseClient(event)

        const { data: records, error } = await (supabase as any)
            .from('controle_pareamento')
            .select('pareado_dispositivo')
            .eq('id_user', userId)
            .limit(1)

        if (error) {
            console.error('Erro na query check-pareamento:', error)
            return { 
                success: false, 
                pareado: false, 
                error: error // Retornamos o erro sem explodir a API
            }
        }

        const isPareado = records && records.length > 0 ? records[0].pareado_dispositivo : false;

        return { 
            success: true, 
            pareado: isPareado
        }

    } catch (error: any) {
        console.error('BFF Error [vvs/check-pareamento]:', error)
        return {
            success: false,
            pareado: false,
            error: error.message || 'Erro Interno'
        }
    }
})
