import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/instant_timer.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'parear2_model.dart';
export 'parear2_model.dart';

/// eu gostaria que essa página estivesse em orientação horizontal, fosse
/// completamente preta e tivesse duas linhas vermelhas a 0 graus em relação à
/// tela (considerando sua posição horizontal.
///
/// As duas linhas devem estar arranjadas de tal modo na tela, que ao serem
/// vistas em um óculos de realidade virtual a pessoa veja uma só.
class Parear2Widget extends StatefulWidget {
  const Parear2Widget({super.key});

  static String routeName = 'parear2';
  static String routePath = '/parear2';

  @override
  State<Parear2Widget> createState() => _Parear2WidgetState();
}

class _Parear2WidgetState extends State<Parear2Widget>
    with TickerProviderStateMixin {
  late Parear2Model _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => Parear2Model());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      FFAppState().pagina = 'pagina_parear';
      FFAppState().TelaAtual = 'inicio';
      FFAppState().relogiotela = getCurrentTimestamp;
      await actions.listenTela(
        '${currentUserUid}-tela',
      );
      await actions.listenMensagem(
        '${currentUserUid}-mensagem',
      );
      await actions.mantercaordado();
      await actions.esconderbarra();
      await ControlePareamentoTable().update(
        data: {
          'pareado_dispositivo': false,
        },
        matchingRows: (rows) => rows.eqOrNull(
          'id_user',
          currentUserUid,
        ),
      );
      if (FFAppState().telaexame == true) {
        await actions.enviarBroadcastSimples(
          '${currentUserUid}-mensagem',
          'mensagem',
          'cancelar',
        );
        FFAppState().telaexame = false;
      } else {
        FFAppState().telaexame = false;
      }

      await Future.wait([
        Future(() async {
          _model.time_parear2 = InstantTimer.periodic(
            duration: Duration(milliseconds: 500),
            callback: (timer) async {
              if (FFAppState().TelaAtual == 'parear') {
                _model.time_parear2?.cancel();
                FFAppState().TelaAtual = 'boasvindas';
                await ControlePareamentoTable().update(
                  data: {
                    'pareado_dispositivo': true,
                  },
                  matchingRows: (rows) => rows.eqOrNull(
                    'id_user',
                    currentUserUid,
                  ),
                );
                FFAppState().estadobotao = 'Conectado';

                context.goNamed(Exame2Widget.routeName);
              }
            },
            startImmediately: true,
          );
        }),
        Future(() async {
          _model.verificartempoparear2 = InstantTimer.periodic(
            duration: Duration(milliseconds: 500),
            callback: (timer) async {
              if (functions.timedif(FFAppState().relogiotela!) ==
                  DurationStruct(
                    minutes: 5,
                  )) {
                context.goNamed(ParearWidget.routeName);

                FFAppState().relogiotela = getCurrentTimestamp;
                FFAppState().estadobotao = 'Reconectar';
              }
            },
            startImmediately: true,
          );
        }),
      ]);
    });

    animationsMap.addAll({
      'imageOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.9, 0.9),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
      'buttonOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: Offset(0.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
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
        resizeToAvoidBottomInset: false,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: 100.0,
                height: 100.0,
                constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width * 1.0,
                  minHeight: MediaQuery.sizeOf(context).height * 1.0,
                ),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(48.0, 48.0, 48.0, 48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          'https://otolithics-p.b-cdn.net/logo-04.png',
                          width: 200.0,
                          height: 100.0,
                          fit: BoxFit.contain,
                        ),
                      ).animateOnPageLoad(
                          animationsMap['imageOnPageLoadAnimation']!),
                      FFButtonWidget(
                        onPressed: () async {
                          FFAppState().estadobotao = 'Conectado';
                          FFAppState().relogiotela = getCurrentTimestamp;

                          context.goNamed(ParearWidget.routeName);

                          await actions.enviarBroadcastSimples(
                            '${currentUserUid}-mensagem',
                            'mensagem',
                            'cancelar Mano2',
                          );
                        },
                        text: FFAppState().estadobotao,
                        options: FFButtonOptions(
                          height: 60.0,
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 0.0),
                          iconPadding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 0.0),
                          color: FFAppState().estadobotao == 'Reconectar'
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).secondary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.roboto(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    fontSize: 24.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ).animateOnPageLoad(
                          animationsMap['buttonOnPageLoadAnimation']!),
                    ].divide(SizedBox(height: 64.0)),
                  ),
                ),
              ),
              Container(
                width: 2.0,
                height: 2.0,
                child: custom_widgets.ListenerOnResume(
                  width: 2.0,
                  height: 2.0,
                  goOnResume: false,
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
