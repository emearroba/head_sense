import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _CalculatorTitle = 'BMI calculator';
  String get CalculatorTitle => _CalculatorTitle;
  set CalculatorTitle(String value) {
    _CalculatorTitle = value;
  }

  /// Latitude
  double _userLat = 0.0;
  double get userLat => _userLat;
  set userLat(double value) {
    _userLat = value;
  }

  /// Longitude
  double _userLong = 0.0;
  double get userLong => _userLong;
  set userLong(double value) {
    _userLong = value;
  }

  DateTime? _locationFetchedAt;
  DateTime? get locationFetchedAt => _locationFetchedAt;
  set locationFetchedAt(DateTime? value) {
    _locationFetchedAt = value;
  }

  DateTime? _selectedTime;
  DateTime? get selectedTime => _selectedTime;
  set selectedTime(DateTime? value) {
    _selectedTime = value;
  }
}
