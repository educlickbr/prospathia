import '../database.dart';

class VideosHabilidadesTable extends SupabaseTable<VideosHabilidadesRow> {
  @override
  String get tableName => 'videos_habilidades';

  @override
  VideosHabilidadesRow createRow(Map<String, dynamic> data) =>
      VideosHabilidadesRow(data);
}

class VideosHabilidadesRow extends SupabaseDataRow {
  VideosHabilidadesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideosHabilidadesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);
}
