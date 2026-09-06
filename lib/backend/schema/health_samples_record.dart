import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class HealthSamplesRecord extends FirestoreRecord {
  HealthSamplesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "type" field. Health data type as reported by the `health` package,
  // e.g. "SLEEP_ASLEEP", "STEPS", "HEART_RATE".
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  // "value" field.
  double? _value;
  double get value => _value ?? 0.0;
  bool hasValue() => _value != null;

  // "unit" field, e.g. "HOUR", "COUNT", "BEATS_PER_MINUTE".
  String? _unit;
  String get unit => _unit ?? '';
  bool hasUnit() => _unit != null;

  // "startDate" field.
  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  bool hasStartDate() => _startDate != null;

  // "endDate" field.
  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  bool hasEndDate() => _endDate != null;

  // "sourcePlatform" field: "apple_health" or "health_connect".
  String? _sourcePlatform;
  String get sourcePlatform => _sourcePlatform ?? '';
  bool hasSourcePlatform() => _sourcePlatform != null;

  // "sourceName" field: device/app that recorded the sample.
  String? _sourceName;
  String get sourceName => _sourceName ?? '';
  bool hasSourceName() => _sourceName != null;

  // "syncedAt" field.
  DateTime? _syncedAt;
  DateTime? get syncedAt => _syncedAt;
  bool hasSyncedAt() => _syncedAt != null;

  // "consentedForResearch" field.
  bool? _consentedForResearch;
  bool get consentedForResearch => _consentedForResearch ?? false;
  bool hasConsentedForResearch() => _consentedForResearch != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _type = snapshotData['type'] as String?;
    _value = castToType<double>(snapshotData['value']);
    _unit = snapshotData['unit'] as String?;
    _startDate = snapshotData['startDate'] as DateTime?;
    _endDate = snapshotData['endDate'] as DateTime?;
    _sourcePlatform = snapshotData['sourcePlatform'] as String?;
    _sourceName = snapshotData['sourceName'] as String?;
    _syncedAt = snapshotData['syncedAt'] as DateTime?;
    _consentedForResearch = snapshotData['consentedForResearch'] as bool?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('health_samples')
          : FirebaseFirestore.instance.collectionGroup('health_samples');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('health_samples').doc(id);

  static Stream<HealthSamplesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => HealthSamplesRecord.fromSnapshot(s));

  static Future<HealthSamplesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => HealthSamplesRecord.fromSnapshot(s));

  static HealthSamplesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      HealthSamplesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static HealthSamplesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      HealthSamplesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'HealthSamplesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is HealthSamplesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createHealthSamplesRecordData({
  String? type,
  double? value,
  String? unit,
  DateTime? startDate,
  DateTime? endDate,
  String? sourcePlatform,
  String? sourceName,
  DateTime? syncedAt,
  bool? consentedForResearch,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'type': type,
      'value': value,
      'unit': unit,
      'startDate': startDate,
      'endDate': endDate,
      'sourcePlatform': sourcePlatform,
      'sourceName': sourceName,
      'syncedAt': syncedAt,
      'consentedForResearch': consentedForResearch,
    }.withoutNulls,
  );

  return firestoreData;
}

class HealthSamplesRecordDocumentEquality
    implements Equality<HealthSamplesRecord> {
  const HealthSamplesRecordDocumentEquality();

  @override
  bool equals(HealthSamplesRecord? e1, HealthSamplesRecord? e2) {
    return e1?.type == e2?.type &&
        e1?.value == e2?.value &&
        e1?.unit == e2?.unit &&
        e1?.startDate == e2?.startDate &&
        e1?.endDate == e2?.endDate &&
        e1?.sourcePlatform == e2?.sourcePlatform &&
        e1?.sourceName == e2?.sourceName &&
        e1?.syncedAt == e2?.syncedAt &&
        e1?.consentedForResearch == e2?.consentedForResearch;
  }

  @override
  int hash(HealthSamplesRecord? e) => const ListEquality().hash([
        e?.type,
        e?.value,
        e?.unit,
        e?.startDate,
        e?.endDate,
        e?.sourcePlatform,
        e?.sourceName,
        e?.syncedAt,
        e?.consentedForResearch
      ]);

  @override
  bool isValidKey(Object? o) => o is HealthSamplesRecord;
}
