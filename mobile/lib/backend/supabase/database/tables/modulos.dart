import '../database.dart';

class ModulosTable extends SupabaseTable<ModulosRow> {
  @override
  String get tableName => 'modulos';

  @override
  ModulosRow createRow(Map<String, dynamic> data) => ModulosRow(data);
}

class ModulosRow extends SupabaseDataRow {
  ModulosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ModulosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get contextoId => getField<String>('contexto_id');
  set contextoId(String? value) => setField<String>('contexto_id', value);
}
