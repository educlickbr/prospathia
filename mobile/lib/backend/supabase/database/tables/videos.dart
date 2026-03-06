import '../database.dart';

class VideosTable extends SupabaseTable<VideosRow> {
  @override
  String get tableName => 'videos';

  @override
  VideosRow createRow(Map<String, dynamic> data) => VideosRow(data);
}

class VideosRow extends SupabaseDataRow {
  VideosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VideosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idBunnystream => getField<String>('id_bunnystream')!;
  set idBunnystream(String value) => setField<String>('id_bunnystream', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get urlThumbnail => getField<String>('url_thumbnail');
  set urlThumbnail(String? value) => setField<String>('url_thumbnail', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);

  String? get instrucaoParaProfissional =>
      getField<String>('instrucao_para_profissional');
  set instrucaoParaProfissional(String? value) =>
      setField<String>('instrucao_para_profissional', value);

  String? get instrucaoParaPaciente =>
      getField<String>('instrucao_para_paciente');
  set instrucaoParaPaciente(String? value) =>
      setField<String>('instrucao_para_paciente', value);

  String? get gabarito => getField<String>('gabarito');
  set gabarito(String? value) => setField<String>('gabarito', value);

  String? get sugestaoUso => getField<String>('sugestao_uso');
  set sugestaoUso(String? value) => setField<String>('sugestao_uso', value);

  String get nivel => getField<String>('nivel')!;
  set nivel(String value) => setField<String>('nivel', value);

  String? get reabilitacaoId => getField<String>('reabilitacao_id');
  set reabilitacaoId(String? value) =>
      setField<String>('reabilitacao_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get categoriaId => getField<String>('categoria_id');
  set categoriaId(String? value) => setField<String>('categoria_id', value);
}
