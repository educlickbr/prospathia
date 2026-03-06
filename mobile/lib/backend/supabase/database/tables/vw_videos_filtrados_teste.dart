import '../database.dart';

class VwVideosFiltradosTesteTable
    extends SupabaseTable<VwVideosFiltradosTesteRow> {
  @override
  String get tableName => 'vw_videos_filtrados_teste';

  @override
  VwVideosFiltradosTesteRow createRow(Map<String, dynamic> data) =>
      VwVideosFiltradosTesteRow(data);
}

class VwVideosFiltradosTesteRow extends SupabaseDataRow {
  VwVideosFiltradosTesteRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwVideosFiltradosTesteTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get nome => getField<String>('nome');
  set nome(String? value) => setField<String>('nome', value);

  String? get descricao => getField<String>('descricao');
  set descricao(String? value) => setField<String>('descricao', value);

  String? get idBunnystream => getField<String>('id_bunnystream');
  set idBunnystream(String? value) => setField<String>('id_bunnystream', value);

  String? get thumbnail => getField<String>('thumbnail');
  set thumbnail(String? value) => setField<String>('thumbnail', value);

  String? get nivel => getField<String>('nivel');
  set nivel(String? value) => setField<String>('nivel', value);

  String? get categoriaId => getField<String>('categoria_id');
  set categoriaId(String? value) => setField<String>('categoria_id', value);

  String? get categoriaNome => getField<String>('categoria_nome');
  set categoriaNome(String? value) => setField<String>('categoria_nome', value);

  String? get sugestaoUso => getField<String>('sugestao_uso');
  set sugestaoUso(String? value) => setField<String>('sugestao_uso', value);

  String? get gabarito => getField<String>('gabarito');
  set gabarito(String? value) => setField<String>('gabarito', value);

  String? get instrucaoParaPaciente =>
      getField<String>('instrucao_para_paciente');
  set instrucaoParaPaciente(String? value) =>
      setField<String>('instrucao_para_paciente', value);

  String? get instrucaoParaProfissional =>
      getField<String>('instrucao_para_profissional');
  set instrucaoParaProfissional(String? value) =>
      setField<String>('instrucao_para_profissional', value);

  List<dynamic> get grupos => getListField<dynamic>('grupos');
  set grupos(List<dynamic>? value) => setListField<dynamic>('grupos', value);

  List<dynamic> get habilidades => getListField<dynamic>('habilidades');
  set habilidades(List<dynamic>? value) =>
      setListField<dynamic>('habilidades', value);

  List<String> get gruposNomesTexto =>
      getListField<String>('grupos_nomes_texto');
  set gruposNomesTexto(List<String>? value) =>
      setListField<String>('grupos_nomes_texto', value);

  List<String> get habilidadesNomesTexto =>
      getListField<String>('habilidades_nomes_texto');
  set habilidadesNomesTexto(List<String>? value) =>
      setListField<String>('habilidades_nomes_texto', value);
}
