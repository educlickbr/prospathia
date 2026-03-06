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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'exame_model.dart';
export 'exame_model.dart';

class ExameWidget extends StatefulWidget {
  const ExameWidget({super.key});

  static String routeName = 'exame';
  static String routePath = '/exame';

  @override
  State<ExameWidget> createState() => _ExameWidgetState();
}

class _ExameWidgetState extends State<ExameWidget> {
  late ExameModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ExameModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().pagina = random_data.randomString(
        2,
        6,
        true,
        false,
        false,
      );
      // telaexametrue
      FFAppState().telaexame = true;
      FFAppState().relogiotela = getCurrentTimestamp;
      FFAppState().TelaAtualVerifica = FFAppState().TelaAtual;
      await actions.esconderbarra();
      await actions.listenTela(
        '${currentUserUid}-tela',
      );
      await actions.listenAngulo(
        '${currentUserUid}-angulo',
      );
      await actions.listenMensagem(
        '${currentUserUid}-mensagem',
      );
      await actions.mantercaordado();
      await Future.wait([
        Future(() async {
          _model.voltarparearcicloexame = InstantTimer.periodic(
            duration: Duration(milliseconds: 500),
            callback: (timer) async {
              if (functions.timedif(FFAppState().relogiotela!) ==
                  DurationStruct(
                    minutes: 5,
                  )) {
                _model.voltarparearcicloexame?.cancel();
                await ControlePareamentoTable().update(
                  data: {
                    'pareado_dispositivo': false,
                  },
                  matchingRows: (rows) => rows.eqOrNull(
                    'id_user',
                    currentUserUid,
                  ),
                );
                await actions.enviarBroadcastSimples(
                  '${currentUserUid}-mensagem',
                  'mensagem',
                  'cancelar',
                );

                context.goNamed(
                  ParearWidget.routeName,
                  extra: <String, dynamic>{
                    '__transition_info__': TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                    ),
                  },
                );
              }
            },
            startImmediately: true,
          );
        }),
        Future(() async {
          _model.voltarparearc = InstantTimer.periodic(
            duration: Duration(milliseconds: 500),
            callback: (timer) async {
              if (FFAppState().TelaAtual == 'cancelar') {
                _model.voltarparearc?.cancel();
                await ControlePareamentoTable().update(
                  data: {
                    'pareado_dispositivo': false,
                  },
                  matchingRows: (rows) => rows.eqOrNull(
                    'id_user',
                    currentUserUid,
                  ),
                );

                context.goNamed(ParearWidget.routeName);
              }
            },
            startImmediately: true,
          );
        }),
        Future(() async {
          _model.atualizartelaexame = InstantTimer.periodic(
            duration: Duration(milliseconds: 500),
            callback: (timer) async {
              if (FFAppState().TelaAtual != FFAppState().TelaAtualVerifica) {
                FFAppState().relogiotela = getCurrentTimestamp;
                FFAppState().TelaAtualVerifica = FFAppState().TelaAtual;
              }
            },
            startImmediately: true,
          );
        }),
        Future(() async {
          _model.heartbeat1 = InstantTimer.periodic(
            duration: Duration(milliseconds: 15000),
            callback: (timer) async {
              await actions.enviarBroadcastSimples(
                '${currentUserUid}-mensagem',
                'mensagem',
                'heartbeat1',
              );
            },
            startImmediately: true,
          );
        }),
      ]);
      if (FFAppState().TelaAtual != FFAppState().TelaAtualVerifica) {
        FFAppState().relogiotela = getCurrentTimestamp;
        FFAppState().TelaAtualVerifica = FFAppState().TelaAtual;
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              if (FFAppState().TelaAtual == 'sobreposicao')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: Container(
                                      width: 200.0,
                                      height: 200.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF0000FF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.5,
                                    child: Container(
                                      width: 200.0,
                                      height: 200.0,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFF0000),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (FFAppState().TelaAtual == 'foco')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  'https://otolithics-p.b-cdn.net/tela_foco_16_9.png',
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  'https://otolithics-p.b-cdn.net/tela_foco_16_9.png',
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (FFAppState().TelaAtual == 'boasvindas')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      'https://otolithics-p.b-cdn.net/logo-04.png',
                                      width: MediaQuery.sizeOf(context).width *
                                          0.25,
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.25,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Bem Vindo!',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 24.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      FFAppState().mensagem,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Começaremos em instantes',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      'https://otolithics-p.b-cdn.net/logo-04.png',
                                      width: MediaQuery.sizeOf(context).width *
                                          0.25,
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.25,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Bem Vindo!',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 24.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      FFAppState().mensagem,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Começaremos em instantes',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (FFAppState().TelaAtual == 'aguardando')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      'https://otolithics-p.b-cdn.net/logo-04.png',
                                      width: MediaQuery.sizeOf(context).width *
                                          0.25,
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.25,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Aguardando',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 24.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      'https://otolithics-p.b-cdn.net/logo-04.png',
                                      width: MediaQuery.sizeOf(context).width *
                                          0.25,
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                              0.25,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Opacity(
                                    opacity: 0.4,
                                    child: Text(
                                      'Aguardando',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            fontSize: 24.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (FFAppState().TelaAtual == 'examenormal')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: functions.calcularCompensacaoLinha(
                                            FFAppState().anguloinicial,
                                            FFAppState().angulosensor) *
                                        (math.pi / 180),
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.5,
                                      height: 200.0,
                                      constraints: BoxConstraints(
                                        minWidth: 30.0,
                                        maxWidth: 30.0,
                                      ),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          fit: BoxFit.fill,
                                          image: Image.network(
                                            'https://otolithics-p.b-cdn.net/linha_oto.png',
                                          ).image,
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: functions.calcularCompensacaoLinha(
                                            FFAppState().anguloinicial,
                                            FFAppState().angulosensor) *
                                        (math.pi / 180),
                                    child: Container(
                                      width: MediaQuery.sizeOf(context).width *
                                          0.5,
                                      height: 200.0,
                                      constraints: BoxConstraints(
                                        minWidth: 30.0,
                                        maxWidth: 30.0,
                                      ),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          fit: BoxFit.fill,
                                          image: Image.network(
                                            'https://otolithics-p.b-cdn.net/linha_oto.png',
                                          ).image,
                                        ),
                                      ),
                                    ),
                                  ),
                                ].divide(SizedBox(height: 8.0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (FFAppState().TelaAtual == 'examedinamicaamtihorario')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height:
                                        MediaQuery.sizeOf(context).height * 1.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://otolithics-p.b-cdn.net/oto_bolinhas_anti_22.gif',
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.95,
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                                0.95,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Transform.rotate(
                                      angle: functions.calcularCompensacaoLinha(
                                              FFAppState().anguloinicial,
                                              FFAppState().angulosensor) *
                                          (math.pi / 180),
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.5,
                                        height: 200.0,
                                        constraints: BoxConstraints(
                                          minWidth: 30.0,
                                          maxWidth: 30.0,
                                        ),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.fill,
                                            image: Image.network(
                                              'https://otolithics-p.b-cdn.net/linha_oto.png',
                                            ).image,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height:
                                        MediaQuery.sizeOf(context).height * 1.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://otolithics-p.b-cdn.net/oto_bolinhas_anti_22.gif',
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.95,
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                                0.95,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Transform.rotate(
                                      angle: functions.calcularCompensacaoLinha(
                                              FFAppState().anguloinicial,
                                              FFAppState().angulosensor) *
                                          (math.pi / 180),
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.5,
                                        height: 200.0,
                                        constraints: BoxConstraints(
                                          minWidth: 30.0,
                                          maxWidth: 30.0,
                                        ),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.fill,
                                            image: Image.network(
                                              'https://otolithics-p.b-cdn.net/linha_oto.png',
                                            ).image,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (FFAppState().TelaAtual == 'examedinamicahorario')
                Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: MediaQuery.sizeOf(context).width * 1.0,
                    height: MediaQuery.sizeOf(context).height * 1.0,
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Container(
                      width: 693.3,
                      height: MediaQuery.sizeOf(context).height * 1.0,
                      constraints: BoxConstraints(
                        minWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                        maxWidth: functions
                            .calcularlargura(MediaQuery.sizeOf(context).height),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height:
                                        MediaQuery.sizeOf(context).height * 1.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://otolithics-p.b-cdn.net/oto_bolinhas_normal_22.gif',
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.95,
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                                0.95,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Transform.rotate(
                                      angle: functions.calcularCompensacaoLinha(
                                              FFAppState().anguloinicial,
                                              FFAppState().angulosensor) *
                                          (math.pi / 180),
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.5,
                                        height: 200.0,
                                        constraints: BoxConstraints(
                                          minWidth: 30.0,
                                          maxWidth: 30.0,
                                        ),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.fill,
                                            image: Image.network(
                                              'https://otolithics-p.b-cdn.net/linha_oto.png',
                                            ).image,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.sizeOf(context).width * 0.5,
                              height: MediaQuery.sizeOf(context).height * 1.0,
                              decoration: BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    height:
                                        MediaQuery.sizeOf(context).height * 1.0,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        'https://otolithics-p.b-cdn.net/oto_bolinhas_normal_22.gif',
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.95,
                                        height:
                                            MediaQuery.sizeOf(context).height *
                                                0.95,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                    child: Transform.rotate(
                                      angle: functions.calcularCompensacaoLinha(
                                              FFAppState().anguloinicial,
                                              FFAppState().angulosensor) *
                                          (math.pi / 180),
                                      child: Container(
                                        width:
                                            MediaQuery.sizeOf(context).width *
                                                0.5,
                                        height: 200.0,
                                        constraints: BoxConstraints(
                                          minWidth: 30.0,
                                          maxWidth: 30.0,
                                        ),
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            fit: BoxFit.fill,
                                            image: Image.network(
                                              'https://otolithics-p.b-cdn.net/linha_oto.png',
                                            ).image,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Container(
                width: 1.0,
                height: 1.0,
                child: custom_widgets.AnguloUnificadoListener(
                  width: 1.0,
                  height: 1.0,
                  canalId: '${currentUserUid}-dispositivo',
                ),
              ),
              Container(
                width: 2.0,
                height: 2.0,
                child: custom_widgets.ListenerOnResume(
                  width: 2.0,
                  height: 2.0,
                  goOnResume: true,
                  routeName: 'parear2',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
