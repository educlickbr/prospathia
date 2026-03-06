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

Future subscribeCanaisFix(
  String? canal1,
  String? evento1,
  String? canal2,
  String? evento2,
  String? canal3,
  String? evento3,
  String? canal4,
  String? evento4,
) async {
  final supabase = Supabase.instance.client;

  Future<void> subscribe(String canal, String evento) async {
    final channel = supabase.channel(canal);
    channel.onBroadcast(
      event: evento,
      callback: (payload) {
        print('Evento recebido [$evento] no canal [$canal]: $payload');
      },
    );
    channel.subscribe();
    print('Inscrito: $canal | $evento');
  }

  if (canal1 != null &&
      canal1.isNotEmpty &&
      evento1 != null &&
      evento1.isNotEmpty) {
    await subscribe(canal1, evento1);
  }

  if (canal2 != null &&
      canal2.isNotEmpty &&
      evento2 != null &&
      evento2.isNotEmpty) {
    await subscribe(canal2, evento2);
  }

  if (canal3 != null &&
      canal3.isNotEmpty &&
      evento3 != null &&
      evento3.isNotEmpty) {
    await subscribe(canal3, evento3);
  }

  if (canal4 != null &&
      canal4.isNotEmpty &&
      evento4 != null &&
      evento4.isNotEmpty) {
    await subscribe(canal4, evento4);
  }
}
