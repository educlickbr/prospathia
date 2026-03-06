// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';

class AnguloUnificadoListener extends StatefulWidget {
  const AnguloUnificadoListener({
    Key? key,
    this.width,
    this.height,
    required this.canalId, // Canal Supabase (ex: id do usuário)
  }) : super(key: key);

  final double? width;
  final double? height;
  final String canalId;

  @override
  State<AnguloUnificadoListener> createState() =>
      _AnguloUnificadoListenerState();
}

class _AnguloUnificadoListenerState extends State<AnguloUnificadoListener> {
  StreamSubscription? _subscription;
  double _ultimoValor = 0;
  late RealtimeChannel _canal;

  @override
  void initState() {
    super.initState();
    _canal = Supabase.instance.client.channel(widget.canalId);
    _canal.subscribe();
    _iniciarSensor();
  }

  void _iniciarSensor() {
    _subscription = motionSensors.absoluteOrientation.listen((event) async {
      final pitchDeg = event.pitch * 180 / math.pi;

      if ((pitchDeg - _ultimoValor).abs() > 0.1) {
        _ultimoValor = pitchDeg;

        // Atualiza localmente
        FFAppState().update(() {
          FFAppState().angulosensor = pitchDeg;
        });

        // Envia por broadcast
        try {
          await _canal.sendBroadcastMessage(
            event: 'angulodispositivo',
            payload: {'valor': pitchDeg},
          );
        } catch (e) {
          print('Erro ao enviar broadcast: $e');
        }

        print('Ângulo atualizado e enviado: $pitchDeg');
      }
    }, onError: (error) {
      print("Erro no sensor: $error");
      _subscription?.cancel();
      _iniciarSensor();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _canal.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? 1,
      height: widget.height ?? 1,
      color: Colors.transparent,
    );
  }
}
