import '../database.dart';

class RoleAuthTable extends SupabaseTable<RoleAuthRow> {
  @override
  String get tableName => 'role_auth';

  @override
  RoleAuthRow createRow(Map<String, dynamic> data) => RoleAuthRow(data);
}

class RoleAuthRow extends SupabaseDataRow {
  RoleAuthRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RoleAuthTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get nomeRole => getField<String>('nome_role');
  set nomeRole(String? value) => setField<String>('nome_role', value);
}
