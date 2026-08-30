// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'headline_metric_tiles.dart';
import 'intensity_distribution_chart.dart';
import 'symptom_analytics.dart';
import 'symptom_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'dart:math';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// "My symptoms" tab content for Core/Premium users on the Results screen
// (the free-tier PatternLockCard placeholder lives in results_widget.dart
// and is untouched; the "Connections" tab lives in connections_panel.dart).
// Sourced entirely from the `dashboard` docs the update_dashboard_metric.js
// cloud function already maintains per metricKey/periodType. Defaults to
// 'headache_intensity' as the symptom being analyzed, but the "Looking at:"
// dropdown lets the user switch to any other tracked metric that has
// scale-type dashboard data - everything below is computed around whichever
// one is selected, so none of the copy assumes "headache" specifically.
//
// Layout, top to bottom, is deliberately "results first": the Looking-at
// picker and period pills are compact filter chrome, then a bold "Your X
// results" heading anchors four headline metric tiles, a trend chart, an
// intensity distribution, and finally the narrative "What we noticed"
// insight cards - in that order of visual weight.
//
// Period selector has 4 pills: 7/30/60/90 days. There is no server-computed
// "last7" period (see PERIODS in update_dashboard_metric.js), so the weekly
// view is derived client-side from the trailing 7 entries of the last30
// doc's dailyValues instead of a separate query. The 60- and 90-day pills
// are Premium-only; Core users see them unlocked-looking but subtly
// star-marked and get an upsell dialog instead of running the query.
//
// "What we noticed" surfaces plain-language, scored findings (a weekday
// effect, a trend, an episode-length pattern, or a safety flag) rather than
// raw stats. Each discovery gets an interest score from effect size + how
// much data backs it + how consistent it is + a type-relevance weight; the
// top one is the headline insight, the rest follow as a ranked feed. See
// _buildDiscoveries and _Discovery.score.
class PatternInsightsPanel extends StatefulWidget {
  const PatternInsightsPanel({
    super.key,
    required this.trackedMetricKeys,
    required this.userPlan,
  });

  final List<String> trackedMetricKeys;
  final String userPlan;

  @override
  State<PatternInsightsPanel> createState() => _PatternInsightsPanelState();
}

class _PatternInsightsPanelState extends State<PatternInsightsPanel> {
  static const _defaultFocusMetricKey = 'headache_intensity';

  String _selectedPeriod = 'last30';
  // Which tracked metric the discoveries are built around - defaults to
  // headache but can be switched (e.g. to a sleep-quality metric) via the
  // dropdown in the header.
  String _selectedFocusKey = _defaultFocusMetricKey;

  bool get _isPremium => widget.userPlan == 'premium';
  static const _premiumPeriods = {'last60', 'last90'};

  void _selectPeriod(String period) {
    if (_premiumPeriods.contains(period) && !_isPremium) {
      _showPeriodUpsell(period);
      return;
    }
    setState(() => _selectedPeriod = period);
  }

