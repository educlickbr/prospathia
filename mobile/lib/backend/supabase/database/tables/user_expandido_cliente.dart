import '../database.dart';

class UserExpandidoClienteTable extends SupabaseTable<UserExpandidoClienteRow> {
  @override
  String get tableName => 'user_expandido_cliente';

  @override
  UserExpandidoClienteRow createRow(Map<String, dynamic> data) =>
      UserExpandidoClienteRow(data);
}

class UserExpandidoClienteRow extends SupabaseDataRow {
  UserExpandidoClienteRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserExpandidoClienteTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String get tipoJuridicoFisico => getField<String>('tipo_juridico_fisico')!;
  set tipoJuridicoFisico(String value) =>
      setField<String>('tipo_juridico_fisico', value);

  String get nomeCompleto => getField<String>('nome_completo')!;
  set nomeCompleto(String value) => setField<String>('nome_completo', value);

  String? get sexo => getField<String>('sexo');
  set sexo(String? value) => setField<String>('sexo', value);

  DateTime? get dataNascimento => getField<DateTime>('data_nascimento');
  set dataNascimento(DateTime? value) =>
      setField<DateTime>('data_nascimento', value);

  String get cpf => getField<String>('cpf')!;
  set cpf(String value) => setField<String>('cpf', value);

  String? get rg => getField<String>('rg');
  set rg(String? value) => setField<String>('rg', value);

  String? get tipoCredenciamento => getField<String>('tipo_credenciamento');
  set tipoCredenciamento(String? value) =>
      setField<String>('tipo_credenciamento', value);

  String? get numeroCredenciamento => getField<String>('numero_credenciamento');
  set numeroCredenciamento(String? value) =>
      setField<String>('numero_credenciamento', value);

  String? get telefone => getField<String>('telefone');
  set telefone(String? value) => setField<String>('telefone', value);

  String? get cep => getField<String>('cep');
  set cep(String? value) => setField<String>('cep', value);

  String? get endereco => getField<String>('endereco');
  set endereco(String? value) => setField<String>('endereco', value);

  String? get numero => getField<String>('numero');
  set numero(String? value) => setField<String>('numero', value);

  String? get complemento => getField<String>('complemento');
  set complemento(String? value) => setField<String>('complemento', value);

  String? get bairro => getField<String>('bairro');
  set bairro(String? value) => setField<String>('bairro', value);

  String? get cidade => getField<String>('cidade');
  set cidade(String? value) => setField<String>('cidade', value);

  String? get estado => getField<String>('estado');
  set estado(String? value) => setField<String>('estado', value);

  String? get pais => getField<String>('pais');
  set pais(String? value) => setField<String>('pais', value);

  String? get roleId => getField<String>('role_id');
  set roleId(String? value) => setField<String>('role_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String get email => getField<String>('email')!;
  set email(String value) => setField<String>('email', value);

  bool? get status => getField<bool>('status');
  set status(bool? value) => setField<bool>('status', value);

  String? get planoId => getField<String>('plano_id');
  set planoId(String? value) => setField<String>('plano_id', value);

  String? get razaoSocial => getField<String>('razao_social');
  set razaoSocial(String? value) => setField<String>('razao_social', value);

  String? get cnpj => getField<String>('cnpj');
  set cnpj(String? value) => setField<String>('cnpj', value);

  String? get clinicaId => getField<String>('clinica_id');
  set clinicaId(String? value) => setField<String>('clinica_id', value);

  String? get imagemUser => getField<String>('imagem_user');
  set imagemUser(String? value) => setField<String>('imagem_user', value);

  String? get contextoId => getField<String>('contexto_id');
  set contextoId(String? value) => setField<String>('contexto_id', value);
}
