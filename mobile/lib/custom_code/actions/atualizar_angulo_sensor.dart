// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:math' as math;
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';

Completer? _listenerCompleter;

Future atualizarAnguloSensor() async {
  if (_listenerCompleter != null && !_listenerCompleter!.isCompleted) {
    return;
  }

  _listenerCompleter = Completer();

  motionSensors.absoluteOrientation.listen((event) {
    final pitch = event.pitch;
    final pitchDeg = pitch * 180 / math.pi;

    FFAppState().angulosensor = pitchDeg;
  });

  _listenerCompleter!.complete();
}
