import '../database.dart';

class ProntuarioPerguntasTable extends SupabaseTable<ProntuarioPerguntasRow> {
  @override
  String get tableName => 'prontuario_perguntas';

  @override
  ProntuarioPerguntasRow createRow(Map<String, dynamic> data) =>
      ProntuarioPerguntasRow(data);
}

class ProntuarioPerguntasRow extends SupabaseDataRow {
  ProntuarioPerguntasRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProntuarioPerguntasTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get pergunta => getField<String>('pergunta')!;
  set pergunta(String value) => setField<String>('pergunta', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  bool? get global => getField<bool>('global');
  set global(bool? value) => setField<bool>('global', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

  String get tipoResposta => getField<String>('tipo_resposta')!;
  set tipoResposta(String value) => setField<String>('tipo_resposta', value);
}
