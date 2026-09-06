// Shared (non-widget) helpers for the Results tab: the rainbow 0-10 color
// scale, intensity histogram/mode math, and the pairwise correlation logic
// used by both the "My symptoms" panel (pattern_insights_panel.dart) and the
// "Connections" panel (connections_panel.dart). Pulled out of
// pattern_insights_panel.dart so both panels can share one implementation
// instead of two copies drifting apart.
import 'dart:math';

import 'package:flutter/material.dart';

import '/backend/backend.dart';

// Same four semantic anchors used by the diary's intensity slider
// (metric_answer_input.dart) and the Dashboard's intensity legend, so a "4"
// reads as the same color everywhere in the app.
const Color kSevereRed = Color(0xFFBD3A31);
const Color kModerateTan = Color(0xFFCB9A61);
const Color kMildGreen = Color(0xFF7ABA5A);
const Color kCrystalBlue = Color(0xFFAEE0EA);

/// value: 0 (crystal clear) .. 10 (extremely high) -> rainbow color.
Color intensityColorForValue(double value) {
  final t = 1.0 - (value.clamp(0.0, 10.0) / 10.0);
  if (t <= 1 / 3) return Color.lerp(kSevereRed, kModerateTan, t / (1 / 3))!;
  if (t <= 2 / 3) {
    return Color.lerp(kModerateTan, kMildGreen, (t - 1 / 3) / (1 / 3))!;
  }
  return Color.lerp(kMildGreen, kCrystalBlue, (t - 2 / 3) / (1 / 3))!;
}

String intensityCategoryLabel(double value) {
  if (value <= 0) return 'Crystal clear';
  if (value <= 3) return 'Mild';
  if (value <= 6) return 'Moderate';
  return 'Severe';
}

Color hexToColor(String hex, {required Color fallback}) {
  if (hex.isEmpty) return fallback;
  var cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length == 6) cleaned = 'FF$cleaned';
  try {
    return Color(int.parse(cleaned, radix: 16));
  } catch (_) {
    return fallback;
  }
}

/// Counts tracked days by rounded intensity (0-10).
Map<int, int> intensityHistogram(Iterable<DailyValueStruct> tracked) {
  final histogram = {for (var i = 0; i <= 10; i++) i: 0};
  for (final d in tracked) {
    final bucket = d.value.round().clamp(0, 10);
    histogram[bucket] = (histogram[bucket] ?? 0) + 1;
  }
  return histogram;
}

/// The most frequently logged intensity, or null if there's no data at all.
/// Ties break toward the lower (better) value.
int? modeIntensityValue(Map<int, int> histogram) {
  int? best;
  var bestCount = 0;
  histogram.forEach((value, occurrences) {
    if (occurrences == 0) return;
    if (occurrences > bestCount ||
        (occurrences == bestCount && (best == null || value < best!))) {
      best = value;
      bestCount = occurrences;
    }
  });
  return best;
}

double? pearsonCorrelation(List<double> xs, List<double> ys) {
  final n = xs.length;
  if (n < 2) return null;
  final meanX = xs.reduce((a, b) => a + b) / n;
  final meanY = ys.reduce((a, b) => a + b) / n;
  var cov = 0.0, varX = 0.0, varY = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = xs[i] - meanX;
    final dy = ys[i] - meanY;
    cov += dx * dy;
    varX += dx * dx;
    varY += dy * dy;
  }
  if (varX == 0 || varY == 0) return null;
  return cov / sqrt(varX * varY);
}

String isoDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

bool isResponseMetric(String metricKey) => metricKey == 'analgesia';

/// (days both a and b have a tracked entry, days either does) - used for the
/// Connections tab's "logged together on N of M days" line, shown even when
/// no correlation clears the significance bar.
(int, int) symptomOverlap(DashboardRecord a, DashboardRecord b) {
  final aDates =
      a.dailyValues.where((d) => d.isTracked).map((d) => d.date).toSet();
  final bDates =
      b.dailyValues.where((d) => d.isTracked).map((d) => d.date).toSet();
  return (
    aDates.intersection(bDates).length,
    aDates.union(bDates).length,
  );
}

