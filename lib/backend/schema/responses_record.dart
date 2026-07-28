import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ResponsesRecord extends FirestoreRecord {
  ResponsesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "metricKey" field.
  String? _metricKey;
  String get metricKey => _metricKey ?? '';
  bool hasMetricKey() => _metricKey != null;

  // "metricLabel" field.
  String? _metricLabel;
  String get metricLabel => _metricLabel ?? '';
  bool hasMetricLabel() => _metricLabel != null;

  // "capturedAt" field.
  DateTime? _capturedAt;
  DateTime? get capturedAt => _capturedAt;
  bool hasCapturedAt() => _capturedAt != null;

  // "valueNumber" field.
  double? _valueNumber;
  double get valueNumber => _valueNumber ?? 0.0;
  bool hasValueNumber() => _valueNumber != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _metricKey = snapshotData['metricKey'] as String?;
    _metricLabel = snapshotData['metricLabel'] as String?;
    _capturedAt = snapshotData['capturedAt'] as DateTime?;
    _valueNumber = castToType<double>(snapshotData['valueNumber']);
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('responses')
          : FirebaseFirestore.instance.collectionGroup('responses');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('responses').doc(id);

  static Stream<ResponsesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ResponsesRecord.fromSnapshot(s));

  static Future<ResponsesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ResponsesRecord.fromSnapshot(s));

  static ResponsesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ResponsesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ResponsesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ResponsesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ResponsesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ResponsesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createResponsesRecordData({
  String? metricKey,
  String? metricLabel,
  DateTime? capturedAt,
  double? valueNumber,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'metricKey': metricKey,
      'metricLabel': metricLabel,
      'capturedAt': capturedAt,
      'valueNumber': valueNumber,
    }.withoutNulls,
  );

  return firestoreData;
}

class ResponsesRecordDocumentEquality implements Equality<ResponsesRecord> {
  const ResponsesRecordDocumentEquality();

  @override
  bool equals(ResponsesRecord? e1, ResponsesRecord? e2) {
    return e1?.metricKey == e2?.metricKey &&
        e1?.metricLabel == e2?.metricLabel &&
        e1?.capturedAt == e2?.capturedAt &&
        e1?.valueNumber == e2?.valueNumber;
  }

  @override
  int hash(ResponsesRecord? e) => const ListEquality()
      .hash([e?.metricKey, e?.metricLabel, e?.capturedAt, e?.valueNumber]);

  @override
  bool isValidKey(Object? o) => o is ResponsesRecord;
}
