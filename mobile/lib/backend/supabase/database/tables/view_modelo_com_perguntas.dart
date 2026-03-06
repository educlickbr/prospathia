import '../database.dart';

class ViewModeloComPerguntasTable
    extends SupabaseTable<ViewModeloComPerguntasRow> {
  @override
  String get tableName => 'view_modelo_com_perguntas';

  @override
  ViewModeloComPerguntasRow createRow(Map<String, dynamic> data) =>
      ViewModeloComPerguntasRow(data);
}

class ViewModeloComPerguntasRow extends SupabaseDataRow {
  ViewModeloComPerguntasRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ViewModeloComPerguntasTable();

  String? get idModelo => getField<String>('id_modelo');
  set idModelo(String? value) => setField<String>('id_modelo', value);

  String? get nomeModelo => getField<String>('nome_modelo');
  set nomeModelo(String? value) => setField<String>('nome_modelo', value);

  String? get idPergunta => getField<String>('id_pergunta');
  set idPergunta(String? value) => setField<String>('id_pergunta', value);

  String? get pergunta => getField<String>('pergunta');
  set pergunta(String? value) => setField<String>('pergunta', value);

  String? get tipoResposta => getField<String>('tipo_resposta');
  set tipoResposta(String? value) => setField<String>('tipo_resposta', value);

  int? get ordem => getField<int>('ordem');
  set ordem(int? value) => setField<int>('ordem', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

  bool? get global => getField<bool>('global');
  set global(bool? value) => setField<bool>('global', value);
}
