import '../database.dart';

class ClienteContratoTable extends SupabaseTable<ClienteContratoRow> {
  @override
  String get tableName => 'cliente_contrato';

  @override
  ClienteContratoRow createRow(Map<String, dynamic> data) =>
      ClienteContratoRow(data);
}

class ClienteContratoRow extends SupabaseDataRow {
  ClienteContratoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ClienteContratoTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get status => getField<String>('status')!;
  set status(String value) => setField<String>('status', value);

  DateTime? get dataCriacao => getField<DateTime>('data_criacao');
  set dataCriacao(DateTime? value) => setField<DateTime>('data_criacao', value);

  String? get idCliente => getField<String>('id_cliente');
  set idCliente(String? value) => setField<String>('id_cliente', value);
}