/// Same-day Pearson correlation between two tracked metrics, over the days
/// both have a tracked entry for. Returns null when fewer than
/// [minSampleDays] days overlap. Unlike [buildSymptomConnection] (which
/// searches lagged offsets for one anchor at a time and only returns a
/// result once |r| >= 0.3), this always returns the raw same-day r whenever
/// there's enough data - used by the Connections tab's correlation matrix,
/// where every pair needs one directly-comparable, symmetric number.
double? sameDayCorrelation(
  DashboardRecord a,
  DashboardRecord b, {
  int minSampleDays = 8,
}) {
  final aByDate = <String, double>{
    for (final d in a.dailyValues.where((d) => d.isTracked)) d.date: d.value,
  };
  final bByDate = <String, double>{
    for (final d in b.dailyValues.where((d) => d.isTracked)) d.date: d.value,
  };
  final xs = <double>[];
  final ys = <double>[];
  aByDate.forEach((date, value) {
    final otherValue = bByDate[date];
    if (otherValue != null) {
      xs.add(value);
      ys.add(otherValue);
    }
  });
  if (xs.length < minSampleDays) return null;
  return pearsonCorrelation(xs, ys);
}

// A pill label + color per correlation-strength tier - thresholds line up
// with the example set the Connections tab's design was modeled on (72% ->
// Strong, 48% -> Moderate, 31% -> Possible), and 30% is the effective floor
// since buildSymptomConnection only returns a connection once |r| >= 0.3.
// Shared by the Connections tab and the Overview tab's "strongest
// connections" mini-list so both use identical tiering/colors.
({String label, Color color}) connectionStrengthTier(int pct) {
  if (pct >= 60) return (label: 'Strong', color: const Color(0xFF4CAF6D));
  if (pct >= 40) return (label: 'Moderate', color: const Color(0xFFFFC533));
  return (label: 'Possible', color: kCrystalBlue);
}

enum ConnectionKind { risk, protective, precursor, response }

// Which side of the anchor day the "other" metric's strongest lag falls on -
// the literal axis the Connections tab's Before/Same day/After/All filter
// chips filter on. Independent of ConnectionKind (a precursor connection is
// always `before`/`after`, but a same-day risk/protective/response
// connection is always `sameDay`).
enum ConnectionTiming { before, sameDay, after }

// A discovered (or absent) relationship between two tracked symptoms, built
// around a fixed "anchor" metric (e.g. headache) vs. an "other" one (e.g.
// fatigue) - mirrors the connection logic that used to live inside
// PatternInsightsPanel's discovery engine, generalized so the Connections
// tab can run it for any pair the user picks, not just headache vs. a
// candidate.
class SymptomConnection {
  SymptomConnection({
    required this.kind,
    required this.icon,
    required this.title,
    required this.detail,
    required this.why,
    required this.strengthPct,
    required this.overlapDays,
    required this.totalDays,
    required this.sampleDays,
    required this.groupALabel,
    required this.groupAValue,
    required this.groupBLabel,
    required this.groupBValue,
    required this.highlightA,
    required this.timingBucket,
    required this.timingLabel,
    required this.lagDays,
  });

  final ConnectionKind kind;
  final IconData icon;
  final String title;
  final String detail;
  final String why;
  final int strengthPct;
  final int overlapDays;
  final int totalDays;
  final int sampleDays;
  final String groupALabel;
  final double groupAValue;
  final String groupBLabel;
  final double groupBValue;
  final bool highlightA;
  // Before/same day/after classification for the Connections tab's filter
  // chips, plus the raw signed lag (days the "other" metric leads the
  // anchor by; negative means it lags behind) the connection-detail Timeline
  // view anchors its -3d..+3d window's marker on.
  final ConnectionTiming timingBucket;
  final String timingLabel;
  final int lagDays;

  double get overlapPct => totalDays == 0 ? 0.0 : overlapDays / totalDays * 100.0;
}

class _PairedSeries {
  _PairedSeries(
      {required this.xs, required this.ys, required this.r, required this.lagDays});
  final List<double> xs;
  final List<double> ys;
  final double r;
  final int lagDays;
}

