import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DiaryEntriesRecord extends FirestoreRecord {
  DiaryEntriesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "entryDate" field.
  DateTime? _entryDate;
  DateTime? get entryDate => _entryDate;
  bool hasEntryDate() => _entryDate != null;

  // "entryDateKey" field.
  String? _entryDateKey;
  String get entryDateKey => _entryDateKey ?? '';
  bool hasEntryDateKey() => _entryDateKey != null;

  // "completedAt" field.
  DateTime? _completedAt;
  DateTime? get completedAt => _completedAt;
  bool hasCompletedAt() => _completedAt != null;

  // "isComplete" field.
  bool? _isComplete;
  bool get isComplete => _isComplete ?? false;
  bool hasIsComplete() => _isComplete != null;

  // "userRef" field.
  DocumentReference? _userRef;
  DocumentReference? get userRef => _userRef;
  bool hasUserRef() => _userRef != null;

  // "coinsEarned" field.
  int? _coinsEarned;
  int get coinsEarned => _coinsEarned ?? 0;
  bool hasCoinsEarned() => _coinsEarned != null;

  void _initializeFields() {
    _entryDate = snapshotData['entryDate'] as DateTime?;
    _entryDateKey = snapshotData['entryDateKey'] as String?;
    _completedAt = snapshotData['completedAt'] as DateTime?;
    _isComplete = snapshotData['isComplete'] as bool?;
    _userRef = snapshotData['userRef'] as DocumentReference?;
    _coinsEarned = castToType<int>(snapshotData['coinsEarned']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('diary_entries');

  static Stream<DiaryEntriesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DiaryEntriesRecord.fromSnapshot(s));

  static Future<DiaryEntriesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DiaryEntriesRecord.fromSnapshot(s));

  static DiaryEntriesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DiaryEntriesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DiaryEntriesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DiaryEntriesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DiaryEntriesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DiaryEntriesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDiaryEntriesRecordData({
  DateTime? entryDate,
  String? entryDateKey,
  DateTime? completedAt,
  bool? isComplete,
  DocumentReference? userRef,
  int? coinsEarned,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'entryDate': entryDate,
      'entryDateKey': entryDateKey,
      'completedAt': completedAt,
      'isComplete': isComplete,
      'userRef': userRef,
      'coinsEarned': coinsEarned,
    }.withoutNulls,
  );

  return firestoreData;
}

class DiaryEntriesRecordDocumentEquality
    implements Equality<DiaryEntriesRecord> {
  const DiaryEntriesRecordDocumentEquality();

  @override
  bool equals(DiaryEntriesRecord? e1, DiaryEntriesRecord? e2) {
    return e1?.entryDate == e2?.entryDate &&
        e1?.entryDateKey == e2?.entryDateKey &&
        e1?.completedAt == e2?.completedAt &&
        e1?.isComplete == e2?.isComplete &&
        e1?.userRef == e2?.userRef &&
        e1?.coinsEarned == e2?.coinsEarned;
  }

  @override
  int hash(DiaryEntriesRecord? e) => const ListEquality().hash([
        e?.entryDate,
        e?.entryDateKey,
        e?.completedAt,
        e?.isComplete,
        e?.userRef,
        e?.coinsEarned
      ]);

  @override
  bool isValidKey(Object? o) => o is DiaryEntriesRecord;
}