  void _showPeriodUpsell(String period) {
    final label = period == 'last60' ? '60-day' : '90-day';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFFFC533)),
            const SizedBox(width: 8.0),
            Text(
              '$label view',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontWeight: FontWeight.w600,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
          ],
        ),
        content: Text(
          'Longer-range analysis is available with Premium — upgrade to '
          'unlock the $label view.',
          style: FlutterFlowTheme.of(context).bodySmall.override(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Not now',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO: wire to the real subscription flow once payment infra
              // (see CLAUDE.md) is built; for now this is a UI-only
              // placeholder, matching the existing upgrade TODO in
              // results_widget.dart.
            },
            child: const Text(
              'Upgrade',
              style: TextStyle(
                color: Color(0xFFFFC533),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortLabel(String metricLabel) => metricLabel
      .toLowerCase()
      .replaceAll(RegExp(r'\s+intensity$', caseSensitive: false), '');

  @override
  Widget build(BuildContext context) {
    // The 7-day pill has no server-computed period of its own — it's
    // derived from the last30 doc, so the query below always fetches
    // last30 while last7 is selected.
    final queryPeriod = _selectedPeriod == 'last7' ? 'last30' : _selectedPeriod;

    return StreamBuilder<List<DashboardRecord>>(
      stream: queryDashboardRecord(
        queryBuilder: (q) => q
            .where('userRef', isEqualTo: currentUserReference)
            .where('periodType', isEqualTo: queryPeriod),
      ),
      builder: (context, snapshot) {
        Widget? focusDropdown;
        Widget body;
        if (!snapshot.hasData) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          final docs = snapshot.data!;
          // Any metric the user tracks (plus the always-on headache +
          // painkiller ones) that actually has data for this period can be
          // picked as the symptom to analyze.
          final focusOptions = docs
              .where((d) =>
                  d.metricKey == 'headache_intensity' ||
                  d.metricKey == 'analgesia' ||
                  widget.trackedMetricKeys.contains(d.metricKey))
              .toList()
            ..sort((a, b) => a.metricLabel.compareTo(b.metricLabel));
          final focusKey = focusOptions.any((d) => d.metricKey == _selectedFocusKey)
              ? _selectedFocusKey
              : _defaultFocusMetricKey;
          focusDropdown = _focusSelector(context, focusOptions, focusKey);

          final focus = docs.firstWhereOrNull((d) => d.metricKey == focusKey);
          body = _selectedPeriod == 'last7'
              ? _weeklyView(context, focus)
              : _periodView(context, focus);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (focusDropdown != null) ...[
              focusDropdown,
              const SizedBox(height: 10.0),
            ],
            _periodSelector(context),
            const SizedBox(height: 18.0),
            body,
          ],
        );
      },
    );
  }

  Widget _focusSelector(
    BuildContext context,
    List<DashboardRecord> options,
    String selectedKey,
  ) {
    if (options.length <= 1) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          'Looking at: ',
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        DropdownButton<String>(
          value: selectedKey,
          dropdownColor: const Color(0xFF1A2A33),
          underline: const SizedBox.shrink(),
          style: FlutterFlowTheme.of(context).labelMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: FlutterFlowTheme.of(context).primaryText,
                fontWeight: FontWeight.w600,
              ),
          items: options
              .map((d) => DropdownMenuItem(
                    value: d.metricKey,
                    child: Text(d.metricLabel),
                  ))
              .toList(),
          onChanged: (key) {
            if (key == null) return;
            setState(() => _selectedFocusKey = key);
          },
        ),
      ],
    );
  }

  Widget _periodSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _pill(context, 'last7', '7 days')),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last30', '30 days')),
        const SizedBox(width: 8.0),
        Expanded(
          child: _pill(context, 'last60', '60 days', premium: !_isPremium),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _pill(context, 'last90', '90 days', premium: !_isPremium),
        ),
      ],
    );
  }

  Widget _pill(BuildContext context, String period, String label,
      {bool premium = false}) {
    final selected = _selectedPeriod == period;
    final selectedColor = FlutterFlowTheme.of(context).primary;
    return InkWell(
      onTap: () => _selectPeriod(period),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color:
              selected ? const Color(0xFF123C45) : const Color(0xFF1A2A33),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: selected ? selectedColor : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: selected
                    ? selectedColor
                    : FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            // Subtle star instead of a lock icon - the pill stays fully
            // visible/tappable, it just opens an upsell dialog for Core
            // users (see _selectPeriod).
            if (premium) ...[
              const SizedBox(width: 3.0),
              const Text(
                '✦',
                style: TextStyle(fontSize: 10.0, color: Color(0xFFFFC533)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultsHeading(BuildContext context, String metricLabel) {
    return Text(
      'Your ${_shortLabel(metricLabel)} results',
      style: FlutterFlowTheme.of(context).headlineSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            color: FlutterFlowTheme.of(context).primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 20.0,
          ),
    );
  }

  // ---- 30/60/90-day view ----

  Widget _periodView(BuildContext context, DashboardRecord? focus) {
    if (focus == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultsHeading(context, 'symptom'),
          const SizedBox(height: 16.0),
          _emptyCard(context, 'No data yet for this window.'),
        ],
      );
    }

    final tracked = focus.dailyValues.where((d) => d.isTracked);
    final histogram = intensityHistogram(tracked);
    final mode = modeIntensityValue(histogram);
    final hasEnoughData = focus.periodHasEnoughData;
    final eligible = focus.analysisEligible;

    final discoveries = (hasEnoughData && eligible)
        ? (_buildDiscoveries(focus)..sort((a, b) => b.score.compareTo(a.score)))
        : const <_Discovery>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultsHeading(context, focus.metricLabel),
        const SizedBox(height: 14.0),
        HeadlineMetricTiles(metrics: [
          HeadlineMetric(
            label: 'Average intensity',
            value: focus.symptomDays > 0
                ? focus.meanIntensitySymptomDays.toStringAsFixed(1)
                : '—',
            icon: Icons.show_chart_rounded,
            color: FlutterFlowTheme.of(context).primary,
          ),
          HeadlineMetric(
            label: 'Spikes',
            value: '${focus.spikeCount}',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFFC533),
          ),
          HeadlineMetric(
            label: 'Crystal clear days',
            value: '${focus.symptomFreeDays}',
            icon: Icons.spa_outlined,
            color: kCrystalBlue,
          ),
          HeadlineMetric(
            label: 'Most common intensity',
            value: mode == null ? '—' : '$mode',
            sublabel: mode == null ? null : intensityCategoryLabel(mode.toDouble()),
            icon: Icons.bar_chart_rounded,
            color: mode == null
                ? FlutterFlowTheme.of(context).secondaryText
                : intensityColorForValue(mode.toDouble()),
          ),
        ]),
        const SizedBox(height: 22.0),
        _sectionHeader(context, '${_shortLabel(focus.metricLabel)} trend'),
        const SizedBox(height: 8.0),
        _cardWrap(context, SymptomTrendChart(values: focus.dailyValues)),
        const SizedBox(height: 22.0),
        _sectionHeader(context, 'Intensity distribution'),
        const SizedBox(height: 8.0),
        _cardWrap(context, IntensityDistributionChart(histogram: histogram)),
        const SizedBox(height: 22.0),
        _sectionHeader(context, 'What we noticed'),
        const SizedBox(height: 8.0),
        if (!hasEnoughData)
          _emptyCard(
            context,
            "You've logged ${(focus.completionRate * 100).round()}% of "
            'days this period — a bit more consistency will unlock your '
            'insight cards.',
          )
        else if (!eligible)
          _emptyCard(
            context,
            'Your ${focus.metricLabel.toLowerCase()} has been pretty '
            "stable this period — not enough ups and downs yet to detect "
            "a pattern. That's good news!",
          )
        else if (discoveries.isEmpty)
          _emptyCard(
            context,
            'Nothing stands out strongly enough yet — keep tracking and '
            'check back soon.',
          )
        else ...[
          _heroCard(context, discoveries.first),
          ...discoveries.skip(1).take(6).map((d) => Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _discoveryCard(context, d),
              )),
        ],
      ],
    );
  }

  Widget _cardWrap(BuildContext context, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8.0, 14.0, 12.0, 8.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(
      text,
      style: FlutterFlowTheme.of(context).labelMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            color: FlutterFlowTheme.of(context).primaryText,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _emptyCard(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome,
              color: FlutterFlowTheme.of(context).secondaryText, size: 18.0),
          const SizedBox(width: 10.0),
          Expanded(child: _note(context, message)),
        ],
      ),
    );
  }

  // ---- Discovery engine ----
  //
  // Every discovery gets a 0-1 score from four ingredients, matching the
  // "effect size + amount of data + consistency + relevance" idea:
  //   score = 0.4*effectSize + 0.3*consistency + 0.2*dataAmount + 0.1*relevance
  // These are deliberately simple, roughly-normalized proportions rather
  // than rigorous statistics - good enough to *rank* candidate discoveries
  // against each other, which is all a score needs to do here.
  List<_Discovery> _buildDiscoveries(DashboardRecord focus) {
    final all = <_Discovery>[];

    all.addAll(_weekdayDiscoveries(focus));

    final trend = _trendDiscovery(focus);
    if (trend != null) all.add(trend);

    final episode = _episodeDiscovery(focus);
    if (episode != null) all.add(episode);

    all.addAll(_alertDiscoveries(focus));

    // Reserve one slot per category (best/worst day, trend, episode length,
    // safety alerts) and keep only the best-scoring candidate for each.
    final bySlot = <String, _Discovery>{};
    for (final d in all) {
      final existing = bySlot[d.slotKey];
      if (existing == null || d.score > existing.score) {
        bySlot[d.slotKey] = d;
      }
    }
    return bySlot.values.toList();
  }

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Best and worst weekday are two separate reserved slots (not "the one
  // most extreme day") so a strong good-day pattern doesn't get buried
  // just because the bad-day pattern happens to score slightly higher.
  List<_Discovery> _weekdayDiscoveries(DashboardRecord focus) {
    final byWeekday = <int, List<double>>{};
    var overallSum = 0.0;
    var overallCount = 0;
    for (final d in focus.dailyValues) {
      if (!d.isTracked) continue;
      final weekday = DateTime.parse(d.date).weekday;
      (byWeekday[weekday] ??= []).add(d.value);
      overallSum += d.value;
      overallCount++;
    }
    if (overallCount < 10) return const [];
    final overallMean = overallSum / overallCount;

    final weekMeans = List<double?>.filled(7, null);
    for (var wd = 1; wd <= 7; wd++) {
      final values = byWeekday[wd];
      if (values == null || values.length < 3) continue;
      weekMeans[wd - 1] = values.reduce((a, b) => a + b) / values.length;
    }

    int? worstIdx, bestIdx;
    var worstDelta = 0.0, bestDelta = 0.0;
    for (var i = 0; i < 7; i++) {
      final mean = weekMeans[i];
      if (mean == null) continue;
      final delta = mean - overallMean;
      if (delta > worstDelta) {
        worstDelta = delta;
        worstIdx = i;
      }
      if (delta < bestDelta) {
        bestDelta = delta;
        bestIdx = i;
      }
    }

    _Discovery buildCard(int dayIdx, double delta, bool isWorst) {
      final dayName = _weekdayNames[dayIdx];
      final values = byWeekday[dayIdx + 1]!;
      final matching = values
          .where((v) => isWorst ? v > overallMean : v < overallMean)
          .length;
      final consistency = matching / values.length;
      final effectSize =
          (delta.abs() / (overallMean.abs() + 1.0)).clamp(0.0, 1.0);
      final dataAmount = (values.length / 8).clamp(0.0, 1.0);
      const relevance = 0.85;
      final qualifier = effectSize > 0.5 ? ' by a lot' : '';

      return _Discovery(
        kind: _DiscoveryKind.weekday,
        slotKey: isWorst ? 'weekday_worst' : 'weekday_best',
        icon:
            isWorst ? Icons.trending_up_rounded : Icons.trending_down_rounded,
        title: '${dayName}s are your ${isWorst ? 'worst' : 'best'} '
            'day$qualifier',
        detail:
            '${focus.metricLabel} averages ${(overallMean + delta).toStringAsFixed(1)} '
            'on ${dayName}s vs ${overallMean.toStringAsFixed(1)} overall · '
            '$matching of your last ${values.length} ${dayName}s stood out.',
        badge: '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} pts',
        score: 0.4 * effectSize + 0.3 * consistency + 0.2 * dataAmount +
            0.1 * relevance,
        why: isWorst
            ? 'Certain days can carry different routines, sleep, stress, or '
                'social patterns that build up over time. A weekday '
                'pattern like this is common and often points to a '
                'specific habit worth a closer look.'
            : 'A consistently good day can be just as revealing as a bad '
                'one — whatever is different about your routine on this '
                'day may be worth repeating on the others.',
        visual: _WeekBarsVisual(means: weekMeans, highlightIndex: dayIdx),
      );
    }

    final discoveries = <_Discovery>[];
    if (worstIdx != null && worstDelta >= 0.5) {
      discoveries.add(buildCard(worstIdx, worstDelta, true));
    }
    if (bestIdx != null && bestDelta <= -0.5) {
      discoveries.add(buildCard(bestIdx, bestDelta, false));
    }
    return discoveries;
  }

  _Discovery? _trendDiscovery(DashboardRecord focus) {
    final sorted = [...focus.dailyValues]..sort((a, b) => a.day.compareTo(b.day));
    final tracked = sorted.where((d) => d.isTracked).toList();
    if (tracked.length < 14) return null;

    // Bucket into trailing 7-day weeks, oldest first.
    final weeks = <double>[];
    for (var start = 0; start + 4 <= tracked.length; start += 7) {
      final end = min(start + 7, tracked.length);
      final bucket = tracked.sublist(start, end);
      if (bucket.length < 4) break;
      weeks.add(bucket.map((d) => d.value).reduce((a, b) => a + b) /
          bucket.length);
    }
    if (weeks.length < 3) return null;

    // Trailing run (from the most recent week backward) of consistent
    // improvement or worsening, so "3 weeks improving" means the last 3
    // weekly averages have each moved the same direction.
    var streak = 1;
    final improving = weeks.last < weeks[weeks.length - 2];
    for (var i = weeks.length - 1; i > 0; i--) {
      final stepImproving = weeks[i] < weeks[i - 1];
      if (stepImproving != improving) break;
      if (i == weeks.length - 1) continue;
      streak++;
    }
    if (streak < 2) return null;

    final firstOfStreak = weeks[weeks.length - streak - 1 < 0
        ? 0
        : weeks.length - streak - 1];
    final delta = (weeks.last - firstOfStreak).abs();
    if (delta < 0.3) return null;

    final effectSize = (delta / (firstOfStreak.abs() + 1.0)).clamp(0.0, 1.0);
    final consistency = (streak / weeks.length).clamp(0.0, 1.0);
    final dataAmount = (tracked.length / (streak * 7)).clamp(0.0, 1.0);
    const relevance = 0.6;

    return _Discovery(
      kind: _DiscoveryKind.trend,
      slotKey: 'trend',
      icon: improving ? Icons.trending_down_rounded : Icons.trending_up_rounded,
      title: "You've been $streak weeks "
          '${improving ? 'improving' : 'trending worse'}',
      detail: '${focus.metricLabel} weekly average moved from '
          '${firstOfStreak.toStringAsFixed(1)} to '
          '${weeks.last.toStringAsFixed(1)} over that time.',
      badge: '$streak wk${streak == 1 ? '' : 's'}',
      score: 0.4 * effectSize + 0.3 * consistency + 0.2 * dataAmount +
          0.1 * relevance,
      why: 'Trends can reflect a real change in routine, treatment, or '
          'environment — or just natural variation. A few more weeks of '
          'tracking will show whether it holds.',
      visual: _SparklineVisual(values: weeks, improving: improving),
    );
  }

  _Discovery? _episodeDiscovery(DashboardRecord focus) {
    final sorted = [...focus.dailyValues]..sort((a, b) => a.day.compareTo(b.day));
    final lengths = <int>[];
    var current = 0;
    for (final d in sorted) {
      if (d.isTracked && d.isSevere) {
        current++;
      } else if (current > 0) {
        lengths.add(current);
        current = 0;
      }
    }
    if (current > 0) lengths.add(current);
    if (lengths.length < 2) return null;

    final avg = lengths.reduce((a, b) => a + b) / lengths.length;
    if (avg < 1.4) return null;
    final longest = lengths.reduce(max);

    final effectSize = (avg / 5).clamp(0.0, 1.0);
    final consistency = (lengths.length / 6).clamp(0.0, 1.0);
    final dataAmount = (lengths.length / 4).clamp(0.0, 1.0);
    const relevance = 0.55;

    return _Discovery(
      kind: _DiscoveryKind.episode,
      slotKey: 'episode',
      icon: Icons.timelapse_rounded,
      title: 'Your severe ${focus.metricLabel.toLowerCase()} episodes '
          'usually last ${avg.toStringAsFixed(1)} days',
      detail: '${lengths.length} separate episode'
          '${lengths.length == 1 ? '' : 's'} this period, longest '
          '$longest day${longest == 1 ? '' : 's'}.',
      badge: '${avg.toStringAsFixed(1)}d avg',
      score: 0.4 * effectSize + 0.3 * consistency + 0.2 * dataAmount +
          0.1 * relevance,
      why: 'Knowing how long a bad stretch typically lasts can help you '
          'plan around it — and a change in that typical length over time '
          'is itself worth noticing.',
    );
  }

  List<_Discovery> _alertDiscoveries(DashboardRecord focus) {
    final alerts = <_Discovery>[];

    if (focus.currentSevereStreak >= 2) {
      final n = focus.currentSevereStreak;
      alerts.add(_Discovery(
        kind: _DiscoveryKind.alert,
        slotKey: 'alert_severe_streak',
        icon: Icons.warning_amber_rounded,
        title: "You're on a $n-day streak of severe ${focus.metricLabel} days",
        detail: 'Worth flagging to your doctor if it continues.',
        badge: '$n',
        color: _alertColor,
        score: 0.4 * (n / 5).clamp(0.0, 1.0) + 0.3 + 0.2 + 0.1,
        why: 'Frequent severe days are worth mentioning to your doctor, '
            'especially alongside how often you\'re using pain medication.',
      ));
    }

    if (focus.periodDays > 0) {
      final painkillerRate = focus.painkillerDays / focus.periodDays;
      if (painkillerRate >= 10 / 30) {
        alerts.add(_Discovery(
          kind: _DiscoveryKind.alert,
          slotKey: 'alert_painkiller',
          icon: Icons.medication_rounded,
          title: 'Frequent pain medication use',
          detail: 'Used on ${focus.painkillerDays} of the last '
              '${focus.periodDays} days — frequent use like this can '
              'itself trigger more headaches.',
          badge: '${focus.painkillerDays}/${focus.periodDays}',
          color: _alertColor,
          score: 0.4 * painkillerRate.clamp(0.0, 1.0) + 0.3 + 0.2 + 0.1,
          why: 'Medication-overuse headache is a recognized pattern — '
              "it's worth mentioning to your doctor if this keeps up.",
        ));
      }
    }

    if (focus.spikeCount >= 2) {
      alerts.add(_Discovery(
        kind: _DiscoveryKind.info,
        slotKey: 'info_spike',
        icon: Icons.bolt_rounded,
        title: '${focus.spikeCount} notable spikes this period',
        detail: 'Sudden jumps in ${focus.metricLabel.toLowerCase()} worth '
            'a closer look in your diary.',
        badge: '${focus.spikeCount}',
        score: 0.4 * (focus.spikeCount / 5).clamp(0.0, 1.0) + 0.3 * 0.5 +
            0.2 * 0.5 + 0.1 * 0.5,
        why: 'Spikes can help pinpoint a specific trigger day — checking '
            "what else was different on those days is a good next step.",
      ));
    }

    return alerts;
  }

  // ---- 7-day view: derived client-side from the last30 doc's dailyValues. ----

  Widget _weeklyView(BuildContext context, DashboardRecord? focus30) {
    if (focus30 == null || focus30.dailyValues.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultsHeading(context, focus30?.metricLabel ?? 'symptom'),
          const SizedBox(height: 16.0),
          _emptyCard(context, 'No data yet for this week.'),
        ],
      );
    }

    final sorted = [...focus30.dailyValues]..sort((a, b) => a.day.compareTo(b.day));
    final weekSlice =
        sorted.length <= 7 ? sorted : sorted.sublist(sorted.length - 7);
    final tracked = weekSlice.where((d) => d.isTracked).toList();
    final trackedCount = tracked.length;
    final symptomDays = tracked.where((d) => d.value > 0).toList();
    final meanIntensity = symptomDays.isEmpty
        ? null
        : symptomDays.map((d) => d.value).reduce((a, b) => a + b) /
            symptomDays.length;
    final spikes = weekSlice.where((d) => d.isSpike).length;
    final crystalDays = tracked.where((d) => d.value <= 0).length;
    final histogram = intensityHistogram(tracked);
    final mode = modeIntensityValue(histogram);
    final severeStreak = _trailingSevereStreak(weekSlice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultsHeading(context, focus30.metricLabel),
        const SizedBox(height: 14.0),
        HeadlineMetricTiles(metrics: [
          HeadlineMetric(
            label: 'Average intensity',
            value: meanIntensity == null ? '—' : meanIntensity.toStringAsFixed(1),
            icon: Icons.show_chart_rounded,
            color: FlutterFlowTheme.of(context).primary,
          ),
          HeadlineMetric(
            label: 'Spikes',
            value: '$spikes',
            icon: Icons.bolt_rounded,
            color: const Color(0xFFFFC533),
          ),
          HeadlineMetric(
            label: 'Crystal clear days',
            value: '$crystalDays',
            icon: Icons.spa_outlined,
            color: kCrystalBlue,
          ),
          HeadlineMetric(
            label: 'Most common intensity',
            value: mode == null ? '—' : '$mode',
            sublabel: mode == null ? null : intensityCategoryLabel(mode.toDouble()),
            icon: Icons.bar_chart_rounded,
            color: mode == null
                ? FlutterFlowTheme.of(context).secondaryText
                : intensityColorForValue(mode.toDouble()),
          ),
        ]),
        const SizedBox(height: 22.0),
        _sectionHeader(context, '${_shortLabel(focus30.metricLabel)} trend'),
        const SizedBox(height: 8.0),
        _cardWrap(context, SymptomTrendChart(values: weekSlice, height: 130.0)),
        const SizedBox(height: 22.0),
        _sectionHeader(context, 'Intensity distribution'),
        const SizedBox(height: 8.0),
        _cardWrap(context, IntensityDistributionChart(histogram: histogram, height: 110.0)),
        const SizedBox(height: 22.0),
        _sectionHeader(context, 'What we noticed'),
        const SizedBox(height: 8.0),
        if (trackedCount < 5)
          _emptyCard(
            context,
            'Log a few more days this week to unlock your insight cards.',
          )
        else ...[
          if (severeStreak > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _discoveryCard(
                context,
                _Discovery(
                  kind: _DiscoveryKind.alert,
                  slotKey: 'weekly_alert',
                  icon: Icons.warning_amber_rounded,
                  title: "You're on a $severeStreak-day streak of severe days",
                  detail: 'Worth flagging if it continues.',
                  color: _alertColor,
                  score: 0,
                ),
              ),
            ),
          if (spikes > 0)
            _discoveryCard(
              context,
              _Discovery(
                kind: _DiscoveryKind.info,
                slotKey: 'weekly_spike',
                icon: Icons.bolt_rounded,
                title: '$spikes notable spike${spikes == 1 ? '' : 's'} this week',
                detail: 'Worth a closer look in your diary.',
                score: 0,
              ),
            ),
          if (spikes == 0 && severeStreak == 0)
            _emptyCard(context, 'Nothing urgent this week.'),
          const SizedBox(height: 8.0),
          _note(
            context,
            'Weekday and trend insight cards need more history — switch to '
            '30 days or more for those.',
          ),
        ],
      ],
    );
  }

  int _trailingSevereStreak(List<DailyValueStruct> weekSlice) {
    var streak = 0;
    for (final d in weekSlice.reversed) {
      if (d.isTracked && d.isSevere) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ---- Presentation helpers ----

  static const _alertColor = Color(0xFFBD3A31);

  void _showWhy(BuildContext context, _Discovery d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why might this be happening?',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontWeight: FontWeight.w700,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            const SizedBox(height: 12.0),
            Text(
              d.why ?? "We don't have a general explanation for this one yet.",
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    lineHeight: 1.5,
                  ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'General information, not a diagnosis — talk to your doctor '
              'about what fits your situation.',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(fontStyle: FontStyle.italic),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(BuildContext context, _Discovery d) {
    final color = d.color ?? FlutterFlowTheme.of(context).primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            FlutterFlowTheme.of(context).secondaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(d.icon, color: color, size: 22.0),
              ),
              if (d.badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    d.badge!,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.0),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14.0),
          Text(
            d.title,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 19.0,
                ),
          ),
          const SizedBox(height: 6.0),
          Text(
            d.detail,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  color: FlutterFlowTheme.of(context).secondaryText,
                  lineHeight: 1.4,
                ),
          ),
          if (d.visual != null) ...[
            const SizedBox(height: 16.0),
            d.visual!.build(context, color),
          ],
          if (d.why != null) ...[
            const SizedBox(height: 16.0),
            OutlinedButton(
              onPressed: () => _showWhy(context, d),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
              ),
              child: const Text(
                'Why might this be happening?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _discoveryCard(BuildContext context, _Discovery d) {
    final color = d.color ?? FlutterFlowTheme.of(context).primary;
    return InkWell(
      onTap: d.why == null ? null : () => _showWhy(context, d),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(d.icon, color: color, size: 18.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.title,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    d.detail,
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          lineHeight: 1.4,
                        ),
                  ),
                  if (d.visual != null) ...[
                    const SizedBox(height: 10.0),
                    d.visual!.build(context, color),
                  ],
                ],
              ),
            ),
            if (d.badge != null) ...[
              const SizedBox(width: 8.0),
              Text(
                d.badge!,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 13.0),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _note(BuildContext context, String text) {
    return Text(
      text,
      style: FlutterFlowTheme.of(context).labelSmall.override(
            font: GoogleFonts.inter(),
            color: FlutterFlowTheme.of(context).secondaryText,
            lineHeight: 1.4,
          ),
    );
  }
}

