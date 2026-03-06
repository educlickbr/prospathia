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

import 'package:supabase_flutter/supabase_flutter.dart';

Future listenAngulo(String canal) async {
  final supabase = Supabase.instance.client;
  final channel = supabase.channel(canal);

  channel.onBroadcast(
    event: '*',
    callback: (payload) {
      if ((payload['event'] ?? '') == 'angulo') {
        final data = payload['payload'];
        FFAppState().update(() {
          FFAppState().anguloinicial = data is Map && data['valor'] != null
              ? double.tryParse(data['valor'].toString()) ?? 0.0
              : 0.0;
        });
      }
    },
  );
  channel.subscribe();
}
