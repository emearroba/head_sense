// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class LatLonStruct extends FFFirebaseStruct {
  LatLonStruct({
    LatLng? latLon,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _latLon = latLon,
        super(firestoreUtilData);

  // "latLon" field.
  LatLng? _latLon;
  LatLng? get latLon => _latLon;
  set latLon(LatLng? val) => _latLon = val;

  bool hasLatLon() => _latLon != null;

  static LatLonStruct fromMap(Map<String, dynamic> data) => LatLonStruct(
        latLon: data['latLon'] as LatLng?,
      );

  static LatLonStruct? maybeFromMap(dynamic data) =>
      data is Map ? LatLonStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'latLon': _latLon,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'latLon': serializeParam(
          _latLon,
          ParamType.LatLng,
        ),
      }.withoutNulls;

  static LatLonStruct fromSerializableMap(Map<String, dynamic> data) =>
      LatLonStruct(
        latLon: deserializeParam(
          data['latLon'],
          ParamType.LatLng,
          false,
        ),
      );

  @override
  String toString() => 'LatLonStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is LatLonStruct && latLon == other.latLon;
  }

  @override
  int get hashCode => const ListEquality().hash([latLon]);
}

LatLonStruct createLatLonStruct({
  LatLng? latLon,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    LatLonStruct(
      latLon: latLon,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

LatLonStruct? updateLatLonStruct(
  LatLonStruct? latLonStruct, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    latLonStruct
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addLatLonStructData(
  Map<String, dynamic> firestoreData,
  LatLonStruct? latLonStruct,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (latLonStruct == null) {
    return;
  }
  if (latLonStruct.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && latLonStruct.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final latLonStructData = getLatLonFirestoreData(latLonStruct, forFieldValue);
  final nestedData =
      latLonStructData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = latLonStruct.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getLatLonFirestoreData(
  LatLonStruct? latLonStruct, [
  bool forFieldValue = false,
]) {
  if (latLonStruct == null) {
    return {};
  }
  final firestoreData = mapToFirestore(latLonStruct.toMap());

  // Add any Firestore field values
  mapToFirestore(latLonStruct.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getLatLonListFirestoreData(
  List<LatLonStruct>? latLonStructs,
) =>
    latLonStructs?.map((e) => getLatLonFirestoreData(e, true)).toList() ?? [];
