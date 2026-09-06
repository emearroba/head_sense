// Shared (non-widget) helpers for the Interventions surfaces: building the
// user's list of medications/diets with a start date, computing before/after
// averages around that start date, and tiering the result into a plain-
// language "signal" label. Extracted out of what used to be
// InterventionsComparisonPanel-only logic so the Overview tab's "Since you
// started X" card and the Interventions tab's card list share one
// implementation instead of two copies drifting apart.
import '/backend/backend.dart';
import 'symptom_analytics.dart' show isoDateKey, kCrystalBlue;

enum InterventionKind { medication, diet }

class InterventionItem {
  const InterventionItem({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.startedAt,
    required this.kind,
  });

  final String id;
  final String label;
  final String sublabel;
  final DateTime? startedAt;
  final InterventionKind kind;
}

/// Builds the user's full list of tracked interventions (medications with a
/// dose + diets), sourced from `user.medicationDoses`/`dietTypeKeys` and
/// resolved against the medications/diet_types collections - the same shape
/// `InterventionsComparisonPanel` used to build inline.
List<InterventionItem> buildInterventionItems({
  required UsersRecord user,
  required Map<String, MedicationsRecord> medsById,
  required Map<String, DietTypesRecord> dietsById,
}) {
  final items = <InterventionItem>[
    for (final entry in user.medicationDoses.entries)
      if (medsById[entry.key] != null)
        InterventionItem(
          id: entry.key,
          label: medsById[entry.key]!.name,
          sublabel: entry.value,
          startedAt: user.medicationStartedAt[entry.key],
          kind: InterventionKind.medication,
        ),
    for (final id in user.dietTypeKeys)
      if (dietsById[id] != null)
        InterventionItem(
          id: id,
          label: dietsById[id]!.name,
          sublabel: 'Diet',
          startedAt: user.dietStartedAt[id],
          kind: InterventionKind.diet,
        ),
  ]..sort((a, b) => a.label.compareTo(b.label));
  return items;
}

class InterventionComparison {
  const InterventionComparison({
    required this.beforeAvg,
    required this.afterAvg,
    required this.beforeDays,
    required this.afterDays,
    required this.daysSinceStart,
  });

  final double beforeAvg;
  final double afterAvg;
  final int beforeDays;
  final int afterDays;
  final int daysSinceStart;

  double get delta => afterAvg - beforeAvg;
  bool get betterAfter => delta < 0;
  double? get deltaPct => beforeAvg == 0 ? null : delta / beforeAvg;
}

/// Before/after comparison for [record] around [startedAt] - requires at
/// least 5 tracked days on each side of the start date (same bar
/// InterventionsComparisonPanel has always used), else returns null: not
/// enough data yet to compare.
InterventionComparison? buildInterventionComparison(
  DashboardRecord record,
  DateTime startedAt,
) {
  final startKey = isoDateKey(startedAt);
  final tracked = record.dailyValues.where((d) => d.isTracked).toList();
  final before = tracked.where((d) => d.date.compareTo(startKey) < 0).toList();
  final after = tracked.where((d) => d.date.compareTo(startKey) >= 0).toList();
  if (before.length < 5 || after.length < 5) return null;

  final beforeAvg =
      before.map((d) => d.value).reduce((a, b) => a + b) / before.length;
  final afterAvg =
      after.map((d) => d.value).reduce((a, b) => a + b) / after.length;

  return InterventionComparison(
    beforeAvg: beforeAvg,
    afterAvg: afterAvg,
    beforeDays: before.length,
    afterDays: after.length,
    daysSinceStart: DateTime.now().difference(startedAt).inDays,
  );
}

class InterventionSignal {
  const InterventionSignal({
    required this.label,
    required this.color,
    required this.isEarly,
  });

  final String label;
  final Color color;
  final bool isEarly;
}

const _kPositiveGreen = Color(0xFF4CAF6D);
const _kWatchAmber = Color(0xFFFFC533);

/// Plain-language signal tier from a comparison's direction + how long the
/// intervention has been running - deliberately conservative about calling
/// anything "positive" before 14 days, and about calling a worsening trend
/// "worth watching" before 30, since a few days either way is easy to
/// over-read. Mirrors the app-wide 30-day baseline convention already used
/// by PatternLockCard/TrackingProgressCard, and the tiered-label pattern in
/// connectionStrengthTier.
InterventionSignal interventionSignalTier(InterventionComparison comparison) {
  final days = comparison.daysSinceStart;
  final improving = comparison.betterAfter;

  if (days < 14) {
    return const InterventionSignal(
      label: 'Early signal',
      color: kCrystalBlue,
      isEarly: true,
    );
  }
  if (days < 30) {
    return InterventionSignal(
      label: improving ? 'Early positive signal' : 'Early worsening signal',
      color: improving ? _kPositiveGreen : _kWatchAmber,
      isEarly: true,
    );
  }
  return InterventionSignal(
    label: improving ? 'Positive signal' : 'Worth watching',
    color: improving ? _kPositiveGreen : _kWatchAmber,
    isEarly: false,
  );
}
