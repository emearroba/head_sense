import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DiaryTodoRecord extends FirestoreRecord {
  DiaryTodoRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "diary_name" field.
  String? _diaryName;
  String get diaryName => _diaryName ?? '';
  bool hasDiaryName() => _diaryName != null;

  // "is_done" field.
  bool? _isDone;
  bool get isDone => _isDone ?? false;
  bool hasIsDone() => _isDone != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  void _initializeFields() {
    _diaryName = snapshotData['diary_name'] as String?;
    _isDone = snapshotData['is_done'] as bool?;
    _uid = snapshotData['uid'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('diary_todo');

  static Stream<DiaryTodoRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DiaryTodoRecord.fromSnapshot(s));

  static Future<DiaryTodoRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DiaryTodoRecord.fromSnapshot(s));

  static DiaryTodoRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DiaryTodoRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DiaryTodoRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DiaryTodoRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DiaryTodoRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DiaryTodoRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDiaryTodoRecordData({
  String? diaryName,
  bool? isDone,
  String? uid,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'diary_name': diaryName,
      'is_done': isDone,
      'uid': uid,
    }.withoutNulls,
  );

  return firestoreData;
}

class DiaryTodoRecordDocumentEquality implements Equality<DiaryTodoRecord> {
  const DiaryTodoRecordDocumentEquality();

  @override
  bool equals(DiaryTodoRecord? e1, DiaryTodoRecord? e2) {
    return e1?.diaryName == e2?.diaryName &&
        e1?.isDone == e2?.isDone &&
        e1?.uid == e2?.uid;
  }

  @override
  int hash(DiaryTodoRecord? e) =>
      const ListEquality().hash([e?.diaryName, e?.isDone, e?.uid]);

  @override
  bool isValidKey(Object? o) => o is DiaryTodoRecord;
}
