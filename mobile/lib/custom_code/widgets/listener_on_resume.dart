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

import 'package:flutter/scheduler.dart' show SchedulerBinding;

/// ListenerOnResume v3
/// ---------------------------------------------------------- Comportamento:
/// • Sempre grava FFAppState().estadoBotao = 'Reconectar'; • Se [goOnResume]
/// == true e [routeName] != null → navega para a rota.
///
/// Como usar em FlutterFlow: 1. Opção ✅ **Wrap With ▶️ Widget** no topo da
/// página → não precisa mexer em nada. 2. Opção ✅ **Add Widget** como um
/// filho qualquer ⟶ deixe width/height 0 ou "match parent". Neste caso o
/// [child] é opcional – se não passar nada a UI não muda.
class ListenerOnResume extends StatefulWidget {
  const ListenerOnResume({
    super.key,
    this.width,
    this.height,
    this.goOnResume = false,
    this.routeName,
    this.child,
  });

  final double? width;
  final double? height;
  final bool goOnResume; // liga/desliga navegação automática
  final String? routeName; // nome da Navigation Route
  final Widget? child; // conteúdo opcional da página

  @override
  State<ListenerOnResume> createState() => _ListenerOnResumeState();
}

class _ListenerOnResumeState extends State<ListenerOnResume>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 1️⃣ Sempre troca o texto do botão
      FFAppState().update(() => FFAppState().estadobotao = 'Reconectar');

      // 2️⃣ Navega se a flag estiver ativa
      if (widget.goOnResume && widget.routeName != null) {
        // aguarda 1 frame p/ evitar setState durante build
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.goNamed(widget.routeName!);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.child ?? const SizedBox.shrink(),
      );
}
