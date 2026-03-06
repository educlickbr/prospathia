import '../database.dart';

class ClinicaTable extends SupabaseTable<ClinicaRow> {
  @override
  String get tableName => 'clinica';

  @override
  ClinicaRow createRow(Map<String, dynamic> data) => ClinicaRow(data);
}

class ClinicaRow extends SupabaseDataRow {
  ClinicaRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ClinicaTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get imagemClinica => getField<String>('imagem_clinica');
  set imagemClinica(String? value) => setField<String>('imagem_clinica', value);

  String? get contextoId => getField<String>('contexto_id');
  set contextoId(String? value) => setField<String>('contexto_id', value);

  String? get idCliente => getField<String>('id_cliente');
  set idCliente(String? value) => setField<String>('id_cliente', value);
}
