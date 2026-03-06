import '../database.dart';

class PlanosModulosTable extends SupabaseTable<PlanosModulosRow> {
  @override
  String get tableName => 'planos_modulos';

  @override
  PlanosModulosRow createRow(Map<String, dynamic> data) =>
      PlanosModulosRow(data);
}

class PlanosModulosRow extends SupabaseDataRow {
  PlanosModulosRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PlanosModulosTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get planoId => getField<String>('plano_id')!;
  set planoId(String value) => setField<String>('plano_id', value);

  String get moduloId => getField<String>('modulo_id')!;
  set moduloId(String value) => setField<String>('modulo_id', value);

  bool get disponivel => getField<bool>('disponivel')!;
  set disponivel(bool value) => setField<bool>('disponivel', value);

  bool get temLimite => getField<bool>('tem_limite')!;
  set temLimite(bool value) => setField<bool>('tem_limite', value);
}
