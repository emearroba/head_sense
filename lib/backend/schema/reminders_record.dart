import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RemindersRecord extends FirestoreRecord {
  RemindersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "message" field.
  String? _message;
  String get message => _message ?? '';
  bool hasMessage() => _message != null;

  // "scheduled_time" field.
  DateTime? _scheduledTime;
  DateTime? get scheduledTime => _scheduledTime;
  bool hasScheduledTime() => _scheduledTime != null;

  // "is_active" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "frequency_type" field.
  String? _frequencyType;
  String get frequencyType => _frequencyType ?? '';
  bool hasFrequencyType() => _frequencyType != null;

  // "hour_of_day" field.
  int? _hourOfDay;
  int get hourOfDay => _hourOfDay ?? 0;
  bool hasHourOfDay() => _hourOfDay != null;

  // "minute_of_hour" field.
  int? _minuteOfHour;
  int get minuteOfHour => _minuteOfHour ?? 0;
  bool hasMinuteOfHour() => _minuteOfHour != null;

  // "weekday" field.
  int? _weekday;
  int get weekday => _weekday ?? 0;
  bool hasWeekday() => _weekday != null;

  // "user_ref" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "type" field.
  String? _type;
  String get type => _type ?? '';
  bool hasType() => _type != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _title = snapshotData['title'] as String?;
    _message = snapshotData['message'] as String?;
    _scheduledTime = snapshotData['scheduled_time'] as DateTime?;
    _isActive = snapshotData['is_active'] as bool?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _frequencyType = snapshotData['frequency_type'] as String?;
    _hourOfDay = castToType<int>(snapshotData['hour_of_day']);
    _minuteOfHour = castToType<int>(snapshotData['minute_of_hour']);
    _weekday = castToType<int>(snapshotData['weekday']);
    _userRef = snapshotData['user_ref'] as DocumentReference?;
    _type = snapshotData['type'] as String?;
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('reminders')
          : FirebaseFirestore.instance.collectionGroup('reminders');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('reminders').doc(id);

  static Stream<RemindersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => RemindersRecord.fromSnapshot(s));

  static Future<RemindersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => RemindersRecord.fromSnapshot(s));

  static RemindersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      RemindersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static RemindersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      RemindersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'RemindersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is RemindersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createRemindersRecordData({
  String? title,
  String? message,
  DateTime? scheduledTime,
  bool? isActive,
  DateTime? createdTime,
  String? frequencyType,
  int? hourOfDay,
  int? minuteOfHour,
  int? weekday,
  DocumentReference? userRef,
  String? type,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'title': title,
      'message': message,
      'scheduled_time': scheduledTime,
      'is_active': isActive,
      'created_time': createdTime,
      'frequency_type': frequencyType,
      'hour_of_day': hourOfDay,
      'minute_of_hour': minuteOfHour,
      'weekday': weekday,
      'user_ref': userRef,
      'type': type,
    }.withoutNulls,
  );

  return firestoreData;
}

class RemindersRecordDocumentEquality implements Equality<RemindersRecord> {
  const RemindersRecordDocumentEquality();

  @override
  bool equals(RemindersRecord? e1, RemindersRecord? e2) {
    return e1?.title == e2?.title &&
        e1?.message == e2?.message &&
        e1?.scheduledTime == e2?.scheduledTime &&
        e1?.isActive == e2?.isActive &&
        e1?.createdTime == e2?.createdTime &&
        e1?.frequencyType == e2?.frequencyType &&
        e1?.hourOfDay == e2?.hourOfDay &&
        e1?.minuteOfHour == e2?.minuteOfHour &&
        e1?.weekday == e2?.weekday &&
        e1?.userRef == e2?.userRef &&
        e1?.type == e2?.type;
  }

  @override
  int hash(RemindersRecord? e) => const ListEquality().hash([
        e?.title,
        e?.message,
        e?.scheduledTime,
        e?.isActive,
        e?.createdTime,
        e?.frequencyType,
        e?.hourOfDay,
        e?.minuteOfHour,
        e?.weekday,
        e?.userRef,
        e?.type
      ]);

  @override
  bool isValidKey(Object? o) => o is RemindersRecord;
}
