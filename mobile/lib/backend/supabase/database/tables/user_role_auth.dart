import '../database.dart';

class UserRoleAuthTable extends SupabaseTable<UserRoleAuthRow> {
  @override
  String get tableName => 'user_role_auth';

  @override
  UserRoleAuthRow createRow(Map<String, dynamic> data) => UserRoleAuthRow(data);
}

class UserRoleAuthRow extends SupabaseDataRow {
  UserRoleAuthRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserRoleAuthTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String? get roleId => getField<String>('role_id');
  set roleId(String? value) => setField<String>('role_id', value);

  String? get clinicaId => getField<String>('clinica_id');
  set clinicaId(String? value) => setField<String>('clinica_id', value);

  String? get contextoId => getField<String>('contexto_id');
  set contextoId(String? value) => setField<String>('contexto_id', value);
}
