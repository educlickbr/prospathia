import '../database.dart';

class ProntuariosModeloTable extends SupabaseTable<ProntuariosModeloRow> {
  @override
  String get tableName => 'prontuarios_modelo';

  @override
  ProntuariosModeloRow createRow(Map<String, dynamic> data) =>
      ProntuariosModeloRow(data);
}

class ProntuariosModeloRow extends SupabaseDataRow {
  ProntuariosModeloRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProntuariosModeloTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

  bool? get global => getField<bool>('global');
  set global(bool? value) => setField<bool>('global', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
