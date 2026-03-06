import '../database.dart';

class ControlePareamentoTable extends SupabaseTable<ControlePareamentoRow> {
  @override
  String get tableName => 'controle_pareamento';

  @override
  ControlePareamentoRow createRow(Map<String, dynamic> data) =>
      ControlePareamentoRow(data);
}

class ControlePareamentoRow extends SupabaseDataRow {
  ControlePareamentoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ControlePareamentoTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idUser => getField<String>('id_user')!;
  set idUser(String value) => setField<String>('id_user', value);

  bool? get pareadoDispositivo => getField<bool>('pareado_dispositivo');
  set pareadoDispositivo(bool? value) =>
      setField<bool>('pareado_dispositivo', value);

  bool? get exameIniciado => getField<bool>('exame_iniciado');
  set exameIniciado(bool? value) => setField<bool>('exame_iniciado', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