enum _DiscoveryKind {
  weekday,
  trend,
  episode,
  alert,
  info,
}

class _Discovery {
  _Discovery({
    required this.kind,
    required this.slotKey,
    required this.icon,
    required this.title,
    required this.detail,
    required this.score,
    this.badge,
    this.color,
    this.why,
    this.visual,
  });

  final _DiscoveryKind kind;
  // One card per slotKey survives into the feed (the highest-scoring), so
  // multiple candidate cards in the same category never crowd out the
  // others - the feed reads as a varied story instead of a ranked list of
  // same-shaped cards.
  final String slotKey;
  final IconData icon;
  final String title;
  final String detail;
  final double score;
  final String? badge;
  final Color? color;
  final String? why;
  final _Visual? visual;
}

// A small inline visual embedded in a discovery card. Kept as an interface
// so different discovery types (a weekday bar row vs. a weekly trend line)
// can each render their own compact chart with one shared call site.
abstract class _Visual {
  Widget build(BuildContext context, Color accent);
}

// The full Mon-Sun week as thin bars, the featured day highlighted in the
// accent color with its value labeled directly above it (everything else
// stays muted, per the "label selectively, not every point" rule) - this is
// what makes "Saturdays are your worst day" immediately legible instead of
// an abstract two-number comparison.
class _WeekBarsVisual implements _Visual {
  _WeekBarsVisual({required this.means, required this.highlightIndex});

