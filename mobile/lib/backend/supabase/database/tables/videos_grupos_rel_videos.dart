import '../database.dart';

class VideosGruposRelVideosTable
    extends SupabaseTable<VideosGruposRelVideosRow> {
  @override
  String get tableName => 'videos_grupos_rel_videos';

  @override
  VideosGruposRelVideosRow createRow(Map<String, dynamic> data) =>
      VideosGruposRelVideosRow(data);
}

class VideosGruposRelVideosRow extends SupabaseDataRow {
  VideosGruposRelVideosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideosGruposRelVideosTable();

  String get videoId => getField<String>('video_id')!;
  set videoId(String value) => setField<String>('video_id', value);

  String get grupoId => getField<String>('grupo_id')!;
  set grupoId(String value) => setField<String>('grupo_id', value);
}
