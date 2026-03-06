import '../database.dart';

class ClientePagamentoContratoTable
    extends SupabaseTable<ClientePagamentoContratoRow> {
  @override
  String get tableName => 'cliente_pagamento_contrato';

  @override
  ClientePagamentoContratoRow createRow(Map<String, dynamic> data) =>
      ClientePagamentoContratoRow(data);
}

class ClientePagamentoContratoRow extends SupabaseDataRow {
  ClientePagamentoContratoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ClientePagamentoContratoTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get idContrato => getField<String>('id_contrato')!;
  set idContrato(String value) => setField<String>('id_contrato', value);

  int? get mesIndex => getField<int>('mes_index');
  set mesIndex(int? value) => setField<int>('mes_index', value);

  DateTime get dataField => getField<DateTime>('data')!;
  set dataField(DateTime value) => setField<DateTime>('data', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);
}
