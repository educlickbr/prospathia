import '../database.dart';

class ProntuarioRespostasTable extends SupabaseTable<ProntuarioRespostasRow> {
  @override
  String get tableName => 'prontuario_respostas';

  @override
  ProntuarioRespostasRow createRow(Map<String, dynamic> data) =>
      ProntuarioRespostasRow(data);
}

class ProntuarioRespostasRow extends SupabaseDataRow {
  ProntuarioRespostasRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProntuarioRespostasTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idProntuario => getField<String>('id_prontuario')!;
  set idProntuario(String value) => setField<String>('id_prontuario', value);

  String get idPergunta => getField<String>('id_pergunta')!;
  set idPergunta(String value) => setField<String>('id_pergunta', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String get resposta => getField<String>('resposta')!;
  set resposta(String value) => setField<String>('resposta', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

  String? get idProntuarioModelo => getField<String>('id_prontuario_modelo');
  set idProntuarioModelo(String? value) =>
      setField<String>('id_prontuario_modelo', value);
}
