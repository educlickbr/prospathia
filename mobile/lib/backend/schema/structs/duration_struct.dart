// ignore_for_file: unnecessary_getters_setters

import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DurationStruct extends BaseStruct {
  DurationStruct({
    int? minutes,
  }) : _minutes = minutes;

  // "minutes" field.
  int? _minutes;
  int get minutes => _minutes ?? 0;
  set minutes(int? val) => _minutes = val;

  void incrementMinutes(int amount) => minutes = minutes + amount;

  bool hasMinutes() => _minutes != null;

  static DurationStruct fromMap(Map<String, dynamic> data) => DurationStruct(
        minutes: castToType<int>(data['minutes']),
      );

  static DurationStruct? maybeFromMap(dynamic data) =>
      data is Map ? DurationStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'minutes': _minutes,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'minutes': serializeParam(
          _minutes,
          ParamType.int,
        ),
      }.withoutNulls;

  static DurationStruct fromSerializableMap(Map<String, dynamic> data) =>
      DurationStruct(
        minutes: deserializeParam(
          data['minutes'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'DurationStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DurationStruct && minutes == other.minutes;
  }

  @override
  int get hashCode => const ListEquality().hash([minutes]);
}

DurationStruct createDurationStruct({
  int? minutes,
}) =>
    DurationStruct(
      minutes: minutes,
    );
