import '../database.dart';

class AnamneseRespostaTable extends SupabaseTable<AnamneseRespostaRow> {
  @override
  String get tableName => 'anamnese_resposta';

  @override
  AnamneseRespostaRow createRow(Map<String, dynamic> data) =>
      AnamneseRespostaRow(data);
}

class AnamneseRespostaRow extends SupabaseDataRow {
  AnamneseRespostaRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnamneseRespostaTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get resposta => getField<String>('resposta')!;
  set resposta(String value) => setField<String>('resposta', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String get idAnamnese => getField<String>('id_anamnese')!;
  set idAnamnese(String value) => setField<String>('id_anamnese', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  String? get idAnamneseModelo => getField<String>('id_anamnese_modelo');
  set idAnamneseModelo(String? value) =>
      setField<String>('id_anamnese_modelo', value);

  String? get idClienteCriar => getField<String>('id_cliente_criar');
  set idClienteCriar(String? value) =>
      setField<String>('id_cliente_criar', value);

  String? get idClienteModificar => getField<String>('id_cliente_modificar');
  set idClienteModificar(String? value) =>
      setField<String>('id_cliente_modificar', value);

  String? get idUserClinicaCriar => getField<String>('id_user_clinica_criar');
  set idUserClinicaCriar(String? value) =>
      setField<String>('id_user_clinica_criar', value);

  String? get idUserClinicaModificar =>
      getField<String>('id_user_clinica_modificar');
  set idUserClinicaModificar(String? value) =>
      setField<String>('id_user_clinica_modificar', value);

  DateTime? get criadoEm => getField<DateTime>('criado_em');
  set criadoEm(DateTime? value) => setField<DateTime>('criado_em', value);

  DateTime? get modificadoEm => getField<DateTime>('modificado_em');
  set modificadoEm(DateTime? value) =>
      setField<DateTime>('modificado_em', value);

  String? get idAnamnesePergunta => getField<String>('id_anamnese_pergunta');
  set idAnamnesePergunta(String? value) =>
      setField<String>('id_anamnese_pergunta', value);
}
