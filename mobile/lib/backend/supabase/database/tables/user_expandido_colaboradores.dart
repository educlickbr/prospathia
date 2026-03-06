import '../database.dart';

class UserExpandidoColaboradoresTable
    extends SupabaseTable<UserExpandidoColaboradoresRow> {
  @override
  String get tableName => 'user_expandido_colaboradores';

  @override
  UserExpandidoColaboradoresRow createRow(Map<String, dynamic> data) =>
      UserExpandidoColaboradoresRow(data);
}

class UserExpandidoColaboradoresRow extends SupabaseDataRow {
  UserExpandidoColaboradoresRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserExpandidoColaboradoresTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get nomeCompleto => getField<String>('nome_completo')!;
  set nomeCompleto(String value) => setField<String>('nome_completo', value);

  String get cpf => getField<String>('cpf')!;
  set cpf(String value) => setField<String>('cpf', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  String? get telefone => getField<String>('telefone');
  set telefone(String? value) => setField<String>('telefone', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String get roleId => getField<String>('role_id')!;
  set roleId(String value) => setField<String>('role_id', value);

  String? get imagemUser => getField<String>('imagem_user');
  set imagemUser(String? value) => setField<String>('imagem_user', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  String get clinicaId => getField<String>('clinica_id')!;
  set clinicaId(String value) => setField<String>('clinica_id', value);
}
