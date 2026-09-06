import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

// Catalog collection (like `metrics`) - a curated reference list of diet
// types a user can add to their personal Interventions list. The user's
// selection lives in `dietTypeKeys` on UsersRecord.
class DietTypesRecord extends FirestoreRecord {
  DietTypesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "order" field.
  int? _order;
  int get order => _order ?? 0;
  bool hasOrder() => _order != null;

  // "isActive" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _description = snapshotData['description'] as String?;
    _order = castToType<int>(snapshotData['order']);
    _isActive = snapshotData['isActive'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('diet_types');

  static Stream<DietTypesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DietTypesRecord.fromSnapshot(s));

  static Future<DietTypesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DietTypesRecord.fromSnapshot(s));

  static DietTypesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DietTypesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DietTypesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DietTypesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DietTypesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DietTypesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDietTypesRecordData({
  String? name,
  String? description,
  int? order,
  bool? isActive,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'description': description,
      'order': order,
      'isActive': isActive,
    }.withoutNulls,
  );

  return firestoreData;
}

class DietTypesRecordDocumentEquality implements Equality<DietTypesRecord> {
  const DietTypesRecordDocumentEquality();

  @override
  bool equals(DietTypesRecord? e1, DietTypesRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.description == e2?.description &&
        e1?.order == e2?.order &&
        e1?.isActive == e2?.isActive;
  }

  @override
  int hash(DietTypesRecord? e) => const ListEquality()
      .hash([e?.name, e?.description, e?.order, e?.isActive]);

  @override
  bool isValidKey(Object? o) => o is DietTypesRecord;
}
