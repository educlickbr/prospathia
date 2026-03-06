import '../database.dart';

class ProntuariosTable extends SupabaseTable<ProntuariosRow> {
  @override
  String get tableName => 'prontuarios';

  @override
  ProntuariosRow createRow(Map<String, dynamic> data) => ProntuariosRow(data);
}

class ProntuariosRow extends SupabaseDataRow {
  ProntuariosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProntuariosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String? get idProfissional => getField<String>('id_profissional');
  set idProfissional(String? value) =>
      setField<String>('id_profissional', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  String get tipo => getField<String>('tipo')!;
  set tipo(String value) => setField<String>('tipo', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get idUserClinica => getField<String>('id_user_clinica');
  set idUserClinica(String? value) =>
      setField<String>('id_user_clinica', value);

  String? get idAtendimento => getField<String>('id_atendimento');
  set idAtendimento(String? value) => setField<String>('id_atendimento', value);

  String? get idModeloProntuario => getField<String>('id_modelo_prontuario');
  set idModeloProntuario(String? value) =>
      setField<String>('id_modelo_prontuario', value);
}
