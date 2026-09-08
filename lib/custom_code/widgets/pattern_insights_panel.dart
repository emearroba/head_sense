// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'headline_metric_tiles.dart';
import 'intensity_distribution_chart.dart';
import 'intervention_analytics.dart';
import 'symptom_analytics.dart';
import 'symptom_trend_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
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
// Layout, top to bottom, is deliberately "results first": a bold "Your X
// patterns" heading anchors four headline metric tiles, a trend chart, an
// intensity distribution, and finally the narrative "What we noticed"
// insight cards - in that order of visual weight. The Looking-at picker and
// period pills are owned by ResultsWidget (shown above the My symptoms /
// Connections tabs, not in here) - see selectedFocusKey/selectedPeriod.
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
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.selectedFocusKey,
    required this.totalDays,
    this.onOpenConnection,
    this.onOpenConnectionsTab,
    this.onOpenInterventionsTab,
  });

  final List<String> trackedMetricKeys;
  // Period and focus metric are owned by ResultsWidget (shown in the
  // selectors above the My symptoms / Connections tabs) rather than kept as
  // local state here, so the page chrome and this panel can never disagree
  // about which window/metric is selected.
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final String selectedFocusKey;

  // Total days the user has ever logged a diary entry - used for the
  // "Building your baseline" fallback under "Since you started X", same
  // 30-day convention already used by PatternLockCard/TrackingProgressCard.
  final int totalDays;

  // Jumps to the Connections tab with [otherKey] preselected against the
  // current focus symptom - wired up from "Your strongest connections" rows.
  final ValueChanged<String>? onOpenConnection;
  // Jumps to the Connections tab without preselecting a pair - wired up from
  // the "Explore your data" section's correlation-matrix link.
  final VoidCallback? onOpenConnectionsTab;
  // Jumps to the Interventions tab - wired up from the "Since you started X"
  // card's "Explore intervention" link.
  final VoidCallback? onOpenInterventionsTab;

  @override
  State<PatternInsightsPanel> createState() => _PatternInsightsPanelState();
}

class _PatternInsightsPanelState extends State<PatternInsightsPanel> {

  String _shortLabel(String metricLabel) => metricLabel
      .toLowerCase()
      .replaceAll(RegExp(r'\s+intensity$', caseSensitive: false), '');

  @override
  Widget build(BuildContext context) {
    // The 7-day pill has no server-computed period of its own — it's
    // derived from the last30 doc, so the query below always fetches
    // last30 while last7 is selected.
    final queryPeriod =
        widget.selectedPeriod == 'last7' ? 'last30' : widget.selectedPeriod;

    return StreamBuilder<List<DashboardRecord>>(
      stream: queryDashboardRecord(
        queryBuilder: (q) => q
            .where('subjectId', isEqualTo: currentSubjectId)
            .where('periodType', isEqualTo: queryPeriod),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!;
        final focus = docs
            .firstWhereOrNull((d) => d.metricKey == widget.selectedFocusKey);
        return widget.selectedPeriod == 'last7'
            ? _weeklyView(context, focus, docs)
            : _periodView(context, focus, docs);
      },
    );
  }

