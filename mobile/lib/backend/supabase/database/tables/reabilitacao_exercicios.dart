import '../database.dart';

class ReabilitacaoExerciciosTable
    extends SupabaseTable<ReabilitacaoExerciciosRow> {
  @override
  String get tableName => 'reabilitacao_exercicios';

  @override
  ReabilitacaoExerciciosRow createRow(Map<String, dynamic> data) =>
      ReabilitacaoExerciciosRow(data);
}

class ReabilitacaoExerciciosRow extends SupabaseDataRow {
  ReabilitacaoExerciciosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReabilitacaoExerciciosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String get idReabilitacao => getField<String>('id_reabilitacao')!;
  set idReabilitacao(String value) =>
      setField<String>('id_reabilitacao', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  String? get instrucoesGerais => getField<String>('instrucoes_gerais');
  set instrucoesGerais(String? value) =>
      setField<String>('instrucoes_gerais', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
