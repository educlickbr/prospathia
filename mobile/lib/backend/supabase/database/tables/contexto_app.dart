import '../database.dart';

class ContextoAppTable extends SupabaseTable<ContextoAppRow> {
  @override
  String get tableName => 'contexto_app';

  @override
  ContextoAppRow createRow(Map<String, dynamic> data) => ContextoAppRow(data);
}

class ContextoAppRow extends SupabaseDataRow {
  ContextoAppRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ContextoAppTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);

  bool get ativo => getField<bool>('ativo')!;
  set ativo(bool value) => setField<bool>('ativo', value);

  DateTime? get criadoEm => getField<DateTime>('criado_em');
  set criadoEm(DateTime? value) => setField<DateTime>('criado_em', value);
}
