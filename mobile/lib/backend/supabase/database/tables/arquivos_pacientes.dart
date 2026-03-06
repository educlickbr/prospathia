import '../database.dart';

class ArquivosPacientesTable extends SupabaseTable<ArquivosPacientesRow> {
  @override
  String get tableName => 'arquivos_pacientes';

  @override
  ArquivosPacientesRow createRow(Map<String, dynamic> data) =>
      ArquivosPacientesRow(data);
}

class ArquivosPacientesRow extends SupabaseDataRow {
  ArquivosPacientesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ArquivosPacientesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  String? get idAtendimento => getField<String>('id_atendimento');
  set idAtendimento(String? value) => setField<String>('id_atendimento', value);

  String? get idClienteCriar => getField<String>('id_cliente_criar');
  set idClienteCriar(String? value) =>
      setField<String>('id_cliente_criar', value);

  String? get idUserClinicaCriar => getField<String>('id_user_clinica_criar');
  set idUserClinicaCriar(String? value) =>
      setField<String>('id_user_clinica_criar', value);

  DateTime get criadoEm => getField<DateTime>('criado_em')!;
  set criadoEm(DateTime value) => setField<DateTime>('criado_em', value);

  String get path => getField<String>('path')!;
  set path(String value) => setField<String>('path', value);

  String get nomeOriginal => getField<String>('nome_original')!;
  set nomeOriginal(String value) => setField<String>('nome_original', value);

  String? get tipoDocumento => getField<String>('tipo_documento');
  set tipoDocumento(String? value) => setField<String>('tipo_documento', value);

  int? get tamanhoBytes => getField<int>('tamanho_bytes');
  set tamanhoBytes(int? value) => setField<int>('tamanho_bytes', value);

  String? get mimeType => getField<String>('mime_type');
  set mimeType(String? value) => setField<String>('mime_type', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  String? get observacoes => getField<String>('observacoes');
  set observacoes(String? value) => setField<String>('observacoes', value);
}
