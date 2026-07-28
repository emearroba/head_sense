import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DailyValuesRecord extends FirestoreRecord {
  DailyValuesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "day" field.
  int? _day;
  int get day => _day ?? 0;
  bool hasDay() => _day != null;

  // "date" field.
  String? _date;
  String get date => _date ?? '';
  bool hasDate() => _date != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "isTracked" field.
  bool? _isTracked;
  bool get isTracked => _isTracked ?? false;
  bool hasIsTracked() => _isTracked != null;

  // "isSpike" field.
  bool? _isSpike;
  bool get isSpike => _isSpike ?? false;
  bool hasIsSpike() => _isSpike != null;

  // "deltaFromPreviousDay" field.
  double? _deltaFromPreviousDay;
  double get deltaFromPreviousDay => _deltaFromPreviousDay ?? 0.0;
  bool hasDeltaFromPreviousDay() => _deltaFromPreviousDay != null;

  // "value" field.
  int? _value;
  int get value => _value ?? 0;
  bool hasValue() => _value != null;

  // "barColor" field.
  String? _barColor;
  String get barColor => _barColor ?? '';
  bool hasBarColor() => _barColor != null;

  // "dayOfWeek" field.
  String? _dayOfWeek;
  String get dayOfWeek => _dayOfWeek ?? '';
  bool hasDayOfWeek() => _dayOfWeek != null;

  // "dayOfWeekIndex" field.
  int? _dayOfWeekIndex;
  int get dayOfWeekIndex => _dayOfWeekIndex ?? 0;
  bool hasDayOfWeekIndex() => _dayOfWeekIndex != null;

  // "isMild" field.
  bool? _isMild;
  bool get isMild => _isMild ?? false;
  bool hasIsMild() => _isMild != null;

  // "isModerate" field.
  bool? _isModerate;
  bool get isModerate => _isModerate ?? false;
  bool hasIsModerate() => _isModerate != null;

  // "isSevere" field.
  bool? _isSevere;
  bool get isSevere => _isSevere ?? false;
  bool hasIsSevere() => _isSevere != null;

  // "isMissing" field.
  bool? _isMissing;
  bool get isMissing => _isMissing ?? false;
  bool hasIsMissing() => _isMissing != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _day = castToType<int>(snapshotData['day']);
    _date = snapshotData['date'] as String?;
    _category = snapshotData['category'] as String?;
    _isTracked = snapshotData['isTracked'] as bool?;
    _isSpike = snapshotData['isSpike'] as bool?;
    _deltaFromPreviousDay =
        castToType<double>(snapshotData['deltaFromPreviousDay']);
    _value = castToType<int>(snapshotData['value']);
    _barColor = snapshotData['barColor'] as String?;
    _dayOfWeek = snapshotData['dayOfWeek'] as String?;
    _dayOfWeekIndex = castToType<int>(snapshotData['dayOfWeekIndex']);
    _isMild = snapshotData['isMild'] as bool?;
    _isModerate = snapshotData['isModerate'] as bool?;
    _isSevere = snapshotData['isSevere'] as bool?;
    _isMissing = snapshotData['isMissing'] as bool?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('daily_values')
          : FirebaseFirestore.instance.collectionGroup('daily_values');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('daily_values').doc(id);

  static Stream<DailyValuesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DailyValuesRecord.fromSnapshot(s));

  static Future<DailyValuesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DailyValuesRecord.fromSnapshot(s));

  static DailyValuesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DailyValuesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DailyValuesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DailyValuesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DailyValuesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DailyValuesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDailyValuesRecordData({
  int? day,
  String? date,
  String? category,
  bool? isTracked,
  bool? isSpike,
  double? deltaFromPreviousDay,
  int? value,
  String? barColor,
  String? dayOfWeek,
  int? dayOfWeekIndex,
  bool? isMild,
  bool? isModerate,
  bool? isSevere,
  bool? isMissing,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'day': day,
      'date': date,
      'category': category,
      'isTracked': isTracked,
      'isSpike': isSpike,
      'deltaFromPreviousDay': deltaFromPreviousDay,
      'value': value,
      'barColor': barColor,
      'dayOfWeek': dayOfWeek,
      'dayOfWeekIndex': dayOfWeekIndex,
      'isMild': isMild,
      'isModerate': isModerate,
      'isSevere': isSevere,
      'isMissing': isMissing,
    }.withoutNulls,
  );

  return firestoreData;
}

class DailyValuesRecordDocumentEquality implements Equality<DailyValuesRecord> {
  const DailyValuesRecordDocumentEquality();

  @override
  bool equals(DailyValuesRecord? e1, DailyValuesRecord? e2) {
    return e1?.day == e2?.day &&
        e1?.date == e2?.date &&
        e1?.category == e2?.category &&
        e1?.isTracked == e2?.isTracked &&
        e1?.isSpike == e2?.isSpike &&
        e1?.deltaFromPreviousDay == e2?.deltaFromPreviousDay &&
        e1?.value == e2?.value &&
        e1?.barColor == e2?.barColor &&
        e1?.dayOfWeek == e2?.dayOfWeek &&
        e1?.dayOfWeekIndex == e2?.dayOfWeekIndex &&
        e1?.isMild == e2?.isMild &&
        e1?.isModerate == e2?.isModerate &&
        e1?.isSevere == e2?.isSevere &&
        e1?.isMissing == e2?.isMissing;
  }

  @override
  int hash(DailyValuesRecord? e) => const ListEquality().hash([
        e?.day,
        e?.date,
        e?.category,
        e?.isTracked,
        e?.isSpike,
        e?.deltaFromPreviousDay,
        e?.value,
        e?.barColor,
        e?.dayOfWeek,
        e?.dayOfWeekIndex,
        e?.isMild,
        e?.isModerate,
        e?.isSevere,
        e?.isMissing
      ]);

  @override
  bool isValidKey(Object? o) => o is DailyValuesRecord;
}
