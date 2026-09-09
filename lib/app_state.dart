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

  static const _healthSyncEnabledPrefsKey = 'ff_healthSyncEnabled';
  static const _hasSeenWelcomeIntroPrefsKey = 'ff_hasSeenWelcomeIntro';

  Future initializePersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    _healthSyncEnabled = prefs.getBool(_healthSyncEnabledPrefsKey) ?? false;
    _hasSeenWelcomeIntro =
        prefs.getBool(_hasSeenWelcomeIntroPrefsKey) ?? false;
  }

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

  /// Whether the user has turned on Apple Health / Health Connect sync in
  /// Settings. Persisted (unlike the fields above) since it gates whether
  /// HealthSyncService is invoked on app resume.
  bool _healthSyncEnabled = false;
  bool get healthSyncEnabled => _healthSyncEnabled;
  set healthSyncEnabled(bool value) {
    _healthSyncEnabled = value;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_healthSyncEnabledPrefsKey, value));
  }

  /// Whether the "what does this app do" welcome carousel
  /// (WelcomeIntroWidget) has been shown on this device. Read synchronously
  /// by nav.dart's root route to decide whether a not-yet-logged-in user
  /// sees it before Authentication - device-level, not account-level, since
  /// it must apply before anyone has signed up.
  bool _hasSeenWelcomeIntro = false;
  bool get hasSeenWelcomeIntro => _hasSeenWelcomeIntro;
  set hasSeenWelcomeIntro(bool value) {
    _hasSeenWelcomeIntro = value;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_hasSeenWelcomeIntroPrefsKey, value));
  }
}
