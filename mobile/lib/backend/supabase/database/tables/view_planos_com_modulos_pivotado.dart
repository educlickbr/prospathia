import '../database.dart';

class ViewPlanosComModulosPivotadoTable
    extends SupabaseTable<ViewPlanosComModulosPivotadoRow> {
  @override
  String get tableName => 'view_planos_com_modulos_pivotado';

  @override
  ViewPlanosComModulosPivotadoRow createRow(Map<String, dynamic> data) =>
      ViewPlanosComModulosPivotadoRow(data);
}

class ViewPlanosComModulosPivotadoRow extends SupabaseDataRow {
  ViewPlanosComModulosPivotadoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewPlanosComModulosPivotadoTable();

  String? get planoId => getField<String>('plano_id');
  set planoId(String? value) => setField<String>('plano_id', value);

  String? get planoNome => getField<String>('plano_nome');
  set planoNome(String? value) => setField<String>('plano_nome', value);

  String? get contextoId => getField<String>('contexto_id');
  set contextoId(String? value) => setField<String>('contexto_id', value);

  String? get idPlanoModuloAvaliacao =>
      getField<String>('id_plano_modulo_avaliacao');
  set idPlanoModuloAvaliacao(String? value) =>
      setField<String>('id_plano_modulo_avaliacao', value);

  bool? get avaliacaoDisponivel => getField<bool>('avaliacao_disponivel');
  set avaliacaoDisponivel(bool? value) =>
      setField<bool>('avaliacao_disponivel', value);

  bool? get avaliacaoTemLimite => getField<bool>('avaliacao_tem_limite');
  set avaliacaoTemLimite(bool? value) =>
      setField<bool>('avaliacao_tem_limite', value);

  String? get idLimiteAvaliacao => getField<String>('id_limite_avaliacao');
  set idLimiteAvaliacao(String? value) =>
      setField<String>('id_limite_avaliacao', value);

  int? get avaliacaoLimiteUsuarios =>
      getField<int>('avaliacao_limite_usuarios');
  set avaliacaoLimiteUsuarios(int? value) =>
      setField<int>('avaliacao_limite_usuarios', value);

  String? get idPlanoModuloColaboradores =>
      getField<String>('id_plano_modulo_colaboradores');
  set idPlanoModuloColaboradores(String? value) =>
      setField<String>('id_plano_modulo_colaboradores', value);

  bool? get colaboradoresDisponivel =>
      getField<bool>('colaboradores_disponivel');
  set colaboradoresDisponivel(bool? value) =>
      setField<bool>('colaboradores_disponivel', value);

  bool? get colaboradoresTemLimite =>
      getField<bool>('colaboradores_tem_limite');
  set colaboradoresTemLimite(bool? value) =>
      setField<bool>('colaboradores_tem_limite', value);

  String? get idLimiteColaboradores =>
      getField<String>('id_limite_colaboradores');
  set idLimiteColaboradores(String? value) =>
      setField<String>('id_limite_colaboradores', value);

  int? get colaboradoresLimiteUsuarios =>
      getField<int>('colaboradores_limite_usuarios');
  set colaboradoresLimiteUsuarios(int? value) =>
      setField<int>('colaboradores_limite_usuarios', value);

  String? get idPlanoModuloQuestionario =>
      getField<String>('id_plano_modulo_questionario');
  set idPlanoModuloQuestionario(String? value) =>
      setField<String>('id_plano_modulo_questionario', value);

  bool? get questionarioDisponivel => getField<bool>('questionario_disponivel');
  set questionarioDisponivel(bool? value) =>
      setField<bool>('questionario_disponivel', value);

  bool? get questionarioTemLimite => getField<bool>('questionario_tem_limite');
  set questionarioTemLimite(bool? value) =>
      setField<bool>('questionario_tem_limite', value);

  String? get idLimiteQuestionario =>
      getField<String>('id_limite_questionario');
  set idLimiteQuestionario(String? value) =>
      setField<String>('id_limite_questionario', value);

  int? get questionarioLimiteUsuarios =>
      getField<int>('questionario_limite_usuarios');
  set questionarioLimiteUsuarios(int? value) =>
      setField<int>('questionario_limite_usuarios', value);

