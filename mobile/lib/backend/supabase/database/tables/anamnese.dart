import '../database.dart';

class AnamneseTable extends SupabaseTable<AnamneseRow> {
  @override
  String get tableName => 'anamnese';

  @override
  AnamneseRow createRow(Map<String, dynamic> data) => AnamneseRow(data);
}

class AnamneseRow extends SupabaseDataRow {
  AnamneseRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnamneseTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  String? get idClienteCriar => getField<String>('id_cliente_criar');
  set idClienteCriar(String? value) =>
      setField<String>('id_cliente_criar', value);

  String? get idUserClinicaCriar => getField<String>('id_user_clinica_criar');
  set idUserClinicaCriar(String? value) =>
      setField<String>('id_user_clinica_criar', value);

  String? get idClienteModificar => getField<String>('id_cliente_modificar');
  set idClienteModificar(String? value) =>
      setField<String>('id_cliente_modificar', value);

  String? get idUserClinicaModificar =>
      getField<String>('id_user_clinica_modificar');
  set idUserClinicaModificar(String? value) =>
      setField<String>('id_user_clinica_modificar', value);

  String get idModelo => getField<String>('id_modelo')!;
  set idModelo(String value) => setField<String>('id_modelo', value);

  DateTime? get criadoEm => getField<DateTime>('criado_em');
  set criadoEm(DateTime? value) => setField<DateTime>('criado_em', value);

  DateTime? get modificadoEm => getField<DateTime>('modificado_em');
  set modificadoEm(DateTime? value) =>
      setField<DateTime>('modificado_em', value);

  String? get idAtendimento => getField<String>('id_atendimento');
  set idAtendimento(String? value) => setField<String>('id_atendimento', value);
}