  Widget _resultsHeading(BuildContext context, String metricLabel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Your ${_shortLabel(metricLabel)} patterns',
            overflow: TextOverflow.ellipsis,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 20.0,
                ),
          ),
        ),
        const SizedBox(width: 6.0),
        InkWell(
          onTap: () => _showResultsInfo(context, metricLabel),
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              Icons.info_outline,
              size: 16.0,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  void _showResultsInfo(BuildContext context, String metricLabel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text(
          'About these results',
          style: FlutterFlowTheme.of(context).titleSmall.override(
                fontWeight: FontWeight.w700,
                color: FlutterFlowTheme.of(context).primaryText,
              ),
        ),
        content: Text(
          'Average intensity, spikes, crystal clear days, and most common '
          'intensity are computed from your logged ${metricLabel.toLowerCase()} '
          'entries in the selected window. Delta indicators compare the '
          'second half of the window to the first half.',
          style: FlutterFlowTheme.of(context).bodySmall.override(
                color: FlutterFlowTheme.of(context).secondaryText,
                lineHeight: 1.4,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Got it',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 30/60/90-day view ----

  Widget _periodView(
    BuildContext context,
    DashboardRecord? focus,
    List<DashboardRecord> docs,
  ) {
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

    final sortedTracked = [...focus.dailyValues]
      ..sort((a, b) => a.day.compareTo(b.day));
    final trackedOnly =
        sortedTracked.where((d) => d.isTracked).toList(growable: false);
    final histogram = intensityHistogram(trackedOnly);
    final mode = modeIntensityValue(histogram);
    final intensityDelta = _intensityDelta(trackedOnly);
    final spikeDelta = _spikeDelta(trackedOnly);
    final hasEnoughData = focus.periodHasEnoughData;
    final eligible = focus.analysisEligible;

    final discoveries = (hasEnoughData && eligible)
        ? (_buildDiscoveries(focus)..sort((a, b) => b.score.compareTo(a.score)))
        : const <_Discovery>[];

    // Lead with the narrative ("Somatica noticed X"), not the stats - see
    // module comment. Order: what we noticed -> since you started X ->
    // strongest connections -> demoted stat row/trend -> explore your data
    // (the raw charts, for whoever wants the "proof" layer underneath).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultsHeading(context, focus.metricLabel),
        const SizedBox(height: 18.0),
        _noticedSection(context, hasEnoughData, eligible, focus, discoveries),
        _interventionHighlight(context, focus),
        _strongestConnectionsSection(context, focus, docs),
        _thisMonthSection(
            context, focus, mode, intensityDelta, spikeDelta),
        _exploreYourData(context, focus, histogram),
      ],
    );
  }

  // "What Somatica noticed" - the discovery hero+grid, now the very first
  // thing under the page heading instead of the last. Content unchanged
  // from before, just relocated.
  Widget _noticedSection(
    BuildContext context,
    bool hasEnoughData,
    bool eligible,
    DashboardRecord focus,
    List<_Discovery> discoveries,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderRow(
            context,
            'What Somatica noticed',
            onViewAll: discoveries.length > 3
                ? () => _showAllDiscoveries(context, discoveries)
                : null,
          ),
          const SizedBox(height: 10.0),
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
          else
            _noticedGrid(context, discoveries.take(3).toList()),
        ],
      ),
    );
  }

  // "Since you started X" - the most-recently-started intervention with
  // enough before/after data to compare, or a "building your baseline" nudge
  // if the user has interventions but not enough tracked days yet. Renders
  // nothing at all when the user hasn't added any intervention - no nagging
  // to add one they haven't shown interest in. Self-fetches user/medication/
  // diet data (mirrors InterventionsComparisonPanel) rather than having
  // ResultsWidget prop-drill it down, matching how this panel and
  // ConnectionsPanel already each own their own Firestore listeners.
  Widget _interventionHighlight(BuildContext context, DashboardRecord focus) {
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null ||
            (user.medicationDoses.isEmpty && user.dietTypeKeys.isEmpty)) {
          return const SizedBox.shrink();
        }
        return StreamBuilder<List<MedicationsRecord>>(
          stream: queryMedicationsRecord(),
          builder: (context, medsSnapshot) {
            return StreamBuilder<List<DietTypesRecord>>(
              stream: queryDietTypesRecord(),
              builder: (context, dietsSnapshot) {
                final medsById = {
                  for (final m in medsSnapshot.data ?? <MedicationsRecord>[])
                    m.reference.id: m,
                };
                final dietsById = {
                  for (final d in dietsSnapshot.data ?? <DietTypesRecord>[])
                    d.reference.id: d,
                };
                final items = buildInterventionItems(
                  user: user,
                  medsById: medsById,
                  dietsById: dietsById,
                );
                if (items.isEmpty) return const SizedBox.shrink();

                // Most-recently-started item with enough before/after data
                // wins - freshest change is the most "newsworthy" one.
                final withStart = items.where((i) => i.startedAt != null)
                    .toList()
                  ..sort((a, b) => b.startedAt!.compareTo(a.startedAt!));
                InterventionItem? bestItem;
                InterventionComparison? bestComparison;
                for (final item in withStart) {
                  final comparison =
                      buildInterventionComparison(focus, item.startedAt!);
                  if (comparison != null) {
                    bestItem = item;
                    bestComparison = comparison;
                    break;
                  }
                }

                if (bestItem == null || bestComparison == null) {
                  if (widget.totalDays >= 30) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _baselineBuildingCard(context),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _interventionCard(
                      context, focus, bestItem, bestComparison),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _baselineBuildingCard(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final clamped = widget.totalDays.clamp(0, 30);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You're building your baseline",
            style: theme.bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w700),
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            "You've tracked $clamped of 30 recommended days. A bit more "
            'history will give you a clearer before-and-after comparison '
            'for what you started.',
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              lineHeight: 1.4,
            ),
          ),
          const SizedBox(height: 12.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: LinearProgressIndicator(
              value: clamped / 30.0,
              minHeight: 6.0,
              backgroundColor: theme.alternate,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '$clamped / 30 days',
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: theme.secondaryText,
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _interventionCard(
    BuildContext context,
    DashboardRecord focus,
    InterventionItem item,
    InterventionComparison comparison,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final signal = interventionSignalTier(comparison);
    final deltaPct = comparison.deltaPct;
    return InkWell(
      onTap: widget.onOpenInterventionsTab,
      borderRadius: BorderRadius.circular(18.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: signal.color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Since you started ${item.label}',
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: theme.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: signal.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    signal.label,
                    style: TextStyle(
                        color: signal.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Started ${dateTimeFormat('MMM d, y', item.startedAt!)} · '
              '${comparison.daysSinceStart} days tracked since',
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                fontSize: 11.0,
              ),
            ),
            const SizedBox(height: 14.0),
            Row(
              children: [
                Text(comparison.beforeAvg.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.w800,
                        color: theme.secondaryText)),
                const SizedBox(width: 4.0),
                Text('before',
                    style: TextStyle(
                        fontSize: 12.0, color: theme.secondaryText)),
                const SizedBox(width: 10.0),
                Icon(Icons.arrow_forward_rounded,
                    size: 18.0, color: theme.secondaryText),
                const SizedBox(width: 10.0),
                Text(comparison.afterAvg.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 26.0,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText)),
                const SizedBox(width: 4.0),
                Text('after',
                    style: TextStyle(
                        fontSize: 12.0, color: theme.secondaryText)),
              ],
            ),
            if (deltaPct != null) ...[
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    comparison.betterAfter
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 15.0,
                    color: comparison.betterAfter
                        ? const Color(0xFF4CAF6D)
                        : const Color(0xFFE5484D),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${(deltaPct.abs() * 100).round()}% '
                    '${comparison.betterAfter ? 'lower' : 'higher'} average '
                    '${_shortLabel(focus.metricLabel)} intensity',
                    style: TextStyle(
                      color: comparison.betterAfter
                          ? const Color(0xFF4CAF6D)
                          : const Color(0xFFE5484D),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
            if (signal.isEarly) ...[
              const SizedBox(height: 10.0),
              Text(
                'Early signal — keep tracking to see whether this pattern '
                'continues.',
                style: theme.labelSmall.override(
                  font: GoogleFonts.inter(fontStyle: FontStyle.italic),
                  color: theme.secondaryText,
                  fontSize: 11.0,
                ),
              ),
            ],
            if (widget.onOpenInterventionsTab != null) ...[
              const SizedBox(height: 10.0),
              Row(
                children: [
                  Text(
                    'Explore intervention',
                    style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14.0, color: theme.primary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // "Your strongest connections" - the auto-ranked list against every other
  // tracked metric (rankedConnections, symptom_analytics.dart), computed
  // from the same `docs` this panel already fetches - no extra Firestore
  // listener. Top 3 shown; tapping one jumps to the Connections tab with
  // that pair preselected.
  Widget _strongestConnectionsSection(
    BuildContext context,
    DashboardRecord focus,
    List<DashboardRecord> docs,
  ) {
    if (docs.length < 2) return const SizedBox.shrink();
    final ranked = rankedConnections(focus, docs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeaderRow(
            context,
            'Your strongest connections',
            onViewAll:
                widget.onOpenConnectionsTab == null || ranked.length <= 3
                    ? null
                    : widget.onOpenConnectionsTab,
          ),
          const SizedBox(height: 10.0),
          if (ranked.isEmpty)
            _emptyCard(
              context,
              'Nothing stands out strongly enough yet — keep tracking your '
              'other variables to see what connects.',
            )
          else
            for (var i = 0; i < min(3, ranked.length); i++)
              Padding(
                padding: EdgeInsets.only(
                    bottom: i == min(3, ranked.length) - 1 ? 0.0 : 8.0),
                child: _connectionMiniRow(
                    context, ranked[i].$1, ranked[i].$2),
              ),
        ],
      ),
    );
  }

  Widget _connectionMiniRow(
    BuildContext context,
    DashboardRecord other,
    SymptomConnection connection,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final tier = connectionStrengthTier(connection.strengthPct);
    return InkWell(
      onTap: widget.onOpenConnection == null
          ? null
          : () => widget.onOpenConnection!(other.metricKey),
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7.0),
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(connection.icon, size: 15.0, color: tier.color),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    other.metricLabel,
                    style: theme.bodySmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: theme.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    connection.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.labelSmall.override(
                      font: GoogleFonts.inter(),
                      color: theme.secondaryText,
                      fontSize: 11.0,
                      lineHeight: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '${tier.label} signal',
                style: TextStyle(
                    color: tier.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Demoted "this month" summary - was the top-of-page 4-tile row; now a
  // lighter 3-stat row (drops "most common intensity", the least
  // narratively useful of the four) plus the trend chart, both below the
  // narrative sections above.
  Widget _thisMonthSection(
    BuildContext context,
    DashboardRecord focus,
    int? mode,
    double? intensityDelta,
    int spikeDelta,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ${_shortLabel(focus.metricLabel)} this ${_periodNoun()}',
            style: theme.labelMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10.0),
          HeadlineMetricTiles(metrics: [
            HeadlineMetric(
              label: 'Average intensity',
              value: focus.symptomDays > 0
                  ? focus.meanIntensitySymptomDays.toStringAsFixed(1)
                  : '—',
              color: theme.primary,
              footer: intensityDelta == null
                  ? null
                  : HeadlineDelta(
                      isDown: intensityDelta < 0,
                      magnitudeLabel:
                          '${(intensityDelta.abs() * 100).round()}%',
                      goodWhenDown: true,
                    ),
            ),
            HeadlineMetric(
              label: 'Spikes',
              value: '${focus.spikeCount}',
              color: const Color(0xFFFFC533),
              footer: spikeDelta == 0
                  ? null
                  : HeadlineDelta(
                      isDown: spikeDelta < 0,
                      magnitudeLabel: '${spikeDelta.abs()}',
                      goodWhenDown: true,
                    ),
            ),
            HeadlineMetric(
              label: 'Crystal clear days',
              value: '${focus.symptomFreeDays}',
              color: kCrystalBlue,
              footer: focus.symptomFreeDays > 0
                  ? const Icon(Icons.auto_awesome,
                      size: 14.0, color: kCrystalBlue)
                  : null,
            ),
          ]),
          const SizedBox(height: 12.0),
          SymptomTrendChart(values: focus.dailyValues, height: 140.0),
        ],
      ),
    );
  }

  String _periodNoun() {
    switch (widget.selectedPeriod) {
      case 'last60':
        return '60 days';
      case 'last90':
        return '90 days';
      default:
        return 'month';
    }
  }

  // "Proof, not product" layer - the intensity distribution chart (was
  // always shown inline before) plus a link into the Connections tab's full
  // correlation matrix, both tucked behind a single collapsed expansion so
  // the data-nerd view is a tap away rather than competing with the
  // narrative sections above for first-screen space.
  Widget _exploreYourData(
    BuildContext context,
    DashboardRecord focus,
    Map<int, int> histogram,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: theme.secondaryText,
        collapsedIconColor: theme.secondaryText,
        title: Text(
          'Explore your data',
          style: theme.labelMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          _cardWrap(
            context,
            IntensityDistributionChart(histogram: histogram),
            title: 'Intensity Distribution',
          ),
          if (widget.onOpenConnectionsTab != null) ...[
            const SizedBox(height: 12.0),
            OutlinedButton.icon(
              onPressed: widget.onOpenConnectionsTab,
              icon: Icon(Icons.grid_on_rounded, size: 16.0, color: theme.primary),
              label: const Text('Advanced correlations'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- "vs earlier this period" deltas ----
  //
  // There's no server-computed "previous period" doc (every periodType is a
  // trailing window from today, not a shifted one) so these compare the
  // second half of the current window to the first half - an honest signal
  // of "is this improving within the window I'm looking at", not a literal
  // previous-window comparison. null/0 suppresses the footer entirely
  // rather than showing a misleading number from too little data.
  double? _intensityDelta(List<DailyValueStruct> trackedSorted) {
    if (trackedSorted.length < 8) return null;
    final mid = trackedSorted.length ~/ 2;
    final earlier = trackedSorted
        .sublist(0, mid)
        .where((d) => d.value > 0)
        .map((d) => d.value)
        .toList();
    final recent = trackedSorted
        .sublist(mid)
        .where((d) => d.value > 0)
        .map((d) => d.value)
        .toList();
    if (earlier.isEmpty || recent.isEmpty) return null;
    final earlierAvg = earlier.reduce((a, b) => a + b) / earlier.length;
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    if (earlierAvg == 0) return null;
    return (recentAvg - earlierAvg) / earlierAvg;
  }

  int _spikeDelta(List<DailyValueStruct> trackedSorted) {
    if (trackedSorted.length < 8) return 0;
    final mid = trackedSorted.length ~/ 2;
    final earlier = trackedSorted.sublist(0, mid).where((d) => d.isSpike).length;
    final recent = trackedSorted.sublist(mid).where((d) => d.isSpike).length;
    return recent - earlier;
  }

  Widget _cardWrap(BuildContext context, Widget child,
      {String? title, String? subtitle}) {
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
      child: title == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: 4.0, bottom: subtitle == null ? 10.0 : 2.0),
                  child: _sectionHeader(context, title),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
                    child: Text(
                      subtitle,
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.inter(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ),
                child,
              ],
            ),
    );
  }

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayNamesShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // "This week" mini bar-chart: the trailing 7 tracked days, with the
  // highest and lowest days ringed and called out below. Only shown on the
  // 7-day pill (_weeklyView) - a per-day breakdown doesn't add much next to
  // the 30/60/90-day trend/distribution cards, which already summarize the
  // whole window.
  Widget _weekCalendar(BuildContext context, DashboardRecord focus) {
    final sorted = [...focus.dailyValues]..sort((a, b) => a.day.compareTo(b.day));
    final weekSlice =
        sorted.length <= 7 ? sorted : sorted.sublist(sorted.length - 7);
    final trackedInWeek =
        weekSlice.where((d) => d.isTracked && !d.isMissing).toList();
    if (trackedInWeek.length < 2) return const SizedBox.shrink();

    final higher = trackedInWeek.reduce((a, b) => a.value >= b.value ? a : b);
    final lower = trackedInWeek.reduce((a, b) => a.value <= b.value ? a : b);
    const higherColor = Color(0xFFFFC533);
    const lowerColor = kCrystalBlue;

    return _cardWrap(
      context,
      title: 'This week',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                for (final d in weekSlice)
                  Expanded(
                    child: _weekDayCell(
                      context,
                      d,
                      isHigher: d.isTracked && d.date == higher.date,
                      isLower: d.isTracked &&
                          d.date == lower.date &&
                          lower.date != higher.date,
                      higherColor: higherColor,
                      lowerColor: lowerColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _weekLegendChip(
                  context,
                  color: higherColor,
                  icon: Icons.arrow_upward_rounded,
                  label: 'Higher day',
                  day: higher,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _weekLegendChip(
                  context,
                  color: lowerColor,
                  icon: Icons.arrow_downward_rounded,
                  label: 'Lower day',
                  day: lower,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weekDayCell(
    BuildContext context,
    DailyValueStruct d, {
    required bool isHigher,
    required bool isLower,
    required Color higherColor,
    required Color lowerColor,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final weekday = DateTime.parse(d.date).weekday; // 1 = Monday
    final tracked = d.isTracked && !d.isMissing;
    final barColor =
        tracked ? intensityColorForValue(d.value) : theme.alternate;
    final ringColor = isHigher ? higherColor : (isLower ? lowerColor : null);
    final barHeight = tracked ? (d.value.clamp(0.0, 10.0) / 10.0) * 36.0 + 4.0 : 4.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _weekdayLetters[weekday - 1],
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: ringColor != null ? FontWeight.w800 : FontWeight.w500,
            color: ringColor ?? theme.secondaryText,
          ),
        ),
        const SizedBox(height: 6.0),
        SizedBox(
          height: 44.0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 20.0,
              height: barHeight,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6.0),
                border: ringColor == null
                    ? null
                    : Border.all(color: ringColor, width: 2.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          tracked ? d.value.round().toString() : '–',
          style: TextStyle(fontSize: 9.0, color: theme.secondaryText),
        ),
      ],
    );
  }

  Widget _weekLegendChip(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required DailyValueStruct day,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final weekday = DateTime.parse(day.date).weekday;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12.0, color: color),
          const SizedBox(width: 6.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  '${_weekdayNamesShort[weekday - 1]} · ${day.value.round()}/10',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _sectionHeaderRow(BuildContext context, String text,
      {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Expanded(child: _sectionHeader(context, text)),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View all',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).primary,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
              ),
            ),
          ),
      ],
    );
  }

  // Top 3 discoveries as compact mini-cards (icon + short title + one-line
  // detail) instead of the full hero+list treatment - "What we noticed"
  // reads as a quick scan, with "View all" (see _showAllDiscoveries) for
  // the rest instead of pushing every discovery into the main scroll.
  Widget _noticedGrid(BuildContext context, List<_Discovery> top) {
    // Every card reserves fixed-height slots for its title (2 lines) and
    // detail (1 line) - see _miniDiscoveryCard - so all cards come out the
    // same height on their own. That means a plain Row works here; no need
    // for IntrinsicHeight + stretch (which previously sized the row from a
    // dry-layout pass that could be a hair short of the real layout, an
    // easy way to get a 1px "bottom overflowed" warning on some cards).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < top.length; i++) ...[
          if (i > 0) const SizedBox(width: 8.0),
          Expanded(child: _miniDiscoveryCard(context, top[i])),
        ],
      ],
    );
  }

  Widget _miniDiscoveryCard(BuildContext context, _Discovery d) {
    final theme = FlutterFlowTheme.of(context);
    final color = d.color ?? theme.primary;
    return InkWell(
      onTap: d.why == null ? null : () => _showWhy(context, d),
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(d.icon, color: color, size: 14.0),
            ),
            const SizedBox(height: 8.0),
            // Fixed-height slots (2 lines for the title, 1 for the detail)
            // regardless of how much of that the text actually uses, so
            // every mini-card comes out the same height without relying on
            // an IntrinsicHeight-stretched row to force it.
            SizedBox(
              height: 32.0,
              child: Text(
                d.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.0,
                ),
              ),
            ),
            const SizedBox(height: 3.0),
            SizedBox(
              height: 14.0,
              child: Text(
                d.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall.override(
                  font: GoogleFonts.inter(),
                  color: theme.secondaryText,
                  fontSize: 10.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllDiscoveries(BuildContext context, List<_Discovery> discoveries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'What we noticed',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontWeight: FontWeight.w700,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              const SizedBox(height: 14.0),
              _heroCard(context, discoveries.first),
              ...discoveries.skip(1).map((d) => Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: _discoveryCard(context, d),
                  )),
            ],
          ),
        ),
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

  Widget _weeklyView(
    BuildContext context,
    DashboardRecord? focus30,
    List<DashboardRecord> docs,
  ) {
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
    final severeStreak = _trailingSevereStreak(weekSlice);

    // Same lead-with-narrative order as the 30/60/90-day view, at a smaller
    // scale: noticed cards first, then intervention/connections highlights,
    // then the demoted stat row + week calendar + trend, and finally the
    // intensity distribution tucked behind "Explore your data".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultsHeading(context, focus30.metricLabel),
        const SizedBox(height: 18.0),
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'What Somatica noticed'),
              const SizedBox(height: 10.0),
              if (trackedCount < 5)
                _emptyCard(
                  context,
                  'Log a few more days this week to unlock your insight '
                  'cards.',
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
                        title:
                            "You're on a $severeStreak-day streak of severe days",
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
                      title:
                          '$spikes notable spike${spikes == 1 ? '' : 's'} this week',
                      detail: 'Worth a closer look in your diary.',
                      score: 0,
                    ),
                  ),
                if (spikes == 0 && severeStreak == 0)
                  _emptyCard(context, 'Nothing urgent this week.'),
                const SizedBox(height: 8.0),
                _note(
                  context,
                  'Weekday and trend insight cards need more history — '
                  'switch to 30 days or more for those.',
                ),
              ],
            ],
          ),
        ),
        _interventionHighlight(context, focus30),
        _strongestConnectionsSection(context, focus30, docs),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your ${_shortLabel(focus30.metricLabel)} this week',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10.0),
              HeadlineMetricTiles(metrics: [
                HeadlineMetric(
                  label: 'Average intensity',
                  value: meanIntensity == null
                      ? '—'
                      : meanIntensity.toStringAsFixed(1),
                  color: FlutterFlowTheme.of(context).primary,
                ),
                HeadlineMetric(
                  label: 'Spikes',
                  value: '$spikes',
                  color: const Color(0xFFFFC533),
                ),
                HeadlineMetric(
                  label: 'Crystal clear days',
                  value: '$crystalDays',
                  color: kCrystalBlue,
                  footer: crystalDays > 0
                      ? const Icon(Icons.auto_awesome,
                          size: 14.0, color: kCrystalBlue)
                      : null,
                ),
              ]),
              const SizedBox(height: 12.0),
              _weekCalendar(context, focus30),
              const SizedBox(height: 12.0),
              SymptomTrendChart(values: weekSlice, height: 130.0),
            ],
          ),
        ),
        _exploreYourData(context, focus30, histogram),
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
