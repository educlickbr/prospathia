import '../database.dart';

class ProntuariosModeloPerguntaTable
    extends SupabaseTable<ProntuariosModeloPerguntaRow> {
  @override
  String get tableName => 'prontuarios_modelo_pergunta';

  @override
  ProntuariosModeloPerguntaRow createRow(Map<String, dynamic> data) =>
      ProntuariosModeloPerguntaRow(data);
}

class ProntuariosModeloPerguntaRow extends SupabaseDataRow {
  ProntuariosModeloPerguntaRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProntuariosModeloPerguntaTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idProntuarioModelo => getField<String>('id_prontuario_modelo')!;
  set idProntuarioModelo(String value) =>
      setField<String>('id_prontuario_modelo', value);

  String get idPergunta => getField<String>('id_pergunta')!;
  set idPergunta(String value) => setField<String>('id_pergunta', value);

  int? get ordem => getField<int>('ordem');
  set ordem(int? value) => setField<int>('ordem', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

  bool? get global => getField<bool>('global');
  set global(bool? value) => setField<bool>('global', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