/// Looks for the strongest same-day-or-lagged relationship between [anchor]
/// and [other] (each tracked days across a 0-10 or boolean scale). Returns
/// null when nothing clears the |r| >= 0.3 / 8-day-minimum bar, in which
/// case the caller should show a "not enough of a pattern yet" state.
SymptomConnection? buildSymptomConnection(
  DashboardRecord anchor,
  DashboardRecord other, {
  int maxLagDays = 2,
}) {
  final anchorByDate = <String, double>{
    for (final d in anchor.dailyValues.where((d) => d.isTracked)) d.date: d.value,
  };
  final otherByDate = <String, double>{
    for (final d in other.dailyValues.where((d) => d.isTracked)) d.date: d.value,
  };
  final overlapDays =
      anchorByDate.keys.toSet().intersection(otherByDate.keys.toSet()).length;
  final totalDays = anchorByDate.keys.toSet().union(otherByDate.keys.toSet()).length;

  _PairedSeries? best;
  for (var lag = -maxLagDays; lag <= maxLagDays; lag++) {
    final xs = <double>[];
    final ys = <double>[];
    otherByDate.forEach((date, value) {
      final shiftedDate = DateTime.parse(date).add(Duration(days: lag));
      final anchorValue = anchorByDate[isoDateKey(shiftedDate)];
      if (anchorValue != null) {
        xs.add(value);
        ys.add(anchorValue);
      }
    });
    if (xs.length < 8) continue;
    final r = pearsonCorrelation(xs, ys);
    if (r == null || r.abs() < 0.3) continue;
    if (best == null || r.abs() > best.r.abs()) {
      best = _PairedSeries(xs: xs, ys: ys, r: r, lagDays: lag);
    }
  }
  if (best == null) return null;

  // Boolean metrics in this app's catalog are always phrased as yes/no
  // questions ("Ate a late meal?", "On your period?", "Did cardio today?" -
  // see seed_metrics.js's boolean() entries), unlike scale/numeric metrics
  // which are plain noun phrases ("Alcoholic drinks", "Bowel urgency"). A
  // question can't be dropped into a sentence the same way a noun phrase
  // can ("on days with on your period?" reads as nonsense), so anywhere a
  // boolean's label gets embedded mid-sentence below, it's quoted as an
  // answered question instead, with any trailing "?" stripped first so it
  // doesn't collide with the sentence's own punctuation.
  final otherLabelClean = other.metricLabel.endsWith('?')
      ? other.metricLabel.substring(0, other.metricLabel.length - 1).trim()
      : other.metricLabel;

  final isBoolean = best.xs.every((v) => v == 0.0 || v == 1.0);
  double groupAValue, groupBValue;
  String groupALabel, groupBLabel, thresholdNote;
  if (isBoolean) {
    final yesYs = <double>[];
    final noYs = <double>[];
    for (var i = 0; i < best.xs.length; i++) {
      (best.xs[i] == 1.0 ? yesYs : noYs).add(best.ys[i]);
    }
    if (yesYs.isEmpty || noYs.isEmpty) return null;
    groupAValue = yesYs.reduce((a, b) => a + b) / yesYs.length;
    groupBValue = noYs.reduce((a, b) => a + b) / noYs.length;
    groupALabel = '$otherLabelClean: yes';
    groupBLabel = '$otherLabelClean: no';
    thresholdNote = '';
  } else {
    final sortedXs = [...best.xs]..sort();
    final median = sortedXs[sortedXs.length ~/ 2];
    final highYs = <double>[];
    final lowYs = <double>[];
    for (var i = 0; i < best.xs.length; i++) {
      (best.xs[i] > median ? highYs : lowYs).add(best.ys[i]);
    }
    if (highYs.isEmpty || lowYs.isEmpty) return null;
    groupAValue = highYs.reduce((a, b) => a + b) / highYs.length;
    groupBValue = lowYs.reduce((a, b) => a + b) / lowYs.length;
    groupALabel = 'Higher ${other.metricLabel}';
    groupBLabel = 'Lower ${other.metricLabel}';
    thresholdNote = ' (split around ${median.toStringAsFixed(1)})';
  }

  final delta = groupAValue - groupBValue;
  final higher = delta > 0;
  final String timing;
  final ConnectionTiming timingBucket;
  if (best.lagDays == 0) {
    timing = 'on the same day';
    timingBucket = ConnectionTiming.sameDay;
  } else if (best.lagDays > 0) {
    timing = '${best.lagDays} day${best.lagDays == 1 ? '' : 's'} before';
    timingBucket = ConnectionTiming.before;
  } else {
    timing = '${-best.lagDays} day${-best.lagDays == 1 ? '' : 's'} after';
    timingBucket = ConnectionTiming.after;
  }

  final anchorLower = anchor.metricLabel.toLowerCase();
  final otherLower = other.metricLabel.toLowerCase();
  final effectSize = best.r.abs();
  final qualifier = effectSize > 0.5 ? ' much' : '';
  final isResponse =
      isResponseMetric(other.metricKey) && best.lagDays == 0 && higher;

  // The clause that follows "Your <anchor> is worse/better ___" - a plain
  // noun phrase for scale/numeric metrics, or a quoted answered-question for
  // booleans, so both read as a real sentence regardless of which kind of
  // metric was picked.
  final otherCondition = isBoolean
      ? 'on days you answered "yes" to "$otherLabelClean"'
      : 'when $otherLower is higher';
  // Same idea, but in subject position (used by the precursor title, which
  // leads with the "other" metric rather than the anchor).
  final otherSubject =
      isBoolean ? 'Answering "yes" to "$otherLabelClean"' : other.metricLabel;

  final ConnectionKind kind;
  final IconData icon;
  final String title;
  final String why;

  if (isResponse) {
    kind = ConnectionKind.response;
    icon = Icons.medication_outlined;
    title = 'When your $anchorLower is high, you tend to use $otherLower';
    why = 'This reads like a response, not a cause — it\'s natural to reach '
        'for treatment once symptoms are already there. Still worth '
        'tracking how consistently that happens, and mentioning the '
        'frequency to your doctor.';
  } else if (best.lagDays != 0) {
    kind = ConnectionKind.precursor;
    icon = Icons.history_rounded;
    title = '$otherSubject often shows up $timing your $anchorLower';
    why = 'Some effects take a day or two to build up before symptoms show '
        '— sleep and stress are common examples. That\'s why we also check '
        'a few days before and after, not just the same day.';
  } else if (higher) {
    kind = ConnectionKind.risk;
    icon = Icons.hub_rounded;
    title = 'Your $anchorLower is$qualifier worse $otherCondition';
    why = 'This kind of link between "$otherLabelClean" and '
        '"${anchor.metricLabel}" is common — many symptoms are sensitive to '
        'daily habits. It doesn\'t prove one causes the other, but it\'s a '
        'good place to pay closer attention.';
  } else {
    kind = ConnectionKind.protective;
    icon = Icons.shield_outlined;
    title = 'Your $anchorLower is$qualifier better $otherCondition';
    // Deliberately doesn't tell the user to do more of whatever "other" is -
    // for a habit like alcohol that reads as reckless advice, and for a
    // symptom like bowel urgency "do more of it" doesn't even make sense.
    // Just names the pattern and defers any action to their doctor.
    why = 'Whatever is behind this — routine, timing, or something else '
        'entirely — it lines up with your better days. Correlation isn\'t '
        'causation, so it\'s worth mentioning to your doctor rather than '
        'changing anything based on this alone.';
  }

  return SymptomConnection(
    kind: kind,
    icon: icon,
    title: title,
    detail: '$otherLabelClean$thresholdNote $timing: '
        '${anchor.metricLabel} averages ${groupAValue.toStringAsFixed(1)} vs '
        '${groupBValue.toStringAsFixed(1)}.',
    why: why,
    strengthPct: (effectSize * 100).round(),
    overlapDays: overlapDays,
    totalDays: totalDays,
    sampleDays: best.xs.length,
    groupALabel: groupALabel,
    groupAValue: groupAValue,
    groupBLabel: groupBLabel,
    groupBValue: groupBValue,
    highlightA: higher,
    timingBucket: timingBucket,
    timingLabel: timing,
    lagDays: best.lagDays,
  );
}

/// Runs [buildSymptomConnection] for [anchor] against every other tracked
/// metric in [allTracked], keeping only the ones that clear the existing
/// |r| >= 0.3 bar, sorted strongest-first. This is the "Somatica just tells
/// you" auto-ranked list - both the Overview tab's "strongest connections"
/// mini-list and the Connections tab's default (non-"Advanced") view call
/// this one function so they can never drift apart.
List<(DashboardRecord, SymptomConnection)> rankedConnections(
  DashboardRecord anchor,
  List<DashboardRecord> allTracked,
) {
  final pairs = <(DashboardRecord, SymptomConnection)>[];
  for (final other in allTracked) {
    if (other.metricKey == anchor.metricKey) continue;
    final connection = buildSymptomConnection(anchor, other);
    if (connection != null) pairs.add((other, connection));
  }
  pairs.sort((a, b) => b.$2.strengthPct.compareTo(a.$2.strengthPct));
  return pairs;
}
