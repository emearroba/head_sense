import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

/// Reads sleep, steps and resting heart rate from Apple Health / Google
/// Health Connect and writes them as raw samples to
/// `users/{uid}/health_samples`. The `aggregate_health_samples` cloud
/// function picks those up and rolls them into the existing
/// `dashboard`/`daily_values` pipeline (see update_dashboard_metric.js) -
/// this service only owns the raw, per-sample side of the sync.
///
/// v1 is manual/foreground sync only: call [requestPermissions] once (e.g.
/// from a Settings toggle) and [syncRecentData] to pull the latest window
/// on demand. There is no background delivery yet.
class HealthSyncService {
  HealthSyncService._();
  static final HealthSyncService instance = HealthSyncService._();

  final Health _health = Health();

  static const List<HealthDataType> types = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.STEPS,
    HealthDataType.RESTING_HEART_RATE,
  ];

  /// Metric keys this service feeds, in the same order as [types] - kept
  /// here so callers (e.g. the Settings toggle) can add/remove them from
  /// UsersRecord.trackedMetricKeys without duplicating this mapping.
  static const List<String> trackedMetricKeys = [
    'health_sleep_hours',
    'health_steps',
    'health_resting_hr',
  ];

  /// The `health` package (and HealthKit/Health Connect themselves) only
  /// exist on iOS/Android - there is no web equivalent. Every other member
  /// below is only safe to call when this is true.
  bool get isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  /// "Apple Health" on iOS, "Health Connect" on Android/elsewhere.
  String get platformLabel =>
      !kIsWeb && Platform.isIOS ? 'Apple Health' : 'Health Connect';

  /// On Android, Health Connect may not be installed. Always true on iOS
  /// (not applicable there) and false on web (not supported at all).
  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    if (!Platform.isAndroid) return true;
    return _health.isHealthConnectAvailable();
  }

  /// Directs the user to install/update the Health Connect app. Android
  /// only, no-op elsewhere.
  Future<void> promptInstall() async {
    if (!isSupported || !Platform.isAndroid) return;
    await _health.installHealthConnect();
  }

  /// Requests read authorization for [types]. Returns whether the request
  /// completed - on iOS this does NOT mean access was granted (HealthKit
  /// never discloses read-grant status), only that the prompt was shown.
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await _health.configure();
    if (Platform.isAndroid && !await isAvailable()) {
      return false;
    }
    return _health.requestAuthorization(types);
  }

  /// Fetches [lookback] worth of samples and writes them to
  /// `subjects/{subjectId}/health_samples` - pseudonymous like the other
  /// clinical collections (diary_entries, dashboard), not nested under
  /// `users/{uid}` - keyed by each sample's own uuid so re-running this
  /// never creates duplicates. Returns how many samples were written.
  Future<int> syncRecentData({Duration lookback = const Duration(days: 7)}) async {
    if (!isSupported) return 0;

    final userRef = currentUserReference;
    if (userRef == null) return 0;
    final subjectId = currentSubjectId;
    if (subjectId.isEmpty) return 0;
    final subjectRef =
        FirebaseFirestore.instance.collection('subjects').doc(subjectId);

    final now = DateTime.now();
    final points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: now.subtract(lookback),
      endTime: now,
    );
    final deduped = _health.removeDuplicates(points);
    if (deduped.isEmpty) return 0;

    final consent = await _researchConsent(userRef);
    final syncedAt = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();
    var count = 0;

    for (final point in deduped) {
      final value = point.value;
      if (value is! NumericHealthValue) continue;

      // The uuid HealthKit/Health Connect assigns each sample - using it as
      // the doc id makes writes idempotent across repeated syncs.
      final docId = point.uuid.isNotEmpty
          ? point.uuid
          : '${point.type.name}_${point.dateFrom.millisecondsSinceEpoch}_${point.dateTo.millisecondsSinceEpoch}';

      final ref = HealthSamplesRecord.createDoc(subjectRef, id: docId);
      batch.set(
        ref,
        createHealthSamplesRecordData(
          type: point.type.name,
          value: value.numericValue.toDouble(),
          unit: point.unit.name,
          startDate: point.dateFrom,
          endDate: point.dateTo,
          sourcePlatform: point.sourcePlatform == HealthPlatformType.appleHealth
              ? 'apple_health'
              : 'health_connect',
          sourceName: point.sourceName,
          syncedAt: syncedAt,
          consentedForResearch: consent,
        ),
      );
      count++;
    }

    if (count > 0) {
      await batch.commit();
    }
    return count;
  }

  Future<bool> _researchConsent(DocumentReference userRef) async {
    final user = await UsersRecord.getDocumentOnce(userRef);
    return user.healthDataResearchConsent;
  }
}
