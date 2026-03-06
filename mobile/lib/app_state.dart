import 'package:flutter/material.dart';
import '/backend/schema/structs/index.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _grau = prefs.getInt('ff_grau') ?? _grau;
    });
    _safeInit(() {
      _TelaAtual = prefs.getString('ff_TelaAtual') ?? _TelaAtual;
    });
    _safeInit(() {
      _anguloinicial = prefs.getDouble('ff_anguloinicial') ?? _anguloinicial;
    });
    _safeInit(() {
      _mensagem = prefs.getString('ff_mensagem') ?? _mensagem;
    });
    _safeInit(() {
      _pagina = prefs.getString('ff_pagina') ?? _pagina;
    });
    _safeInit(() {
      _estadobotao = prefs.getString('ff_estadobotao') ?? _estadobotao;
    });
    _safeInit(() {
      _relogiotela = prefs.containsKey('ff_relogiotela')
          ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('ff_relogiotela')!)
          : _relogiotela;
    });
    _safeInit(() {
      _TelaAtualVerifica =
          prefs.getString('ff_TelaAtualVerifica') ?? _TelaAtualVerifica;
    });
    _safeInit(() {
      _cor = prefs.getString('ff_cor') ?? _cor;
    });
    _safeInit(() {
      _telaexame = prefs.getBool('ff_telaexame') ?? _telaexame;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  /// teste
  int _grau = 195;
  int get grau => _grau;
  set grau(int value) {
    _grau = value;
    prefs.setInt('ff_grau', value);
  }

  String _updateMessage = '';
  String get updateMessage => _updateMessage;
  set updateMessage(String value) {
    _updateMessage = value;
  }

  String _TelaAtual = 'aguardando';
  String get TelaAtual => _TelaAtual;
  set TelaAtual(String value) {
    _TelaAtual = value;
    prefs.setString('ff_TelaAtual', value);
  }

  double _angulosensor = 180.0;
  double get angulosensor => _angulosensor;
  set angulosensor(double value) {
    _angulosensor = value;
  }

  double _anguloinicial = 180.0;
  double get anguloinicial => _anguloinicial;
  set anguloinicial(double value) {
    _anguloinicial = value;
    prefs.setDouble('ff_anguloinicial', value);
  }

  String _mensagem = 'paciente';
  String get mensagem => _mensagem;
  set mensagem(String value) {
    _mensagem = value;
    prefs.setString('ff_mensagem', value);
  }

  String _pagina = '';
  String get pagina => _pagina;
  set pagina(String value) {
    _pagina = value;
    prefs.setString('ff_pagina', value);
  }

  String _estadobotao = 'Conectado';
  String get estadobotao => _estadobotao;
  set estadobotao(String value) {
    _estadobotao = value;
    prefs.setString('ff_estadobotao', value);
  }

  DateTime? _relogiotela = DateTime.fromMillisecondsSinceEpoch(1750603380000);
  DateTime? get relogiotela => _relogiotela;
  set relogiotela(DateTime? value) {
    _relogiotela = value;
    value != null
        ? prefs.setInt('ff_relogiotela', value.millisecondsSinceEpoch)
        : prefs.remove('ff_relogiotela');
  }

  String _TelaAtualVerifica = 'parear';
  String get TelaAtualVerifica => _TelaAtualVerifica;
  set TelaAtualVerifica(String value) {
    _TelaAtualVerifica = value;
    prefs.setString('ff_TelaAtualVerifica', value);
  }

  String _cor = '#FFC999';
  String get cor => _cor;
  set cor(String value) {
    _cor = value;
    prefs.setString('ff_cor', value);
  }

  bool _telaexame = false;
  bool get telaexame => _telaexame;
  set telaexame(bool value) {
    _telaexame = value;
    prefs.setBool('ff_telaexame', value);
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
