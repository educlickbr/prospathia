import { serverSupabaseClient } from '#supabase/server';

export default defineEventHandler(async (event) => {
  const supabase = await serverSupabaseClient(event);
  const body = await readBody(event);

  const { id_paciente, id_clinica, id_user_expandido, condicoes } = body;

  if (!id_paciente || !id_clinica || !id_user_expandido || !condicoes) {
    throw createError({
      statusCode: 400,
      statusMessage: 'Faltam parâmetros obrigatórios para salvar o exame.'
    });
  }

  // Chama a RPC para inserir o Exame e as Condições em cascata
  const { data: exameId, error } = await supabase.rpc('nxt_create_oto_exame_paciente', {
    p_id_paciente: id_paciente,
    p_id_clinica: id_clinica,
    p_id_user_expandido: id_user_expandido,
    p_condicoes: condicoes
  } as any);

  if (error) {
    console.error('[VVS_BFF] Erro ao salvar exame:', error);
    throw createError({
      statusCode: 500,
      statusMessage: `Erro DB: ${error.message}`,
      message: `Erro Supabase (Hint: ${error.hint || error.details || 'Sem detalhes adic.'})`,
      data: error
    });
  }

  return { 
    sucesso: true, 
    id_exame: exameId 
  };
});
