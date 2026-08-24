// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'dart:math';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Real pattern analysis for Core/Premium users on the Patterns tab (the
// free-tier PatternLockCard placeholder lives in results_widget.dart and is
// untouched). Sourced entirely from the `dashboard` docs the
// update_dashboard_metric.js cloud function already maintains per
// metricKey/periodType, focused on the app's primary symptom
// ('headache_intensity').
//
// Period selector has 4 pills: 7/30/60/90 days. There is no server-computed
// "last7" period (see PERIODS in update_dashboard_metric.js), so the weekly
// view is derived client-side from the trailing 7 entries of the last30
// doc's dailyValues instead of a separate query. The 7-day pill is
// Premium-only; Core users see it locked and get an upsell dialog instead
// of running the query.
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
  static const _focusMetricKey = 'headache_intensity';

  String _selectedPeriod = 'last30';

  bool get _isPremium => widget.userPlan == 'premium';

  void _selectPeriod(String period) {
    if (period == 'last7' && !_isPremium) {
      _showWeeklyUpsell();
      return;
    }
    setState(() => _selectedPeriod = period);
  }

  void _showWeeklyUpsell() {
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
              'Weekly analysis',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontWeight: FontWeight.w600,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
          ],
        ),
        content: Text(
          'Weekly analysis available with Premium — upgrade to unlock a '
          'fresh check-in every 7 days.',
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

  String get _caption {
    switch (_selectedPeriod) {
      case 'last7':
        return 'Your weekly check-in';
      case 'last60':
        return 'Two months in — your patterns are getting sharper.';
      case 'last90':
        return 'Three months of data — these patterns are well confirmed.';
      case 'last30':
      default:
        return "You have a month of data — here's a first look at your "
            'core patterns.';
    }
  }

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
        Widget body;
        if (!snapshot.hasData) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          final docs = snapshot.data!;
          final focus =
              docs.firstWhereOrNull((d) => d.metricKey == _focusMetricKey);
          final candidates = docs
              .where((d) =>
                  d.metricKey != _focusMetricKey &&
                  (widget.trackedMetricKeys.contains(d.metricKey) ||
                      d.metricKey == 'analgesia'))
              .toList();
          body = _selectedPeriod == 'last7'
              ? _weeklyView(context, focus)
              : _periodView(context, focus, candidates);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _periodSelector(context),
            const SizedBox(height: 8.0),
            Text(
              _caption,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const SizedBox(height: 20.0),
            body,
          ],
        );
      },
    );
  }

  Widget _periodSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pill(context, 'last7', '7 days', locked: !_isPremium),
        ),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last30', '30 days')),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last60', '60 days')),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last90', '90 days')),
      ],
    );
  }

  Widget _pill(BuildContext context, String period, String label,
      {bool locked = false}) {
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
            if (locked) ...[
              const Icon(Icons.workspace_premium,
                  size: 12.0, color: Color(0xFFFFC533)),
              const SizedBox(width: 4.0),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: selected
                    ? selectedColor
                    : (locked
                        ? const Color(0xFFFFC533)
                        : FlutterFlowTheme.of(context).primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 30/60/90-day view: reads the server-precomputed fields directly. ----

  Widget _periodView(
    BuildContext context,
    DashboardRecord? focus,
    List<DashboardRecord> candidates,
  ) {
    if (focus == null) {
      return _sectionCard(
        context,
        title: 'Your Pattern',
        icon: Icons.insights,
        child: _note(context, 'No data yet for this window.'),
      );
    }
    if (!focus.periodHasEnoughData) {
      final pct = (focus.completionRate * 100).round();
      return _sectionCard(
        context,
        title: 'Your Pattern',
        icon: Icons.insights,
        child: _note(
          context,
          "You've logged $pct% of days this period — a bit more "
          'consistency will unlock patterns.',
        ),
      );
    }
    if (!focus.analysisEligible) {
      return _sectionCard(
        context,
        title: 'Your Pattern',
        icon: Icons.insights,
        child: _note(
          context,
          'Your symptoms have been pretty stable this period — not enough '
          "ups and downs yet to detect a pattern. That's good news!",
        ),
      );
    }

    return Column(
      children: [
        _yourPatternSection(context, focus),
        const SizedBox(height: 16.0),
        _connectedSection(context, focus, candidates),
        const SizedBox(height: 16.0),
        _changingSection(context, focus),
        const SizedBox(height: 16.0),
        _worthWatchingSection(context, focus),
      ],
    );
  }

  Widget _yourPatternSection(BuildContext context, DashboardRecord focus) {
    final weekdayNote =
        _worstWeekdayNote(focus.dailyValues, focus.meanIntensitySymptomDays);
    return _sectionCard(
      context,
      title: 'Your Pattern',
      icon: Icons.insights,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statLine(context, 'Average intensity on symptom days',
              focus.meanIntensitySymptomDays.toStringAsFixed(1)),
          _statLine(context, 'Days with symptoms',
              '${(focus.symptomRate * 100).round()}%'),
          _statLine(
            context,
            'Mild / Moderate / Severe days',
            '${focus.mildSymptomDays} / ${focus.moderateSymptomDays} / '
                '${focus.severeSymptomDays}',
          ),
          if (focus.longestCrystalStreak > 0)
            _statLine(
              context,
              'Longest symptom-free streak',
              '${focus.longestCrystalStreak} day'
                  '${focus.longestCrystalStreak == 1 ? '' : 's'}',
            ),
          if (weekdayNote != null) ...[
            const SizedBox(height: 8.0),
            _note(context, weekdayNote),
          ],
        ],
      ),
    );
  }

  Widget _connectedSection(
    BuildContext context,
    DashboardRecord focus,
    List<DashboardRecord> candidates,
  ) {
    Widget content;
    if (candidates.isEmpty) {
      content = _note(
        context,
        "You're not tracking other variables yet — add some in Track "
        'Variables to see what connects to your headaches.',
      );
    } else {
      final connections = _computeConnections(focus, candidates);
      if (connections.isEmpty) {
        content = _note(
          context,
          'No strong connections yet — keep tracking to surface links '
          'between your variables and your headaches.',
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: connections.map((c) {
            final direction = c.r > 0 ? 'higher' : 'lower';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: _note(
                context,
                'Higher ${c.label} lines up with $direction headache '
                'intensity (r=${c.r.toStringAsFixed(2)}).',
              ),
            );
          }).toList(),
        );
      }
    }
    return _sectionCard(
      context,
      title: 'What Seems Connected',
      icon: Icons.hub,
      child: content,
    );
  }

  Widget _changingSection(BuildContext context, DashboardRecord focus) {
    final sorted = [...focus.dailyValues]..sort((a, b) => a.day.compareTo(b.day));
    final mid = sorted.length ~/ 2;
    final firstHalf = _summarize(sorted.sublist(0, mid));
    final secondHalf = _summarize(sorted.sublist(mid));

    Widget content;
    if (firstHalf.symptomDays.length < 3 || secondHalf.symptomDays.length < 3) {
      content = _note(
        context,
        'Not enough symptom days yet to compare the start and end of this '
        'period.',
      );
    } else {
      final delta = secondHalf.meanIntensitySymptomDays -
          firstHalf.meanIntensitySymptomDays;
      final from = firstHalf.meanIntensitySymptomDays.toStringAsFixed(1);
      final to = secondHalf.meanIntensitySymptomDays.toStringAsFixed(1);
      String trend;
      if (delta.abs() < 0.5) {
        trend = 'Stable — your average intensity has held steady around '
            '$to across this period.';
      } else if (delta < 0) {
        trend = 'Improving — average intensity dropped from $from to $to '
            'over the period.';
      } else {
        trend = 'Worsening — average intensity rose from $from to $to '
            'over the period.';
      }
      content = _note(context, trend);
    }
    return _sectionCard(
      context,
      title: "How You're Changing",
      icon: Icons.trending_up,
      child: content,
    );
  }

  Widget _worthWatchingSection(BuildContext context, DashboardRecord focus) {
    final lines = <String>[];
    final spikes = focus.dailyValues.where((d) => d.isSpike).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    if (spikes.isNotEmpty) {
      lines.add(
        '${spikes.length} notable spike${spikes.length == 1 ? '' : 's'} '
        'this period, most recently on ${spikes.last.date}.',
      );
    }
    if (focus.currentSevereStreak > 0) {
      lines.add(
        "You're on a ${focus.currentSevereStreak}-day streak of severe "
        'symptom days.',
      );
    }
    if (focus.periodDays > 0) {
      final painkillerRate = focus.painkillerDays / focus.periodDays;
      if (painkillerRate >= 10 / 30) {
        lines.add(
          'You used pain medication on ${focus.painkillerDays} of the '
          'last ${focus.periodDays} days — frequent use like this can '
          'itself trigger more headaches. Worth mentioning to your doctor.',
        );
      }
    }
    if (focus.currentMissingStreak >= 3) {
      lines.add(
        "You've missed logging for ${focus.currentMissingStreak} days — "
        'keep tracking consistently for accurate patterns.',
      );
    }
    if (lines.isEmpty) {
      lines.add('Nothing urgent right now — keep tracking to stay on top '
          'of changes.');
    }
    return _sectionCard(
      context,
      title: 'Worth Watching',
      icon: Icons.visibility,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _note(context, l),
                ))
            .toList(),
      ),
    );
  }

  // ---- 7-day view: derived client-side from the last30 doc's dailyValues. ----

  Widget _weeklyView(BuildContext context, DashboardRecord? focus30) {
    if (focus30 == null || focus30.dailyValues.isEmpty) {
      return _sectionCard(
        context,
        title: 'Your Pattern',
        icon: Icons.insights,
        child: _note(context, 'No data yet for this week.'),
      );
    }

    final sorted = [...focus30.dailyValues]..sort((a, b) => a.day.compareTo(b.day));
    final weekSlice =
        sorted.length <= 7 ? sorted : sorted.sublist(sorted.length - 7);
    final trackedCount = weekSlice.where((d) => d.isTracked).length;

    if (trackedCount < 5) {
      return _sectionCard(
        context,
        title: 'Your Pattern',
        icon: Icons.insights,
        child: _note(
          context,
          'Log a few more days this week to unlock your weekly check-in.',
        ),
      );
    }

    final summary = _summarize(weekSlice);
    final spikes = weekSlice.where((d) => d.isSpike).toList();
    final severeStreak = _trailingStreak(weekSlice, (d) => d.isSevere);

    final watchLines = <String>[];
    if (spikes.isNotEmpty) {
      watchLines.add(
        '${spikes.length} notable spike${spikes.length == 1 ? '' : 's'} '
        'this week, most recently on ${spikes.last.date}.',
      );
    }
    if (severeStreak > 0) {
      watchLines.add(
        "You're on a $severeStreak-day streak of severe symptom days.",
      );
    }
    if (watchLines.isEmpty) {
      watchLines.add('Nothing urgent this week.');
    }

    return Column(
      children: [
        _sectionCard(
          context,
          title: 'Your Pattern',
          icon: Icons.insights,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statLine(
                context,
                'Average intensity on symptom days',
                summary.symptomDays.isEmpty
                    ? '—'
                    : summary.meanIntensitySymptomDays.toStringAsFixed(1),
              ),
              _statLine(context, 'Symptom days this week',
                  '${summary.symptomDays.length} / 7'),
              _statLine(
                context,
                'Mild / Moderate / Severe',
                '${summary.mildDays} / ${summary.moderateDays} / '
                    '${summary.severeDays}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        _sectionCard(
          context,
          title: 'Worth Watching',
          icon: Icons.visibility,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: watchLines
                .map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _note(context, l),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8.0),
        _note(
          context,
          'Connections and trend comparisons need more history — switch '
          'to 30/60/90 days for those.',
        ),
      ],
    );
  }

  // ---- Shared math helpers ----

  double? _pearson(List<double> xs, List<double> ys) {
    final n = xs.length;
    if (n < 2) return null;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var cov = 0.0;
    var varX = 0.0;
    var varY = 0.0;
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

  List<_Connection> _computeConnections(
    DashboardRecord focus,
    List<DashboardRecord> candidates,
  ) {
    final focusByDate = <String, double>{
      for (final d in focus.dailyValues.where((d) => d.isTracked))
        d.date: d.value,
    };
    final results = <_Connection>[];
    for (final candidate in candidates) {
      final candidateByDate = <String, double>{
        for (final d in candidate.dailyValues.where((d) => d.isTracked))
          d.date: d.value,
      };
      final sharedDates =
          focusByDate.keys.toSet().intersection(candidateByDate.keys.toSet());
      if (sharedDates.length < 8) continue;
      final xs = <double>[];
      final ys = <double>[];
      for (final date in sharedDates) {
        xs.add(candidateByDate[date]!);
        ys.add(focusByDate[date]!);
      }
      final r = _pearson(xs, ys);
      if (r == null || r.abs() < 0.3) continue;
      results.add(_Connection(candidate.metricLabel, r));
    }
    results.sort((a, b) => b.r.abs().compareTo(a.r.abs()));
    return results.take(3).toList();
  }

  _Summary _summarize(List<DailyValueStruct> values) {
    final tracked = values.where((d) => d.isTracked).toList();
    final symptomDays = tracked.where((d) => d.value > 0).toList();
    final meanIntensity = symptomDays.isEmpty
        ? 0.0
        : symptomDays.map((d) => d.value).reduce((a, b) => a + b) /
            symptomDays.length;
    return _Summary(
      symptomDays: symptomDays,
      mildDays: tracked.where((d) => d.isMild).length,
      moderateDays: tracked.where((d) => d.isModerate).length,
      severeDays: tracked.where((d) => d.isSevere).length,
      meanIntensitySymptomDays: meanIntensity,
    );
  }

  int _trailingStreak(
    List<DailyValueStruct> sortedAscending,
    bool Function(DailyValueStruct) predicate,
  ) {
    var streak = 0;
    for (final d in sortedAscending.reversed) {
      if (d.isTracked && predicate(d)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
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

  String? _worstWeekdayNote(
    List<DailyValueStruct> dailyValues,
    double periodMeanIntensitySymptomDays,
  ) {
    final sums = <int, double>{};
    final counts = <int, int>{};
    for (final d in dailyValues) {
      if (!d.isTracked || d.value <= 0) continue;
      final weekday = DateTime.parse(d.date).weekday;
      sums[weekday] = (sums[weekday] ?? 0) + d.value;
      counts[weekday] = (counts[weekday] ?? 0) + 1;
    }
    if (sums.isEmpty) return null;

    int? worstDay;
    var worstAvg = -1.0;
    sums.forEach((weekday, total) {
      final avg = total / counts[weekday]!;
      if (avg > worstAvg) {
        worstAvg = avg;
        worstDay = weekday;
      }
    });
    if (worstDay == null ||
        worstAvg - periodMeanIntensitySymptomDays < 1.0) {
      return null;
    }
    return 'Your headaches tend to be worse on '
        '${_weekdayNames[worstDay! - 1]}s.';
  }

  // ---- Presentation helpers ----

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: FlutterFlowTheme.of(context).primary,
                  size: 18.0),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          child,
        ],
      ),
    );
  }

  Widget _statLine(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ),
          Text(
            value,
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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

class _Connection {
  _Connection(this.label, this.r);

  final String label;
  final double r;
}

class _Summary {
  _Summary({
    required this.symptomDays,
    required this.mildDays,
    required this.moderateDays,
    required this.severeDays,
    required this.meanIntensitySymptomDays,
  });

  final List<DailyValueStruct> symptomDays;
  final int mildDays;
  final int moderateDays;
  final int severeDays;
  final double meanIntensitySymptomDays;
}
