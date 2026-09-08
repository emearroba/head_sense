// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'intervention_analytics.dart';
import 'symptom_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// "Interventions" tab content for the Insights screen: every medication/diet
// the user has added in Settings > Interventions gets its own card here
// (rather than a chip-driven single comparison view), each showing whether
// the currently-selected symptom actually changed after they started it -
// before/after averages, a signal-strength badge, and, expanded, the trend
// line with a start-date marker plus the before/after intensity split. The
// start date itself is only editable in Settings, not here - this stays a
// read-only comparison view. Before/after math and the item list both come
// from intervention_analytics.dart so the Overview tab's "Since you started
// X" card can't drift out of sync with this one.
class InterventionsComparisonPanel extends StatefulWidget {
  const InterventionsComparisonPanel({
    super.key,
    required this.selectedFocusKey,
    required this.selectedPeriod,
    required this.totalDays,
  });

  final String selectedFocusKey;
  final String selectedPeriod;

  // Total days the user has ever logged a diary entry - used for the
  // "Build your baseline first" card, same 30-day convention already used by
  // PatternLockCard/TrackingProgressCard elsewhere in the app.
  final int totalDays;

  @override
  State<InterventionsComparisonPanel> createState() =>
      _InterventionsComparisonPanelState();
}

class _InterventionsComparisonPanelState
    extends State<InterventionsComparisonPanel> {
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = userSnapshot.data!;

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

                return StreamBuilder<List<DashboardRecord>>(
                  stream: queryDashboardRecord(
                    queryBuilder: (q) => q
                        .where('subjectId', isEqualTo: currentSubjectId)
                        .where('metricKey', isEqualTo: widget.selectedFocusKey)
                        .where('periodType', isEqualTo: widget.selectedPeriod),
                  ),
                  builder: (context, dashSnapshot) {
                    final record = dashSnapshot.data?.firstOrNull;
                    return _content(context, items, record);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    List<InterventionItem> items,
    DashboardRecord? record,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final showBaseline = widget.totalDays < 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your interventions',
          style: theme.headlineSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 20.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'See how your symptoms changed after starting something new.',
          style: theme.labelSmall.override(
            font: GoogleFonts.inter(),
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 16.0),
        if (items.isEmpty)
          _emptyState(
            context,
            "You haven't added any medications or diets yet. Add one below "
            'to see how it affects your symptoms.',
          )
        else
          for (final item in items) ...[
            _interventionCard(context, item, record),
            const SizedBox(height: 12.0),
          ],
        _addInterventionRow(context),
        if (showBaseline) ...[
          const SizedBox(height: 12.0),
          _baselineCard(context, widget.totalDays),
        ],
      ],
    );
  }

  Widget _addInterventionRow(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      // Route name string (not a class import) to keep custom_code decoupled
      // from FlutterFlow's page layer - matches
      // InterventionsWidget.routeName in lib/pages/interventions.
      onTap: () => context.pushNamed('Interventions'),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: theme.primary, size: 18.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a new intervention',
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      color: theme.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Track a medication, diet, habit or other change to see '
                    'how it affects your symptoms.',
                    style: theme.labelSmall.override(
                      font: GoogleFonts.inter(),
                      color: theme.secondaryText,
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18.0, color: theme.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _baselineCard(BuildContext context, int totalDays) {
    final theme = FlutterFlowTheme.of(context);
    final clamped = totalDays.clamp(0, 30);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.track_changes_rounded,
                  color: theme.secondaryText, size: 18.0),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build your baseline first',
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      'We recommend tracking for at least 30 days before '
                      'starting a new intervention. This gives you a '
                      'clearer baseline to compare against.',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                        lineHeight: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _emptyState(BuildContext context, String message) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Text(
        message,
        style: theme.labelSmall.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
        ),
      ),
    );
  }

  Widget _cardShell(BuildContext context, {required Widget child}) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: child,
    );
  }

  Widget _cardHeader(
    BuildContext context, {
    required InterventionItem item,
    Widget? badge,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            item.kind == InterventionKind.medication
                ? Icons.medication_outlined
                : Icons.restaurant_outlined,
            color: theme.primary,
            size: 18.0,
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: theme.bodyMedium.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (item.startedAt != null)
                Text(
                  'Started ${dateTimeFormat('MMM d, y', item.startedAt!)}',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                    fontSize: 11.0,
                  ),
                ),
            ],
          ),
        ),
        if (badge != null) badge,
      ],
    );
  }

  Widget _signalBadge(BuildContext context, InterventionSignal signal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        signal.label,
        style: TextStyle(
          color: signal.color,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
        ),
      ),
    );
  }

  Widget _interventionCard(
    BuildContext context,
    InterventionItem item,
    DashboardRecord? record,
  ) {
    final theme = FlutterFlowTheme.of(context);

    if (item.startedAt == null) {
      return _cardShell(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, item: item),
            const SizedBox(height: 10.0),
            Text(
              'Set a start date for ${item.label} in Settings > '
              'Interventions to compare before/after.',
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                lineHeight: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    if (record == null) {
      return _cardShell(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, item: item),
            const SizedBox(height: 10.0),
            Text(
              'No data yet for this window.',
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    final comparison = buildInterventionComparison(record, item.startedAt!);
    if (comparison == null) {
      return _cardShell(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(context, item: item),
            const SizedBox(height: 10.0),
            Text(
              'Not enough tracked days on one side of '
              '${dateTimeFormat('MMM d, y', item.startedAt!)} yet in this '
              'window — try a longer period (60 or 90 days), or check back '
              'once you have more days logged.',
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                lineHeight: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final signal = interventionSignalTier(comparison);
    final expanded = _expandedIds.contains(item.id);
    final startKey = isoDateKey(item.startedAt!);
    final tracked = record.dailyValues.where((d) => d.isTracked).toList();
    final before = tracked.where((d) => d.date.compareTo(startKey) < 0);
    final after = tracked.where((d) => d.date.compareTo(startKey) >= 0);
    final deltaPct = comparison.deltaPct;

    return _cardShell(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            context,
            item: item,
            badge: _signalBadge(context, signal),
          ),
          const SizedBox(height: 14.0),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _statTile(
                    context,
                    label: 'Before',
                    sublabel: '${comparison.beforeDays} days',
                    value: comparison.beforeAvg.toStringAsFixed(1),
                    color: theme.secondaryText,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _statTile(
                    context,
                    label: 'After',
                    sublabel: '${comparison.afterDays} days',
                    value: comparison.afterAvg.toStringAsFixed(1),
                    color: theme.primaryText,
                    accent: comparison.betterAfter
                        ? const Color(0xFF4CAF6D)
                        : const Color(0xFFE5484D),
                  ),
                ),
              ],
            ),
          ),
          if (deltaPct != null) ...[
            const SizedBox(height: 10.0),
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
                  'intensity',
                  style: TextStyle(
                    color: comparison.betterAfter
                        ? const Color(0xFF4CAF6D)
                        : const Color(0xFFE5484D),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${comparison.daysSinceStart} days tracked',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ],
          if (signal.isEarly) ...[
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14.0, color: theme.secondaryText),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'This is an early signal. Keep tracking to see if '
                      'this pattern continues.',
                      style: theme.labelSmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                        fontSize: 11.0,
                        lineHeight: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10.0),
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expandedIds.remove(item.id);
              } else {
                _expandedIds.add(item.id);
              }
            }),
            child: Row(
              children: [
                Text(
                  expanded ? 'Hide details' : 'See details',
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18.0,
                  color: theme.primary,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10.0),
            _sectionLabel(context, '${record.metricLabel} trend'),
            const SizedBox(height: 8.0),
            SymptomTrendChart(
              values: record.dailyValues,
              markerDate: startKey,
              markerLabel: 'Started',
            ),
            const SizedBox(height: 18.0),
            _sectionLabel(context, 'Intensity distribution'),
            const SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Before',
                          style: TextStyle(
                              fontSize: 11.0, color: theme.secondaryText)),
                      const SizedBox(height: 4.0),
                      IntensityDistributionChart(
                        histogram: intensityHistogram(before),
                        height: 100.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('After',
                          style: TextStyle(
                              fontSize: 11.0, color: theme.secondaryText)),
                      const SizedBox(height: 4.0),
                      IntensityDistributionChart(
                        histogram: intensityHistogram(after),
                        height: 100.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      text,
      style: theme.labelMedium.override(
        font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _statTile(
    BuildContext context, {
    required String label,
    required String sublabel,
    required String value,
    required Color color,
    Color? accent,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: (accent ?? theme.alternate).withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 21.0,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(
            '$label · $sublabel',
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
