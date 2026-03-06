import '../database.dart';

class AtendimentosTable extends SupabaseTable<AtendimentosRow> {
  @override
  String get tableName => 'atendimentos';

  @override
  AtendimentosRow createRow(Map<String, dynamic> data) => AtendimentosRow(data);
}

class AtendimentosRow extends SupabaseDataRow {
  AtendimentosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AtendimentosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idPaciente => getField<String>('id_paciente')!;
  set idPaciente(String value) => setField<String>('id_paciente', value);

  String get idProfissional => getField<String>('id_profissional')!;
  set idProfissional(String value) =>
      setField<String>('id_profissional', value);

  String? get idUserClinica => getField<String>('id_user_clinica');
  set idUserClinica(String? value) =>
      setField<String>('id_user_clinica', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  DateTime? get dataReserva => getField<DateTime>('data_reserva');
  set dataReserva(DateTime? value) => setField<DateTime>('data_reserva', value);

  DateTime? get dataInicio => getField<DateTime>('data_inicio');
  set dataInicio(DateTime? value) => setField<DateTime>('data_inicio', value);

  DateTime? get dataFim => getField<DateTime>('data_fim');
  set dataFim(DateTime? value) => setField<DateTime>('data_fim', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);
}
