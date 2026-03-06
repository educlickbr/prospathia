import '../database.dart';

class ReabilitacaoExerciciosVideosTable
    extends SupabaseTable<ReabilitacaoExerciciosVideosRow> {
  @override
  String get tableName => 'reabilitacao_exercicios_videos';

  @override
  ReabilitacaoExerciciosVideosRow createRow(Map<String, dynamic> data) =>
      ReabilitacaoExerciciosVideosRow(data);
}

class ReabilitacaoExerciciosVideosRow extends SupabaseDataRow {
  ReabilitacaoExerciciosVideosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReabilitacaoExerciciosVideosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idReabilitacaoExercicio =>
      getField<String>('id_reabilitacao_exercicio')!;
  set idReabilitacaoExercicio(String value) =>
      setField<String>('id_reabilitacao_exercicio', value);

  String get idVideo => getField<String>('id_video')!;
  set idVideo(String value) => setField<String>('id_video', value);

  String? get instrucaoAuxiliar => getField<String>('instrucao_auxiliar');
  set instrucaoAuxiliar(String? value) =>
      setField<String>('instrucao_auxiliar', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
