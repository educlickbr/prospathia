import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/auth/supabase_auth/auth_util.dart';

double calcularCompensacaoLinha(
  double anguloinicial,
  double angulosensor,
) {
  // quero chamar a variável anguloinicial e subtrair dela a variável angulosensor
  return anguloinicial - angulosensor; // Subtrai angulosensor de anguloinicial
}

double calcularlargura(double altura) {
  return altura * (16 / 9);
}

DurationStruct timedif(DateTime tempotela) {
  final agora = DateTime.now();
  final diff = agora.difference(tempotela); // calcula diferença (Duration)
  final minutos = diff.inMinutes.abs(); // obtém diferença em minutos (absoluto)
  return DurationStruct(
      minutes: minutos); // retorna objeto 'duration' com minutos
}
