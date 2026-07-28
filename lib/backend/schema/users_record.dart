import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "plan" field.
  String? _plan;
  String get plan => _plan ?? '';
  bool hasPlan() => _plan != null;

  // "studyParticipant" field.
  bool? _studyParticipant;
  bool get studyParticipant => _studyParticipant ?? false;
  bool hasStudyParticipant() => _studyParticipant != null;

  // "timezoneName" field.
  String? _timezoneName;
  String get timezoneName => _timezoneName ?? '';
  bool hasTimezoneName() => _timezoneName != null;

  // "userTimezone" field.
  LatLng? _userTimezone;
  LatLng? get userTimezone => _userTimezone;
  bool hasUserTimezone() => _userTimezone != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "coins" field.
  int? _coins;
  int get coins => _coins ?? 0;
  bool hasCoins() => _coins != null;

  // "currentStreak" field.
  int? _currentStreak;
  int get currentStreak => _currentStreak ?? 0;
  bool hasCurrentStreak() => _currentStreak != null;

  // "lastDiaryCompletedDateKey" field.
  String? _lastDiaryCompletedDateKey;
  String get lastDiaryCompletedDateKey => _lastDiaryCompletedDateKey ?? '';
  bool hasLastDiaryCompletedDateKey() => _lastDiaryCompletedDateKey != null;

  // "reminder_time" field.
  DateTime? _reminderTime;
  DateTime? get reminderTime => _reminderTime;
  bool hasReminderTime() => _reminderTime != null;

  // "reminder_active" field.
  bool? _reminderActive;
  bool get reminderActive => _reminderActive ?? false;
  bool hasReminderActive() => _reminderActive != null;

  void _initializeFields() {
    _uid = snapshotData['uid'] as String?;
    _email = snapshotData['email'] as String?;
    _plan = snapshotData['plan'] as String?;
    _studyParticipant = snapshotData['studyParticipant'] as bool?;
    _timezoneName = snapshotData['timezoneName'] as String?;
    _userTimezone = snapshotData['userTimezone'] as LatLng?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _displayName = snapshotData['display_name'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _coins = castToType<int>(snapshotData['coins']);
    _currentStreak = castToType<int>(snapshotData['currentStreak']);
    _lastDiaryCompletedDateKey =
        snapshotData['lastDiaryCompletedDateKey'] as String?;
    _reminderTime = snapshotData['reminder_time'] as DateTime?;
    _reminderActive = snapshotData['reminder_active'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? uid,
  String? email,
  String? plan,
  bool? studyParticipant,
  String? timezoneName,
  LatLng? userTimezone,
  String? photoUrl,
  DateTime? createdTime,
  String? displayName,
  String? phoneNumber,
  int? coins,
  int? currentStreak,
  String? lastDiaryCompletedDateKey,
  DateTime? reminderTime,
  bool? reminderActive,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'uid': uid,
      'email': email,
      'plan': plan,
      'studyParticipant': studyParticipant,
      'timezoneName': timezoneName,
      'userTimezone': userTimezone,
      'photo_url': photoUrl,
      'created_time': createdTime,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'coins': coins,
      'currentStreak': currentStreak,
      'lastDiaryCompletedDateKey': lastDiaryCompletedDateKey,
      'reminder_time': reminderTime,
      'reminder_active': reminderActive,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    return e1?.uid == e2?.uid &&
        e1?.email == e2?.email &&
        e1?.plan == e2?.plan &&
        e1?.studyParticipant == e2?.studyParticipant &&
        e1?.timezoneName == e2?.timezoneName &&
        e1?.userTimezone == e2?.userTimezone &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.createdTime == e2?.createdTime &&
        e1?.displayName == e2?.displayName &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.coins == e2?.coins &&
        e1?.currentStreak == e2?.currentStreak &&
        e1?.lastDiaryCompletedDateKey == e2?.lastDiaryCompletedDateKey &&
        e1?.reminderTime == e2?.reminderTime &&
        e1?.reminderActive == e2?.reminderActive;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.uid,
        e?.email,
        e?.plan,
        e?.studyParticipant,
        e?.timezoneName,
        e?.userTimezone,
        e?.photoUrl,
        e?.createdTime,
        e?.displayName,
        e?.phoneNumber,
        e?.coins,
        e?.currentStreak,
        e?.lastDiaryCompletedDateKey,
        e?.reminderTime,
        e?.reminderActive
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
