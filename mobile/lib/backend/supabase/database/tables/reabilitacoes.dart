import '../database.dart';

class ReabilitacoesTable extends SupabaseTable<ReabilitacoesRow> {
  @override
  String get tableName => 'reabilitacoes';

  @override
  ReabilitacoesRow createRow(Map<String, dynamic> data) =>
      ReabilitacoesRow(data);
}

class ReabilitacoesRow extends SupabaseDataRow {
  ReabilitacoesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReabilitacoesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);
}
