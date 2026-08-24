import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DashboardRecord extends FirestoreRecord {
  DashboardRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "metricRef" field.
  DocumentReference? _metricRef;
  DocumentReference? get metricRef => _metricRef;
  bool hasMetricRef() => _metricRef != null;

  // "periodStart" field.
  DateTime? _periodStart;
  DateTime? get periodStart => _periodStart;
  bool hasPeriodStart() => _periodStart != null;

  // "periodEnd" field.
  DateTime? _periodEnd;
  DateTime? get periodEnd => _periodEnd;
  bool hasPeriodEnd() => _periodEnd != null;

  // "symptomDays" field.
  int? _symptomDays;
  int get symptomDays => _symptomDays ?? 0;
  bool hasSymptomDays() => _symptomDays != null;

  // "symptomKey" field.
  String? _symptomKey;
  String get symptomKey => _symptomKey ?? '';
  bool hasSymptomKey() => _symptomKey != null;

  // "metricKey" field.
  String? _metricKey;
  String get metricKey => _metricKey ?? '';
  bool hasMetricKey() => _metricKey != null;

  // "symptomFreeDays" field.
  int? _symptomFreeDays;
  int get symptomFreeDays => _symptomFreeDays ?? 0;
  bool hasSymptomFreeDays() => _symptomFreeDays != null;

  // "missingDays" field.
  int? _missingDays;
  int get missingDays => _missingDays ?? 0;
  bool hasMissingDays() => _missingDays != null;

  // "incompleteDays" field.
  int? _incompleteDays;
  int get incompleteDays => _incompleteDays ?? 0;
  bool hasIncompleteDays() => _incompleteDays != null;

  // "metricLabel" field.
  String? _metricLabel;
  String get metricLabel => _metricLabel ?? '';
  bool hasMetricLabel() => _metricLabel != null;

  // "trackingDay" field.
  int? _trackingDay;
  int get trackingDay => _trackingDay ?? 0;
  bool hasTrackingDay() => _trackingDay != null;

  // "dailyValues" field.
  List<DailyValueStruct>? _dailyValues;
  List<DailyValueStruct> get dailyValues => _dailyValues ?? const [];
  bool hasDailyValues() => _dailyValues != null;

  // "periodType" field.
  String? _periodType;
  String get periodType => _periodType ?? '';
  bool hasPeriodType() => _periodType != null;

  // "moderateSymptomDays" field.
  int? _moderateSymptomDays;
  int get moderateSymptomDays => _moderateSymptomDays ?? 0;
  bool hasModerateSymptomDays() => _moderateSymptomDays != null;

  // "mildSymptomDays" field.
  int? _mildSymptomDays;
  int get mildSymptomDays => _mildSymptomDays ?? 0;
  bool hasMildSymptomDays() => _mildSymptomDays != null;

  // "severeSymptomDays" field.
  int? _severeSymptomDays;
  int get severeSymptomDays => _severeSymptomDays ?? 0;
  bool hasSevereSymptomDays() => _severeSymptomDays != null;

  // "painkillerDays" field.
  int? _painkillerDays;
  int get painkillerDays => _painkillerDays ?? 0;
  bool hasPainkillerDays() => _painkillerDays != null;

  // "periodDays" field.
  int? _periodDays;
  int get periodDays => _periodDays ?? 0;
  bool hasPeriodDays() => _periodDays != null;

  // "completionRate" field.
  double? _completionRate;
  double get completionRate => _completionRate ?? 0.0;
  bool hasCompletionRate() => _completionRate != null;

  // "symptomRate" field.
  double? _symptomRate;
  double get symptomRate => _symptomRate ?? 0.0;
  bool hasSymptomRate() => _symptomRate != null;

  // "meanIntensitySymptomDays" field.
  double? _meanIntensitySymptomDays;
  double get meanIntensitySymptomDays => _meanIntensitySymptomDays ?? 0.0;
  bool hasMeanIntensitySymptomDays() => _meanIntensitySymptomDays != null;

  // "meanIntensityTrackedDays" field.
  double? _meanIntensityTrackedDays;
  double get meanIntensityTrackedDays => _meanIntensityTrackedDays ?? 0.0;
  bool hasMeanIntensityTrackedDays() => _meanIntensityTrackedDays != null;

  // "spikeCount" field.
  int? _spikeCount;
  int get spikeCount => _spikeCount ?? 0;
  bool hasSpikeCount() => _spikeCount != null;

  // "currentSevereStreak" field.
  int? _currentSevereStreak;
  int get currentSevereStreak => _currentSevereStreak ?? 0;
  bool hasCurrentSevereStreak() => _currentSevereStreak != null;

  // "longestSevereStreak" field.
  int? _longestSevereStreak;
  int get longestSevereStreak => _longestSevereStreak ?? 0;
  bool hasLongestSevereStreak() => _longestSevereStreak != null;

  // "currentCrystalStreak" field.
  int? _currentCrystalStreak;
  int get currentCrystalStreak => _currentCrystalStreak ?? 0;
  bool hasCurrentCrystalStreak() => _currentCrystalStreak != null;

  // "longestCrystalStreak" field.
  int? _longestCrystalStreak;
  int get longestCrystalStreak => _longestCrystalStreak ?? 0;
  bool hasLongestCrystalStreak() => _longestCrystalStreak != null;

  // "currentMissingStreak" field.
  int? _currentMissingStreak;
  int get currentMissingStreak => _currentMissingStreak ?? 0;
  bool hasCurrentMissingStreak() => _currentMissingStreak != null;

  // "periodHasEnoughData" field.
  bool? _periodHasEnoughData;
  bool get periodHasEnoughData => _periodHasEnoughData ?? false;
  bool hasPeriodHasEnoughData() => _periodHasEnoughData != null;

  // "analysisEligible" field.
  bool? _analysisEligible;
  bool get analysisEligible => _analysisEligible ?? false;
  bool hasAnalysisEligible() => _analysisEligible != null;

  void _initializeFields() {
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _metricRef = snapshotData['metricRef'] as DocumentReference?;
    _periodStart = snapshotData['periodStart'] as DateTime?;
    _periodEnd = snapshotData['periodEnd'] as DateTime?;
    _symptomDays = castToType<int>(snapshotData['symptomDays']);
    _symptomKey = snapshotData['symptomKey'] as String?;
    _metricKey = snapshotData['metricKey'] as String?;
    _symptomFreeDays = castToType<int>(snapshotData['symptomFreeDays']);
    _missingDays = castToType<int>(snapshotData['missingDays']);
    _incompleteDays = castToType<int>(snapshotData['incompleteDays']);
    _metricLabel = snapshotData['metricLabel'] as String?;
    _trackingDay = castToType<int>(snapshotData['trackingDay']);
    _dailyValues = getStructList(
      snapshotData['dailyValues'],
      DailyValueStruct.fromMap,
    );
    _periodType = snapshotData['periodType'] as String?;
    _moderateSymptomDays = castToType<int>(snapshotData['moderateSymptomDays']);
    _mildSymptomDays = castToType<int>(snapshotData['mildSymptomDays']);
    _severeSymptomDays = castToType<int>(snapshotData['severeSymptomDays']);
    _painkillerDays = castToType<int>(snapshotData['painkillerDays']);
    _periodDays = castToType<int>(snapshotData['periodDays']);
    _completionRate = castToType<double>(snapshotData['completionRate']);
    _symptomRate = castToType<double>(snapshotData['symptomRate']);
    _meanIntensitySymptomDays =
        castToType<double>(snapshotData['meanIntensitySymptomDays']);
    _meanIntensityTrackedDays =
        castToType<double>(snapshotData['meanIntensityTrackedDays']);
    _spikeCount = castToType<int>(snapshotData['spikeCount']);
    _currentSevereStreak = castToType<int>(snapshotData['currentSevereStreak']);
    _longestSevereStreak = castToType<int>(snapshotData['longestSevereStreak']);
    _currentCrystalStreak =
        castToType<int>(snapshotData['currentCrystalStreak']);
    _longestCrystalStreak =
        castToType<int>(snapshotData['longestCrystalStreak']);
    _currentMissingStreak =
        castToType<int>(snapshotData['currentMissingStreak']);
    _periodHasEnoughData = snapshotData['periodHasEnoughData'] as bool?;
    _analysisEligible = snapshotData['analysisEligible'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('dashboard');

  static Stream<DashboardRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DashboardRecord.fromSnapshot(s));

  static Future<DashboardRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DashboardRecord.fromSnapshot(s));

  static DashboardRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DashboardRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DashboardRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DashboardRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DashboardRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DashboardRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDashboardRecordData({
  DocumentReference? userRef,
  DocumentReference? metricRef,
  DateTime? periodStart,
  DateTime? periodEnd,
  int? symptomDays,
  String? symptomKey,
  String? metricKey,
  int? symptomFreeDays,
  int? missingDays,
  int? incompleteDays,
  String? metricLabel,
  int? trackingDay,
  String? periodType,
  int? moderateSymptomDays,
  int? mildSymptomDays,
  int? severeSymptomDays,
  int? painkillerDays,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'userRef': userRef,
      'metricRef': metricRef,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'symptomDays': symptomDays,
      'symptomKey': symptomKey,
      'metricKey': metricKey,
      'symptomFreeDays': symptomFreeDays,
      'missingDays': missingDays,
      'incompleteDays': incompleteDays,
      'metricLabel': metricLabel,
      'trackingDay': trackingDay,
      'periodType': periodType,
      'moderateSymptomDays': moderateSymptomDays,
      'mildSymptomDays': mildSymptomDays,
      'severeSymptomDays': severeSymptomDays,
      'painkillerDays': painkillerDays,
    }.withoutNulls,
  );

  return firestoreData;
}

