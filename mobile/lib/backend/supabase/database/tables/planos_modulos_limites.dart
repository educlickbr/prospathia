import '../database.dart';

class PlanosModulosLimitesTable extends SupabaseTable<PlanosModulosLimitesRow> {
  @override
  String get tableName => 'planos_modulos_limites';

  @override
  PlanosModulosLimitesRow createRow(Map<String, dynamic> data) =>
      PlanosModulosLimitesRow(data);
}

class PlanosModulosLimitesRow extends SupabaseDataRow {
  PlanosModulosLimitesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PlanosModulosLimitesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get planoModuloId => getField<String>('plano_modulo_id')!;
  set planoModuloId(String value) => setField<String>('plano_modulo_id', value);

  int get limiteUsuarios => getField<int>('limite_usuarios')!;
  set limiteUsuarios(int value) => setField<int>('limite_usuarios', value);
}
