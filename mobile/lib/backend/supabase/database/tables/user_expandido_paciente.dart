import '../database.dart';

class UserExpandidoPacienteTable
    extends SupabaseTable<UserExpandidoPacienteRow> {
  @override
  String get tableName => 'user_expandido_paciente';

  @override
  UserExpandidoPacienteRow createRow(Map<String, dynamic> data) =>
      UserExpandidoPacienteRow(data);
}

class UserExpandidoPacienteRow extends SupabaseDataRow {
  UserExpandidoPacienteRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserExpandidoPacienteTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get nomeCompleto => getField<String>('nome_completo')!;
  set nomeCompleto(String value) => setField<String>('nome_completo', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  String? get telefone => getField<String>('telefone');
  set telefone(String? value) => setField<String>('telefone', value);

  String? get sexo => getField<String>('sexo');
  set sexo(String? value) => setField<String>('sexo', value);

  DateTime? get dataNascimento => getField<DateTime>('data_nascimento');
  set dataNascimento(DateTime? value) =>
      setField<DateTime>('data_nascimento', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  String get idClinica => getField<String>('id_clinica')!;
  set idClinica(String value) => setField<String>('id_clinica', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
