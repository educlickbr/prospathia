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
import 'exame_widget.dart' show ExameWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ExameModel extends FlutterFlowModel<ExameWidget> {
  ///  State fields for stateful widgets in this page.

  InstantTimer? voltarparearcicloexame;
  InstantTimer? voltarparearc;
  InstantTimer? atualizartelaexame;
  InstantTimer? heartbeat1;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    voltarparearcicloexame?.cancel();
    voltarparearc?.cancel();
    atualizartelaexame?.cancel();
    heartbeat1?.cancel();
  }
}