  String? get idPlanoModuloReabilitacao =>
      getField<String>('id_plano_modulo_reabilitacao');
  set idPlanoModuloReabilitacao(String? value) =>
      setField<String>('id_plano_modulo_reabilitacao', value);

  bool? get reabilitacaoDisponivel => getField<bool>('reabilitacao_disponivel');
  set reabilitacaoDisponivel(bool? value) =>
      setField<bool>('reabilitacao_disponivel', value);

  bool? get reabilitacaoTemLimite => getField<bool>('reabilitacao_tem_limite');
  set reabilitacaoTemLimite(bool? value) =>
      setField<bool>('reabilitacao_tem_limite', value);

  String? get idLimiteReabilitacao =>
      getField<String>('id_limite_reabilitacao');
  set idLimiteReabilitacao(String? value) =>
      setField<String>('id_limite_reabilitacao', value);

  int? get reabilitacaoLimiteUsuarios =>
      getField<int>('reabilitacao_limite_usuarios');
  set reabilitacaoLimiteUsuarios(int? value) =>
      setField<int>('reabilitacao_limite_usuarios', value);

  String? get idPlanoModuloClinica =>
      getField<String>('id_plano_modulo_clinica');
  set idPlanoModuloClinica(String? value) =>
      setField<String>('id_plano_modulo_clinica', value);

  bool? get clinicaDisponivel => getField<bool>('clinica_disponivel');
  set clinicaDisponivel(bool? value) =>
      setField<bool>('clinica_disponivel', value);

  bool? get clinicaTemLimite => getField<bool>('clinica_tem_limite');
  set clinicaTemLimite(bool? value) =>
      setField<bool>('clinica_tem_limite', value);

  String? get idLimiteClinica => getField<String>('id_limite_clinica');
  set idLimiteClinica(String? value) =>
      setField<String>('id_limite_clinica', value);

  int? get clinicaLimiteUsuarios => getField<int>('clinica_limite_usuarios');
  set clinicaLimiteUsuarios(int? value) =>
      setField<int>('clinica_limite_usuarios', value);

  String? get idPlanoModuloClinicaOto =>
      getField<String>('id_plano_modulo_clinica_oto');
  set idPlanoModuloClinicaOto(String? value) =>
      setField<String>('id_plano_modulo_clinica_oto', value);

  bool? get clinicaOtoDisponivel => getField<bool>('clinica_oto_disponivel');
  set clinicaOtoDisponivel(bool? value) =>
      setField<bool>('clinica_oto_disponivel', value);

  bool? get clinicaOtoTemLimite => getField<bool>('clinica_oto_tem_limite');
  set clinicaOtoTemLimite(bool? value) =>
      setField<bool>('clinica_oto_tem_limite', value);

  String? get idLimiteClinicaOto => getField<String>('id_limite_clinica_oto');
  set idLimiteClinicaOto(String? value) =>
      setField<String>('id_limite_clinica_oto', value);

  int? get clinicaOtoLimiteUsuarios =>
      getField<int>('clinica_oto_limite_usuarios');
  set clinicaOtoLimiteUsuarios(int? value) =>
      setField<int>('clinica_oto_limite_usuarios', value);

  String? get idPlanoModuloExamesOto =>
      getField<String>('id_plano_modulo_exames_oto');
  set idPlanoModuloExamesOto(String? value) =>
      setField<String>('id_plano_modulo_exames_oto', value);

  bool? get examesOtoDisponivel => getField<bool>('exames_oto_disponivel');
  set examesOtoDisponivel(bool? value) =>
      setField<bool>('exames_oto_disponivel', value);

  bool? get examesOtoTemLimite => getField<bool>('exames_oto_tem_limite');
  set examesOtoTemLimite(bool? value) =>
      setField<bool>('exames_oto_tem_limite', value);

  String? get idLimiteExamesOto => getField<String>('id_limite_exames_oto');
  set idLimiteExamesOto(String? value) =>
      setField<String>('id_limite_exames_oto', value);

  int? get examesOtoLimiteUsuarios =>
      getField<int>('exames_oto_limite_usuarios');
  set examesOtoLimiteUsuarios(int? value) =>
      setField<int>('exames_oto_limite_usuarios', value);
}