  // Monday-first, matching the rest of the app's calendar (index 0=Mon..
  // 6=Sun); null where that weekday doesn't have enough tracked occurrences
  // to trust.
  final List<double?> means;
  final int highlightIndex;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _maxBarHeight = 44.0;

  @override
  Widget build(BuildContext context, Color accent) {
    final values = means.whereType<double>().toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce(max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final baseline = FlutterFlowTheme.of(context).alternate;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final mean = means[i];
        final isHighlight = i == highlightIndex;
        final barHeight = mean == null
            ? 3.0
            : (mean / safeMax).clamp(0.05, 1.0) * _maxBarHeight;
        final color = mean == null
            ? baseline.withValues(alpha: 0.3)
            : (isHighlight ? accent : baseline);
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 14.0,
                child: isHighlight && mean != null
                    ? Center(
                        child: Text(
                          mean.toStringAsFixed(1),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.0,
                          ),
                        ),
                      )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                _dayLetters[i],
                style: TextStyle(
                  color: isHighlight
                      ? accent
                      : FlutterFlowTheme.of(context).secondaryText,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11.0,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// A thin trend line across weekly averages, oldest to newest, with a dot
// marking the latest week - just enough to make "you've been improving"
// visually obvious without a full chart-with-axes.
class _SparklineVisual implements _Visual {
  _SparklineVisual({required this.values, required this.improving});

  final List<double> values;
  final bool improving;

  @override
  Widget build(BuildContext context, Color accent) {
    final color = improving ? const Color(0xFF4FA8B2) : const Color(0xFFBD3A31);
    return SizedBox(
      height: 40.0,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(values: values, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final normalized = (values[i] - minV) / range;
      // Invert Y: higher value draws higher on screen.
      final y = size.height - (normalized * size.height);
      return Offset(dx * i, y.clamp(2.0, size.height - 2.0));
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = pointAt(values.length - 1);
    canvas.drawCircle(last, 3.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
