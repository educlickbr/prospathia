import '../database.dart';

class VideosGruposTable extends SupabaseTable<VideosGruposRow> {
  @override
  String get tableName => 'videos_grupos';

  @override
  VideosGruposRow createRow(Map<String, dynamic> data) => VideosGruposRow(data);
}

class VideosGruposRow extends SupabaseDataRow {
  VideosGruposRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideosGruposTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);

  DateTime? get criadoEm => getField<DateTime>('criado_em');
  set criadoEm(DateTime? value) => setField<DateTime>('criado_em', value);
}
