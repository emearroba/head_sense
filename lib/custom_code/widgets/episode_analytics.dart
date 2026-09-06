// Episode-based analytics for the Connections tab's per-connection detail
// view (connection_detail_sheet.dart + episode_timeline_chart.dart). Kept
// separate from symptom_analytics.dart (which owns the pairwise correlation
// engine) since this operates on top of it: an "episode" is a run of
// consecutive days where the anchor metric spikes above the person's own
// baseline, and these helpers describe what happens around those runs.
import 'dart:math';

import '/backend/backend.dart';
import 'symptom_analytics.dart';

/// A run of consecutive tracked days where the anchor metric was at least
/// [Episode]'s originating threshold above the person's baseline (see
/// [detectEpisodes]). [start] is offset 0 for the Timeline view - the
/// mockup anchors -3d..+3d on the first day of the episode, not its peak.
class Episode {
  Episode({required this.start, required this.end, required this.peakValue});

  final DateTime start;
  final DateTime end;
  final double peakValue;

  int get lengthDays => end.difference(start).inDays + 1;
}

/// Groups [anchor]'s tracked days into episodes: a day qualifies once its
/// value is at least [deltaAboveMean] points above the anchor's own
/// `meanIntensityTrackedDays`, and calendar-adjacent qualifying days merge
/// into one episode. A missing (untracked) day, or a non-qualifying tracked
/// day, breaks a run even if the next qualifying day is otherwise close by -
/// deliberately conservative so episodes reflect confirmed data, not gaps.
List<Episode> detectEpisodes(
  DashboardRecord anchor, {
  double deltaAboveMean = 2.0,
}) {
  final threshold = anchor.meanIntensityTrackedDays + deltaAboveMean;
  final tracked = anchor.dailyValues.where((d) => d.isTracked).toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  final episodes = <Episode>[];
  DateTime? runStart;
  DateTime? runEnd;
  var runPeak = 0.0;

  void closeRun() {
    if (runStart != null && runEnd != null) {
      episodes.add(Episode(start: runStart!, end: runEnd!, peakValue: runPeak));
    }
    runStart = null;
    runEnd = null;
    runPeak = 0.0;
  }

  for (final d in tracked) {
    final date = DateTime.parse(d.date);
    if (d.value >= threshold) {
      if (runEnd != null && date.difference(runEnd!).inDays > 1) {
        closeRun();
      }
      runStart ??= date;
      runEnd = date;
      if (d.value > runPeak) runPeak = d.value;
    } else {
      closeRun();
    }
  }
  closeRun();

  return episodes;
}

/// One point on the Timeline chart's -windowDays..+windowDays x-axis:
/// [other]'s average % change vs its own baseline, [windowDays] days
/// before/after each episode's start, averaged across every episode that had
/// tracked data for [other] at that offset. Null fields mean no episode had
/// data at that offset (or [other]'s baseline is ~0, where "% change" isn't
/// meaningful) - the chart should render a gap there, not a zero.
class OffsetPoint {
  OffsetPoint({
    required this.offset,
    required this.pctChangeVsBaseline,
    required this.bandLow,
    required this.bandHigh,
    required this.sampleCount,
  });

  final int offset;
  final double? pctChangeVsBaseline;
  final double? bandLow;
  final double? bandHigh;
  final int sampleCount;
}

List<OffsetPoint> buildEpisodeTimeline(
  List<Episode> episodes,
  DashboardRecord other, {
  int windowDays = 3,
}) {
  final otherByDate = <String, double>{
    for (final d in other.dailyValues.where((d) => d.isTracked)) d.date: d.value,
  };
  final baseline = other.meanIntensityTrackedDays;

  final points = <OffsetPoint>[];
  for (var offset = -windowDays; offset <= windowDays; offset++) {
    final changes = <double>[];
    for (final episode in episodes) {
      final date = episode.start.add(Duration(days: offset));
      final value = otherByDate[isoDateKey(date)];
      if (value == null || baseline.abs() < 1e-6) continue;
      changes.add((value - baseline) / baseline * 100.0);
    }
    if (changes.isEmpty) {
      points.add(OffsetPoint(
        offset: offset,
        pctChangeVsBaseline: null,
        bandLow: null,
        bandHigh: null,
        sampleCount: 0,
      ));
    } else {
      final mean = changes.reduce((a, b) => a + b) / changes.length;
      points.add(OffsetPoint(
        offset: offset,
        pctChangeVsBaseline: mean,
        bandLow: changes.reduce(min),
        bandHigh: changes.reduce(max),
        sampleCount: changes.length,
      ));
    }
  }
  return points;
}

/// The "Key takeaway" stat tiles for a connection's detail Summary tab: how
/// many episodes (that had tracked data for [other] at the connection's own
/// best-lag offset) actually showed [other] on the side [connection] already
/// established (its `highlightA` direction), out of how many could be
/// checked at all.
class ConnectionSummaryStats {
  ConnectionSummaryStats({
    required this.episodesWithPattern,
    required this.checkableEpisodes,
    required this.typicalTiming,
    required this.consistencyLabel,
  });

  final int episodesWithPattern;
  final int checkableEpisodes;
  final String typicalTiming;
  final String consistencyLabel;

  int get consistencyPct =>
      checkableEpisodes == 0 ? 0 : (episodesWithPattern / checkableEpisodes * 100).round();
}

ConnectionSummaryStats buildConnectionSummary(
  List<Episode> episodes,
  DashboardRecord other,
  SymptomConnection connection, {
  int windowDays = 3,
}) {
  final otherByDate = <String, double>{
    for (final d in other.dailyValues.where((d) => d.isTracked)) d.date: d.value,
  };
  final isBoolean = otherByDate.values.isNotEmpty &&
      otherByDate.values.every((v) => v == 0.0 || v == 1.0);
  final offset = connection.lagDays.clamp(-windowDays, windowDays);
  final baseline = other.meanIntensityTrackedDays;

  var withPattern = 0;
  var checkable = 0;
  for (final episode in episodes) {
    final value = otherByDate[isoDateKey(episode.start.add(Duration(days: offset)))];
    if (value == null) continue;
    checkable++;
    final holds = isBoolean
        ? (connection.highlightA ? value == 1.0 : value == 0.0)
        : (connection.highlightA ? value >= baseline : value < baseline);
    if (holds) withPattern++;
  }

  final pct = checkable == 0 ? 0 : (withPattern / checkable * 100).round();
  final consistencyLabel = checkable == 0
      ? 'Not enough data'
      : pct >= 70
          ? 'High'
          : pct >= 40
              ? 'Moderate'
              : 'Low';

  return ConnectionSummaryStats(
    episodesWithPattern: withPattern,
    checkableEpisodes: checkable,
    typicalTiming: connection.timingLabel,
    consistencyLabel: consistencyLabel,
  );
}
