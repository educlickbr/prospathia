import '../database.dart';

class RelacionamentoClientePacienteColaboradorTable
    extends SupabaseTable<RelacionamentoClientePacienteColaboradorRow> {
  @override
  String get tableName => 'relacionamento_cliente_paciente_colaborador';

  @override
  RelacionamentoClientePacienteColaboradorRow createRow(
          Map<String, dynamic> data) =>
      RelacionamentoClientePacienteColaboradorRow(data);
}

class RelacionamentoClientePacienteColaboradorRow extends SupabaseDataRow {
  RelacionamentoClientePacienteColaboradorRow(Map<String, dynamic> data)
      : super(data);

  @override
  SupabaseTable get table => RelacionamentoClientePacienteColaboradorTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get clienteId => getField<String>('cliente_id')!;
  set clienteId(String value) => setField<String>('cliente_id', value);

  String get pacienteId => getField<String>('paciente_id')!;
  set pacienteId(String value) => setField<String>('paciente_id', value);

  String? get tipoRelacionamento => getField<String>('tipo_relacionamento');
  set tipoRelacionamento(String? value) =>
      setField<String>('tipo_relacionamento', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