class DashboardRecordDocumentEquality implements Equality<DashboardRecord> {
  const DashboardRecordDocumentEquality();

  @override
  bool equals(DashboardRecord? e1, DashboardRecord? e2) {
    const listEquality = ListEquality();
    return e1?.userRef == e2?.userRef &&
        e1?.metricRef == e2?.metricRef &&
        e1?.periodStart == e2?.periodStart &&
        e1?.periodEnd == e2?.periodEnd &&
        e1?.symptomDays == e2?.symptomDays &&
        e1?.symptomKey == e2?.symptomKey &&
        e1?.metricKey == e2?.metricKey &&
        e1?.symptomFreeDays == e2?.symptomFreeDays &&
        e1?.missingDays == e2?.missingDays &&
        e1?.incompleteDays == e2?.incompleteDays &&
        e1?.metricLabel == e2?.metricLabel &&
        e1?.trackingDay == e2?.trackingDay &&
        listEquality.equals(e1?.dailyValues, e2?.dailyValues) &&
        e1?.periodType == e2?.periodType &&
        e1?.moderateSymptomDays == e2?.moderateSymptomDays &&
        e1?.mildSymptomDays == e2?.mildSymptomDays &&
        e1?.severeSymptomDays == e2?.severeSymptomDays &&
        e1?.painkillerDays == e2?.painkillerDays;
  }

  @override
  int hash(DashboardRecord? e) => const ListEquality().hash([
        e?.userRef,
        e?.metricRef,
        e?.periodStart,
        e?.periodEnd,
        e?.symptomDays,
        e?.symptomKey,
        e?.metricKey,
        e?.symptomFreeDays,
        e?.missingDays,
        e?.incompleteDays,
        e?.metricLabel,
        e?.trackingDay,
        e?.dailyValues,
        e?.periodType,
        e?.moderateSymptomDays,
        e?.mildSymptomDays,
        e?.severeSymptomDays,
        e?.painkillerDays
      ]);

  @override
  bool isValidKey(Object? o) => o is DashboardRecord;
}
