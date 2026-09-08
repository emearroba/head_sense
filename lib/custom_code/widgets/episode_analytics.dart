// Episode-based analytics for the Connections tab's per-connection detail
// view (connection_detail_sheet.dart + episode_timeline_chart.dart). Kept
// separate from symptom_analytics.dart (which owns the pairwise correlation
// engine) since this operates on top of it: an "episode" is a single spike
// day of the anchor metric, and these helpers describe what happens around
// each one.
import 'dart:math';

import '/backend/backend.dart';
import 'symptom_analytics.dart';

/// A single spike day of the anchor metric - one per qualifying day, never
/// merged with adjacent qualifying days (a spike is valid even if it only
/// lasts one day, and two spikes on consecutive days are two separate
/// events, each getting their own -windowDays..+windowDays look-around, not
/// one shared window). [start] and [end] are the same date; kept as a
/// start/end pair (rather than a single `date`) so this still drops into
/// [buildEpisodeTimeline]/[buildConnectionSummary] and
/// [EpisodeTimelineChart] unchanged, all of which only ever read [start].
class Episode {
  Episode({required this.start, required this.end, required this.peakValue});

  final DateTime start;
  final DateTime end;
  final double peakValue;

  int get lengthDays => end.difference(start).inDays + 1;
}

/// One [Episode] per day [anchor] recorded a spike, using the exact same
/// `isSpike` the "N Spikes" headline stat is built from (see
/// update_dashboard_metric.js: a day-over-day jump of at least 2 points from
/// the previous *tracked* day - not a fixed level above the person's
/// average). Deliberately not merged/deduplicated when consecutive days both
/// spike - each is its own event with its own before/after window.
List<Episode> detectEpisodes(DashboardRecord anchor) {
  return [
    for (final d in anchor.dailyValues.where((d) => d.isTracked && d.isSpike))
      Episode(
        start: DateTime.parse(d.date),
        end: DateTime.parse(d.date),
        peakValue: d.value,
      ),
  ];
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
  // connection.lagDays is "days the *other* metric leads the anchor by" (see
  // symptom_analytics.dart) - so relative to the anchor episode's start
  // date, the other metric's date is `start - lagDays`, not `start +
  // lagDays`. This was unnegated and checking the wrong side of every
  // episode (e.g. a connection reported as "2 days before" was being
  // verified 2 days *after* each episode instead), which is why these stats
  // and the Timeline chart (whose x-axis does use the correct before/after
  // sign) told two different stories for the same connection.
  final offset = (-connection.lagDays).clamp(-windowDays, windowDays);
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
