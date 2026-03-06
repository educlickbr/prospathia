import '../database.dart';

class AnamnesePerguntaTable extends SupabaseTable<AnamnesePerguntaRow> {
  @override
  String get tableName => 'anamnese_pergunta';

  @override
  AnamnesePerguntaRow createRow(Map<String, dynamic> data) =>
      AnamnesePerguntaRow(data);
}

class AnamnesePerguntaRow extends SupabaseDataRow {
  AnamnesePerguntaRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AnamnesePerguntaTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get pergunta => getField<String>('pergunta')!;
  set pergunta(String value) => setField<String>('pergunta', value);

  String get idAnamneseModelo => getField<String>('id_anamnese_modelo')!;
  set idAnamneseModelo(String value) =>
      setField<String>('id_anamnese_modelo', value);

  String? get idClinica => getField<String>('id_clinica');
  set idClinica(String? value) => setField<String>('id_clinica', value);

  bool? get global => getField<bool>('global');
  set global(bool? value) => setField<bool>('global', value);

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

  String? get tipoPergunta => getField<String>('tipo_pergunta');
  set tipoPergunta(String? value) => setField<String>('tipo_pergunta', value);

  int? get ordem => getField<int>('ordem');
  set ordem(int? value) => setField<int>('ordem', value);
}
