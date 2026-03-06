import '../database.dart';

class VideosCategoriasTable extends SupabaseTable<VideosCategoriasRow> {
  @override
  String get tableName => 'videos_categorias';

  @override
  VideosCategoriasRow createRow(Map<String, dynamic> data) =>
      VideosCategoriasRow(data);
}

class VideosCategoriasRow extends SupabaseDataRow {
  VideosCategoriasRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideosCategoriasTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);
}
