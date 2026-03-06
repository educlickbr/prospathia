import '../database.dart';

class AnamneseModeloTable extends SupabaseTable<AnamneseModeloRow> {
  @override
  String get tableName => 'anamnese_modelo';

  @override
  AnamneseModeloRow createRow(Map<String, dynamic> data) =>
      AnamneseModeloRow(data);
}

class AnamneseModeloRow extends SupabaseDataRow {
  AnamneseModeloRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnamneseModeloTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nome => getField<String>('nome')!;
  set nome(String value) => setField<String>('nome', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

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

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  bool? get global => getField<bool>('global');
  set global(bool? value) => setField<bool>('global', value);
}
