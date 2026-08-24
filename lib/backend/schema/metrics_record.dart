import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MetricsRecord extends FirestoreRecord {
  MetricsRecord._(
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

  // "scaleMin" field.
  int? _scaleMin;
  int get scaleMin => _scaleMin ?? 0;
  bool hasScaleMin() => _scaleMin != null;

  // "scaleMax" field.
  int? _scaleMax;
  int get scaleMax => _scaleMax ?? 0;
  bool hasScaleMax() => _scaleMax != null;

  // "order" field.
  int? _order;
  int get order => _order ?? 0;
  bool hasOrder() => _order != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "domain" field.
  String? _domain;
  String get domain => _domain ?? '';
  bool hasDomain() => _domain != null;

  // "answerType" field.
  String? _answerType;
  String get answerType => _answerType ?? '';
  bool hasAnswerType() => _answerType != null;

  // "isFree" field.
  bool? _isFree;
  bool get isFree => _isFree ?? false;
  bool hasIsFree() => _isFree != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "minLabel" field.
  String? _minLabel;
  String get minLabel => _minLabel ?? '';
  bool hasMinLabel() => _minLabel != null;

  // "maxLabel" field.
  String? _maxLabel;
  String get maxLabel => _maxLabel ?? '';
  bool hasMaxLabel() => _maxLabel != null;

  // "isPredictor" field.
  bool? _isPredictor;
  bool get isPredictor => _isPredictor ?? false;
  bool hasIsPredictor() => _isPredictor != null;

  // "step" field.
  double? _step;
  double get step => _step ?? 1.0;
  bool hasStep() => _step != null;

  // "unit" field.
  String? _unit;
  String get unit => _unit ?? '';
  bool hasUnit() => _unit != null;

  void _initializeFields() {
    _metricKey = snapshotData['metricKey'] as String?;
    _metricLabel = snapshotData['metricLabel'] as String?;
    _scaleMin = castToType<int>(snapshotData['scaleMin']);
    _scaleMax = castToType<int>(snapshotData['scaleMax']);
    _order = castToType<int>(snapshotData['order']);
    _isActive = snapshotData['isActive'] as bool?;
    _domain = snapshotData['domain'] as String?;
    _answerType = snapshotData['answerType'] as String?;
    _isFree = snapshotData['isFree'] as bool?;
    _description = snapshotData['description'] as String?;
    _minLabel = snapshotData['minLabel'] as String?;
    _maxLabel = snapshotData['maxLabel'] as String?;
    _isPredictor = snapshotData['isPredictor'] as bool?;
    _step = castToType<double>(snapshotData['step']);
    _unit = snapshotData['unit'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('metrics');

  static Stream<MetricsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MetricsRecord.fromSnapshot(s));

  static Future<MetricsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MetricsRecord.fromSnapshot(s));

  static MetricsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MetricsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MetricsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MetricsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MetricsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MetricsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMetricsRecordData({
  String? metricKey,
  String? metricLabel,
  int? scaleMin,
  int? scaleMax,
  int? order,
  bool? isActive,
  String? domain,
  String? answerType,
  bool? isFree,
  String? description,
  String? minLabel,
  String? maxLabel,
  bool? isPredictor,
  double? step,
  String? unit,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'metricKey': metricKey,
      'metricLabel': metricLabel,
      'scaleMin': scaleMin,
      'scaleMax': scaleMax,
      'order': order,
      'isActive': isActive,
      'domain': domain,
      'answerType': answerType,
      'isFree': isFree,
      'description': description,
      'minLabel': minLabel,
      'maxLabel': maxLabel,
      'isPredictor': isPredictor,
      'step': step,
      'unit': unit,
    }.withoutNulls,
  );

  return firestoreData;
}

class MetricsRecordDocumentEquality implements Equality<MetricsRecord> {
  const MetricsRecordDocumentEquality();

  @override
  bool equals(MetricsRecord? e1, MetricsRecord? e2) {
    return e1?.metricKey == e2?.metricKey &&
        e1?.metricLabel == e2?.metricLabel &&
        e1?.scaleMin == e2?.scaleMin &&
        e1?.scaleMax == e2?.scaleMax &&
        e1?.order == e2?.order &&
        e1?.isActive == e2?.isActive &&
        e1?.domain == e2?.domain &&
        e1?.answerType == e2?.answerType &&
        e1?.isFree == e2?.isFree &&
        e1?.description == e2?.description &&
        e1?.minLabel == e2?.minLabel &&
        e1?.maxLabel == e2?.maxLabel &&
        e1?.isPredictor == e2?.isPredictor &&
        e1?.step == e2?.step &&
        e1?.unit == e2?.unit;
  }

  @override
  int hash(MetricsRecord? e) => const ListEquality().hash([
        e?.metricKey,
        e?.metricLabel,
        e?.scaleMin,
        e?.scaleMax,
        e?.order,
        e?.isActive,
        e?.domain,
        e?.answerType,
        e?.isFree,
        e?.description,
        e?.minLabel,
        e?.maxLabel,
        e?.isPredictor,
        e?.step,
        e?.unit
      ]);

  @override
  bool isValidKey(Object? o) => o is MetricsRecord;
}
