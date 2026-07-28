import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StudiesRecord extends FirestoreRecord {
  StudiesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "studyName" field.
  String? _studyName;
  String get studyName => _studyName ?? '';
  bool hasStudyName() => _studyName != null;

  // "accessCode" field.
  String? _accessCode;
  String get accessCode => _accessCode ?? '';
  bool hasAccessCode() => _accessCode != null;

  // "includedMetrics" field.
  List<String>? _includedMetrics;
  List<String> get includedMetrics => _includedMetrics ?? const [];
  bool hasIncludedMetrics() => _includedMetrics != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "includedFeatures" field.
  List<String>? _includedFeatures;
  List<String> get includedFeatures => _includedFeatures ?? const [];
  bool hasIncludedFeatures() => _includedFeatures != null;

  void _initializeFields() {
    _studyName = snapshotData['studyName'] as String?;
    _accessCode = snapshotData['accessCode'] as String?;
    _includedMetrics = getDataList(snapshotData['includedMetrics']);
    _isActive = snapshotData['isActive'] as bool?;
    _includedFeatures = getDataList(snapshotData['includedFeatures']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('studies');

  static Stream<StudiesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => StudiesRecord.fromSnapshot(s));

  static Future<StudiesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => StudiesRecord.fromSnapshot(s));

  static StudiesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      StudiesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static StudiesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      StudiesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'StudiesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is StudiesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createStudiesRecordData({
  String? studyName,
  String? accessCode,
  bool? isActive,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'studyName': studyName,
      'accessCode': accessCode,
      'isActive': isActive,
    }.withoutNulls,
  );

  return firestoreData;
}

class StudiesRecordDocumentEquality implements Equality<StudiesRecord> {
  const StudiesRecordDocumentEquality();

  @override
  bool equals(StudiesRecord? e1, StudiesRecord? e2) {
    const listEquality = ListEquality();
    return e1?.studyName == e2?.studyName &&
        e1?.accessCode == e2?.accessCode &&
        listEquality.equals(e1?.includedMetrics, e2?.includedMetrics) &&
        e1?.isActive == e2?.isActive &&
        listEquality.equals(e1?.includedFeatures, e2?.includedFeatures);
  }

  @override
  int hash(StudiesRecord? e) => const ListEquality().hash([
        e?.studyName,
        e?.accessCode,
        e?.includedMetrics,
        e?.isActive,
        e?.includedFeatures
      ]);

  @override
  bool isValidKey(Object? o) => o is StudiesRecord;
}
