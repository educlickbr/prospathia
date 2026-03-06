import '../database.dart';

class UserRoleLogTable extends SupabaseTable<UserRoleLogRow> {
  @override
  String get tableName => 'user_role_log';

  @override
  UserRoleLogRow createRow(Map<String, dynamic> data) => UserRoleLogRow(data);
}

class UserRoleLogRow extends SupabaseDataRow {
  UserRoleLogRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserRoleLogTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get deletedAt => getField<DateTime>('deleted_at');
  set deletedAt(DateTime? value) => setField<DateTime>('deleted_at', value);

  String? get deletedBy => getField<String>('deleted_by');
  set deletedBy(String? value) => setField<String>('deleted_by', value);

  dynamic? get deletedData => getField<dynamic>('deleted_data');
  set deletedData(dynamic? value) => setField<dynamic>('deleted_data', value);
}
