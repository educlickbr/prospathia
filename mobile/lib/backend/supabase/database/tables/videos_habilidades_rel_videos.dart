import '../database.dart';

class VideosHabilidadesRelVideosTable
    extends SupabaseTable<VideosHabilidadesRelVideosRow> {
  @override
  String get tableName => 'videos_habilidades_rel_videos';

  @override
  VideosHabilidadesRelVideosRow createRow(Map<String, dynamic> data) =>
      VideosHabilidadesRelVideosRow(data);
}

class VideosHabilidadesRelVideosRow extends SupabaseDataRow {
  VideosHabilidadesRelVideosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideosHabilidadesRelVideosTable();

  String get videoId => getField<String>('video_id')!;
  set videoId(String value) => setField<String>('video_id', value);

  String get habilidadeId => getField<String>('habilidade_id')!;
  set habilidadeId(String value) => setField<String>('habilidade_id', value);
}
