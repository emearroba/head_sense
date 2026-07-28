// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DailyValueStruct extends FFFirebaseStruct {
  DailyValueStruct({
    int? day,
    String? date,
    double? value,
    String? category,
    bool? isTracked,
    bool? isCrystal,
    bool? isMild,
    bool? isModerate,
    bool? isSevere,
    bool? isMissing,
    double? deltaFromPreviousDay,
    bool? isSpike,
    String? barColor,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _day = day,
        _date = date,
        _value = value,
        _category = category,
        _isTracked = isTracked,
        _isCrystal = isCrystal,
        _isMild = isMild,
        _isModerate = isModerate,
        _isSevere = isSevere,
        _isMissing = isMissing,
        _deltaFromPreviousDay = deltaFromPreviousDay,
        _isSpike = isSpike,
        _barColor = barColor,
        super(firestoreUtilData);

  // "day" field.
  int? _day;
  int get day => _day ?? 0;
  set day(int? val) => _day = val;

  void incrementDay(int amount) => day = day + amount;

  bool hasDay() => _day != null;

  // "date" field.
  String? _date;
  String get date => _date ?? '';
  set date(String? val) => _date = val;

  bool hasDate() => _date != null;

  // "value" field.
  double? _value;
  double get value => _value ?? 0.0;
  set value(double? val) => _value = val;

  void incrementValue(double amount) => value = value + amount;

  bool hasValue() => _value != null;

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  set category(String? val) => _category = val;

  bool hasCategory() => _category != null;

  // "isTracked" field.
  bool? _isTracked;
  bool get isTracked => _isTracked ?? false;
  set isTracked(bool? val) => _isTracked = val;

  bool hasIsTracked() => _isTracked != null;

  // "isCrystal" field.
  bool? _isCrystal;
  bool get isCrystal => _isCrystal ?? false;
  set isCrystal(bool? val) => _isCrystal = val;

  bool hasIsCrystal() => _isCrystal != null;

  // "isMild" field.
  bool? _isMild;
  bool get isMild => _isMild ?? false;
  set isMild(bool? val) => _isMild = val;

  bool hasIsMild() => _isMild != null;

  // "isModerate" field.
  bool? _isModerate;
  bool get isModerate => _isModerate ?? false;
  set isModerate(bool? val) => _isModerate = val;

  bool hasIsModerate() => _isModerate != null;

  // "isSevere" field.
  bool? _isSevere;
  bool get isSevere => _isSevere ?? false;
  set isSevere(bool? val) => _isSevere = val;

  bool hasIsSevere() => _isSevere != null;

  // "isMissing" field.
  bool? _isMissing;
  bool get isMissing => _isMissing ?? false;
  set isMissing(bool? val) => _isMissing = val;

  bool hasIsMissing() => _isMissing != null;

  // "deltaFromPreviousDay" field.
  double? _deltaFromPreviousDay;
  double get deltaFromPreviousDay => _deltaFromPreviousDay ?? 0.0;
  set deltaFromPreviousDay(double? val) => _deltaFromPreviousDay = val;

  void incrementDeltaFromPreviousDay(double amount) =>
      deltaFromPreviousDay = deltaFromPreviousDay + amount;

  bool hasDeltaFromPreviousDay() => _deltaFromPreviousDay != null;

  // "isSpike" field.
  bool? _isSpike;
  bool get isSpike => _isSpike ?? false;
  set isSpike(bool? val) => _isSpike = val;

  bool hasIsSpike() => _isSpike != null;

  // "barColor" field.
  String? _barColor;
  String get barColor => _barColor ?? '';
  set barColor(String? val) => _barColor = val;

  bool hasBarColor() => _barColor != null;

  static DailyValueStruct fromMap(Map<String, dynamic> data) =>
      DailyValueStruct(
        day: castToType<int>(data['day']),
        date: data['date'] as String?,
        value: castToType<double>(data['value']),
        category: data['category'] as String?,
        isTracked: data['isTracked'] as bool?,
        isCrystal: data['isCrystal'] as bool?,
        isMild: data['isMild'] as bool?,
        isModerate: data['isModerate'] as bool?,
        isSevere: data['isSevere'] as bool?,
        isMissing: data['isMissing'] as bool?,
        deltaFromPreviousDay: castToType<double>(data['deltaFromPreviousDay']),
        isSpike: data['isSpike'] as bool?,
        barColor: data['barColor'] as String?,
      );

  static DailyValueStruct? maybeFromMap(dynamic data) => data is Map
      ? DailyValueStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'day': _day,
        'date': _date,
        'value': _value,
        'category': _category,
        'isTracked': _isTracked,
        'isCrystal': _isCrystal,
        'isMild': _isMild,
        'isModerate': _isModerate,
        'isSevere': _isSevere,
        'isMissing': _isMissing,
        'deltaFromPreviousDay': _deltaFromPreviousDay,
        'isSpike': _isSpike,
        'barColor': _barColor,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'day': serializeParam(
          _day,
          ParamType.int,
        ),
        'date': serializeParam(
          _date,
          ParamType.String,
        ),
        'value': serializeParam(
          _value,
          ParamType.double,
        ),
        'category': serializeParam(
          _category,
          ParamType.String,
        ),
        'isTracked': serializeParam(
          _isTracked,
          ParamType.bool,
        ),
        'isCrystal': serializeParam(
          _isCrystal,
          ParamType.bool,
        ),
        'isMild': serializeParam(
          _isMild,
          ParamType.bool,
        ),
        'isModerate': serializeParam(
          _isModerate,
          ParamType.bool,
        ),
        'isSevere': serializeParam(
          _isSevere,
          ParamType.bool,
        ),
        'isMissing': serializeParam(
          _isMissing,
          ParamType.bool,
        ),
        'deltaFromPreviousDay': serializeParam(
          _deltaFromPreviousDay,
          ParamType.double,
        ),
        'isSpike': serializeParam(
          _isSpike,
          ParamType.bool,
        ),
        'barColor': serializeParam(
          _barColor,
          ParamType.String,
        ),
      }.withoutNulls;

  static DailyValueStruct fromSerializableMap(Map<String, dynamic> data) =>
      DailyValueStruct(
        day: deserializeParam(
          data['day'],
          ParamType.int,
          false,
        ),
        date: deserializeParam(
          data['date'],
          ParamType.String,
          false,
        ),
        value: deserializeParam(
          data['value'],
          ParamType.double,
          false,
        ),
        category: deserializeParam(
          data['category'],
          ParamType.String,
          false,
        ),
        isTracked: deserializeParam(
          data['isTracked'],
          ParamType.bool,
          false,
        ),
        isCrystal: deserializeParam(
          data['isCrystal'],
          ParamType.bool,
          false,
        ),
        isMild: deserializeParam(
          data['isMild'],
          ParamType.bool,
          false,
        ),
        isModerate: deserializeParam(
          data['isModerate'],
          ParamType.bool,
          false,
        ),
        isSevere: deserializeParam(
          data['isSevere'],
          ParamType.bool,
          false,
        ),
        isMissing: deserializeParam(
          data['isMissing'],
          ParamType.bool,
          false,
        ),
        deltaFromPreviousDay: deserializeParam(
          data['deltaFromPreviousDay'],
          ParamType.double,
          false,
        ),
        isSpike: deserializeParam(
          data['isSpike'],
          ParamType.bool,
          false,
        ),
        barColor: deserializeParam(
          data['barColor'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'DailyValueStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is DailyValueStruct &&
        day == other.day &&
        date == other.date &&
        value == other.value &&
        category == other.category &&
        isTracked == other.isTracked &&
        isCrystal == other.isCrystal &&
        isMild == other.isMild &&
        isModerate == other.isModerate &&
        isSevere == other.isSevere &&
        isMissing == other.isMissing &&
        deltaFromPreviousDay == other.deltaFromPreviousDay &&
        isSpike == other.isSpike &&
        barColor == other.barColor;
  }

  @override
  int get hashCode => const ListEquality().hash([
        day,
        date,
        value,
        category,
        isTracked,
        isCrystal,
        isMild,
        isModerate,
        isSevere,
        isMissing,
        deltaFromPreviousDay,
        isSpike,
        barColor
      ]);
}

DailyValueStruct createDailyValueStruct({
  int? day,
  String? date,
  double? value,
  String? category,
  bool? isTracked,
  bool? isCrystal,
  bool? isMild,
  bool? isModerate,
  bool? isSevere,
  bool? isMissing,
  double? deltaFromPreviousDay,
  bool? isSpike,
  String? barColor,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    DailyValueStruct(
      day: day,
      date: date,
      value: value,
      category: category,
      isTracked: isTracked,
      isCrystal: isCrystal,
      isMild: isMild,
      isModerate: isModerate,
      isSevere: isSevere,
      isMissing: isMissing,
      deltaFromPreviousDay: deltaFromPreviousDay,
      isSpike: isSpike,
      barColor: barColor,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

DailyValueStruct? updateDailyValueStruct(
  DailyValueStruct? dailyValue, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    dailyValue
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addDailyValueStructData(
  Map<String, dynamic> firestoreData,
  DailyValueStruct? dailyValue,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (dailyValue == null) {
    return;
  }
  if (dailyValue.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && dailyValue.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final dailyValueData = getDailyValueFirestoreData(dailyValue, forFieldValue);
  final nestedData = dailyValueData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = dailyValue.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getDailyValueFirestoreData(
  DailyValueStruct? dailyValue, [
  bool forFieldValue = false,
]) {
  if (dailyValue == null) {
    return {};
  }
  final firestoreData = mapToFirestore(dailyValue.toMap());

  // Add any Firestore field values
  mapToFirestore(dailyValue.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getDailyValueListFirestoreData(
  List<DailyValueStruct>? dailyValues,
) =>
    dailyValues?.map((e) => getDailyValueFirestoreData(e, true)).toList() ?? [];
