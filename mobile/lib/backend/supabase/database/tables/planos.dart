import '../database.dart';

class PlanosTable extends SupabaseTable<PlanosRow> {
  @override
  String get tableName => 'planos';

  @override
  PlanosRow createRow(Map<String, dynamic> data) => PlanosRow(data);
}

class PlanosRow extends SupabaseDataRow {
  PlanosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PlanosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  double? get valor => getField<double>('valor');
  set valor(double? value) => setField<double>('valor', value);

  String? get contextoId => getField<String>('contexto_id');
  set contextoId(String? value) => setField<String>('contexto_id', value);
}
