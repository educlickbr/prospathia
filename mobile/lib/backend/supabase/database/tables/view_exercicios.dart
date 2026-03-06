import '../database.dart';

class ViewExerciciosTable extends SupabaseTable<ViewExerciciosRow> {
  @override
  String get tableName => 'view_exercicios';

  @override
  ViewExerciciosRow createRow(Map<String, dynamic> data) =>
      ViewExerciciosRow(data);
}

class ViewExerciciosRow extends SupabaseDataRow {
  ViewExerciciosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewExerciciosTable();

  String? get idExercicio => getField<String>('id_exercicio');
  set idExercicio(String? value) => setField<String>('id_exercicio', value);

  String? get idPaciente => getField<String>('id_paciente');
  set idPaciente(String? value) => setField<String>('id_paciente', value);

  String? get nomePaciente => getField<String>('nome_paciente');
  set nomePaciente(String? value) => setField<String>('nome_paciente', value);

  String? get idReabilitacao => getField<String>('id_reabilitacao');
  set idReabilitacao(String? value) =>
      setField<String>('id_reabilitacao', value);

  String? get nomeReabilitacao => getField<String>('nome_reabilitacao');
  set nomeReabilitacao(String? value) =>
      setField<String>('nome_reabilitacao', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  int? get quantidadeVideos => getField<int>('quantidade_videos');
  set quantidadeVideos(int? value) => setField<int>('quantidade_videos', value);
}
