import '../database.dart';

class UserExpandidoPacienteDetalhesTable
    extends SupabaseTable<UserExpandidoPacienteDetalhesRow> {
  @override
  String get tableName => 'user_expandido_paciente_detalhes';

  @override
  UserExpandidoPacienteDetalhesRow createRow(Map<String, dynamic> data) =>
      UserExpandidoPacienteDetalhesRow(data);
}

class UserExpandidoPacienteDetalhesRow extends SupabaseDataRow {
  UserExpandidoPacienteDetalhesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserExpandidoPacienteDetalhesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String? get antecedentesClinicos => getField<String>('antecedentes_clinicos');
  set antecedentesClinicos(String? value) =>
      setField<String>('antecedentes_clinicos', value);

  String? get antecedentesCirurgicos =>
      getField<String>('antecedentes_cirurgicos');
  set antecedentesCirurgicos(String? value) =>
      setField<String>('antecedentes_cirurgicos', value);

  String? get antecedentesFamiliares =>
      getField<String>('antecedentes_familiares');
  set antecedentesFamiliares(String? value) =>
      setField<String>('antecedentes_familiares', value);

  String? get habitos => getField<String>('habitos');
  set habitos(String? value) => setField<String>('habitos', value);

  String? get alergias => getField<String>('alergias');
  set alergias(String? value) => setField<String>('alergias', value);

  String? get medicamentosEmUso => getField<String>('medicamentos_em_uso');
  set medicamentosEmUso(String? value) =>
      setField<String>('medicamentos_em_uso', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
