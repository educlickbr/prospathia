import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/instant_timer.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'dart:math' as math;
import 'exame2_widget.dart' show Exame2Widget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Exame2Model extends FlutterFlowModel<Exame2Widget> {
  ///  State fields for stateful widgets in this page.

  InstantTimer? voltarparearcicloexame2;
  InstantTimer? voltarparearc2;
  InstantTimer? atualizartelaexame2;
  InstantTimer? heartbeat2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    voltarparearcicloexame2?.cancel();
    voltarparearc2?.cancel();
    atualizartelaexame2?.cancel();
    heartbeat2?.cancel();
  }
}
