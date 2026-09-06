// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'connection_detail_sheet.dart';
import 'dual_trend_chart.dart';
import 'episode_analytics.dart';
import 'symptom_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// "Connections" tab content for the Results screen: a "Looking at:" picker
// (any tracked symptom - not fixed to headache) sets which symptom is the
// anchor, then the user adds other tracked symptoms to compare against it
// and sees how each relates - connection strength, day overlap, a compact
// compare-trend visual, and the plain-language "detected connection"
// finding. Reuses the correlation math from symptom_analytics.dart (also
// used, for the single-focus case, by pattern_insights_panel.dart's "What
// we noticed" cards on My symptoms).
class ConnectionsPanel extends StatefulWidget {
  const ConnectionsPanel({
    super.key,
    required this.trackedMetricKeys,
    required this.selectedFocusKey,
    required this.selectedPeriod,
    this.initialCompareKey,
  });

  final List<String> trackedMetricKeys;

  // The symptom everything else is compared against - shared with the My
  // symptoms tab's "Looking at" picker so the same bubble/position is used
  // regardless of which tab is active.
  final String selectedFocusKey;

  // Shared with the My symptoms tab's period pill so the same control is
  // used (and stays visible) regardless of which tab is active.
  final String selectedPeriod;

  // Set when the user tapped a "strongest connections" row on the Overview
  // tab - preloads that pair into the manual "Advanced" comparison and opens
  // it expanded, so the tap-through lands on the specific pair they picked
  // rather than just the top of this tab.
  final String? initialCompareKey;

  @override
  State<ConnectionsPanel> createState() => _ConnectionsPanelState();
}

class _ConnectionsPanelState extends State<ConnectionsPanel> {
  String get _anchorKey => widget.selectedFocusKey;
  late final List<String> _compareKeys =
      widget.initialCompareKey == null ? [] : [widget.initialCompareKey!];
  bool _initializedDefaults = false;
  late bool _advancedExpanded = widget.initialCompareKey != null;
  // null = "All". Filters the auto-ranked list by each connection's
  // strongest-lag direction (see ConnectionTiming in symptom_analytics.dart).
  ConnectionTiming? _timingFilter;

  @override
  void didUpdateWidget(ConnectionsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFocusKey != oldWidget.selectedFocusKey) {
      _compareKeys.remove(widget.selectedFocusKey);
    }
    if (widget.initialCompareKey != null &&
        widget.initialCompareKey != oldWidget.initialCompareKey) {
      if (!_compareKeys.contains(widget.initialCompareKey)) {
        _compareKeys.add(widget.initialCompareKey!);
      }
      _advancedExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DashboardRecord>>(
      stream: queryDashboardRecord(
        queryBuilder: (q) => q
            .where('userRef', isEqualTo: currentUserReference)
            .where('periodType', isEqualTo: widget.selectedPeriod),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!;
        final options = docs
            .where((d) =>
                d.metricKey == 'headache_intensity' ||
                d.metricKey == 'analgesia' ||
                widget.trackedMetricKeys.contains(d.metricKey))
            .toList()
          ..sort((a, b) => a.metricLabel.compareTo(b.metricLabel));

        // Seed a sensible symptom to compare against the first time real
        // options come in, so the tab opens already showing a relationship
        // instead of an empty prompt.
        if (!_initializedDefaults && options.isNotEmpty) {
          _initializedDefaults = true;
          final fallback = options.firstWhereOrNull(
              (d) => d.metricKey != _anchorKey && d.metricKey != 'analgesia');
          if (fallback != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _compareKeys.isEmpty) {
                setState(() => _compareKeys.add(fallback.metricKey));
              }
            });
          }
        }

        final byKey = {for (final d in options) d.metricKey: d};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _autoRankedSection(context, byKey),
            const SizedBox(height: 26.0),
            _advancedSection(context, options, byKey),
          ],
        );
      },
    );
  }

  // "Somatica just tells you" default view: every tracked variable ranked by
  // connection strength against the anchor symptom, auto-computed - no
  // manual symptom picking required. Reuses the same rankedConnections
  // helper (symptom_analytics.dart) the Overview tab's "strongest
  // connections" mini-list calls, so the two never disagree.
  Widget _autoRankedSection(
      BuildContext context, Map<String, DashboardRecord> byKey) {
    final theme = FlutterFlowTheme.of(context);
    final anchor = byKey[_anchorKey];
    final heading = Text(
      'Your strongest connections',
      style: theme.headlineSmall.override(
        font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 20.0,
      ),
    );

    if (anchor == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: 14.0),
          _emptyCard(context, 'No data yet for this window.'),
        ],
      );
    }

    final ranked = rankedConnections(anchor, byKey.values.toList());
    final filtered = _timingFilter == null
        ? ranked
        : ranked.where((p) => p.$2.timingBucket == _timingFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading,
        const SizedBox(height: 4.0),
        Text(
          'Factors that tend to be related to your '
          '${anchor.metricLabel.toLowerCase()}.',
          style: theme.labelSmall.override(
            font: GoogleFonts.inter(),
            color: theme.secondaryText,
          ),
        ),
        const SizedBox(height: 14.0),
        _timingFilterChips(context),
        const SizedBox(height: 14.0),
        if (filtered.isEmpty)
          _emptyCard(
            context,
            ranked.isEmpty
                ? 'Nothing stands out strongly enough yet — keep tracking '
                    '${anchor.metricLabel.toLowerCase()} and your other '
                    'variables.'
                : 'No connections show up ${_timingFilterLabel(_timingFilter)} '
                    'yet — try a different filter.',
          )
        else ...[
          _heroConnectionCard(
              context, anchor, filtered.first.$1, filtered.first.$2),
          if (filtered.length > 1) ...[
            const SizedBox(height: 16.0),
            for (var i = 1; i < filtered.length; i++)
              Padding(
                padding: EdgeInsets.only(
                    bottom: i == filtered.length - 1 ? 0.0 : 8.0),
                child: _connectionListRow(
                    context, anchor, filtered[i].$1, filtered[i].$2),
              ),
          ],
        ],
      ],
    );
  }

  // Before/Same day/After/All - filters the auto-ranked list above by each
  // connection's strongest-lag direction (ConnectionTiming). Only affects
  // the auto-ranked section; the manual "Advanced" comparison below is
  // untouched.
  Widget _timingFilterChips(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    Widget chip(String label, ConnectionTiming? value) {
      final selected = _timingFilter == value;
      return InkWell(
        onTap: () => setState(() => _timingFilter = value),
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
          decoration: BoxDecoration(
            color:
                selected ? theme.primary.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: selected ? theme.primary : theme.alternate,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              color: selected ? theme.primary : theme.secondaryText,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        chip('All', null),
        chip('Before', ConnectionTiming.before),
        chip('Same day', ConnectionTiming.sameDay),
        chip('After', ConnectionTiming.after),
      ],
    );
  }

  String _timingFilterLabel(ConnectionTiming? timing) {
    switch (timing) {
      case ConnectionTiming.before:
        return 'before';
      case ConnectionTiming.sameDay:
        return 'on the same day';
      case ConnectionTiming.after:
        return 'after';
      case null:
        return '';
    }
  }

  // The pre-existing manual flow (anchor vs. hand-picked compare symptoms)
  // plus the full correlation matrix, tucked behind a collapsed expansion so
  // it no longer competes with the automatic list above for first-screen
  // attention - for the person who wants to inspect one specific pair or
  // see every pairwise correlation at once.
  Widget _advancedSection(
    BuildContext context,
    List<DashboardRecord> options,
    Map<String, DashboardRecord> byKey,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _advancedExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4.0),
        iconColor: theme.secondaryText,
        collapsedIconColor: theme.secondaryText,
        title: Text(
          'Advanced: compare specific symptoms',
          style: theme.labelMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          _compareChips(context, options),
          const SizedBox(height: 18.0),
          _body(context, byKey),
          const SizedBox(height: 22.0),
          _correlationMatrixCard(context, byKey.values.toList()),
        ],
      ),
    );
  }

  String _labelFor(List<DashboardRecord> options, String key) =>
      options.firstWhereOrNull((d) => d.metricKey == key)?.metricLabel ?? key;

  Widget _compareChips(BuildContext context, List<DashboardRecord> options) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (final key in _compareKeys)
          _symptomChip(
            context,
            _labelFor(options, key),
            onRemove: () => setState(() => _compareKeys.remove(key)),
          ),
        _addSymptomChip(context, options),
      ],
    );
  }

  Widget _symptomChip(
    BuildContext context,
    String label, {
    VoidCallback? onRemove,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A33),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6.0),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close_rounded,
                  size: 14.0, color: theme.secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addSymptomChip(BuildContext context, List<DashboardRecord> options) {
    final theme = FlutterFlowTheme.of(context);
    final available = options
        .where((d) =>
            d.metricKey != _anchorKey && !_compareKeys.contains(d.metricKey))
        .toList();
    return InkWell(
      onTap: available.isEmpty
          ? null
          : () => _openAddSymptomSheet(context, available),
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15.0, color: theme.secondaryText),
            const SizedBox(width: 4.0),
            Text(
              'Add symptom',
              style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddSymptomSheet(
      BuildContext context, List<DashboardRecord> available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            children: available
                .map((d) => ListTile(
                      title: Text(
                        d.metricLabel,
                        style: TextStyle(
                            color: FlutterFlowTheme.of(context).primaryText),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() => _compareKeys.add(d.metricKey));
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Map<String, DashboardRecord> byKey) {
    final anchor = byKey[_anchorKey];

    final children = <Widget>[];

    if (anchor == null) {
      return _emptyCard(context, 'No data yet for this window.');
    }
    if (_compareKeys.isEmpty) {
      return _emptyCard(
        context,
        'Add another symptom above to see how it connects with '
        '${anchor.metricLabel.toLowerCase()}.',
      );
    }
    final others =
        _compareKeys.map((k) => byKey[k]).whereType<DashboardRecord>().toList();
    if (others.isEmpty) {
      return _emptyCard(
          context, 'No data yet for the symptoms you added in this window.');
    }

    // Split the manually-added comparison symptoms into ones with an actual
    // detected connection (|r| >= 0.3, see buildSymptomConnection) vs. ones
    // that just don't have enough of a pattern yet. The strongest detected
    // one becomes the hero card (ring + overlaid trend); the rest of the
    // detected ones list underneath; the not-yet-detected ones stay behind
    // "View all" so the main view doesn't fill up with "nothing found yet"
    // cards while a real connection is available to show.
    final pairs = [
      for (final other in others) (other, buildSymptomConnection(anchor, other)),
    ];
    final detected = pairs.where((p) => p.$2 != null).toList()
      ..sort((a, b) => b.$2!.strengthPct.compareTo(a.$2!.strengthPct));
    final undetected = pairs.where((p) => p.$2 == null).toList();

    if (detected.isEmpty) {
      children.addAll(undetected.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _relationshipCard(context, anchor, p.$1),
          )));
    } else {
      children.addAll([
        _heroConnectionCard(
            context, anchor, detected.first.$1, detected.first.$2!),
        const SizedBox(height: 22.0),
        _sectionHeaderRow(
          context,
          'All detected connections',
          onViewAll: undetected.isEmpty
              ? null
              : () => _showStillGathering(context, anchor, undetected),
        ),
        const SizedBox(height: 10.0),
        for (var i = 0; i < detected.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i == detected.length - 1 ? 0.0 : 8.0),
            child: _connectionListRow(
                context, anchor, detected[i].$1, detected[i].$2!),
          ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  // Full N x N same-day correlation heatmap across every tracked variable -
  // the "at a glance" overview that sits above the anchor-specific
  // discoveries below (which drill into one pair at a time). Symmetric, so
  // only computed once per pair; rows carry the full label, columns are
  // numbered (with a legend) to keep cells small enough to fit N of them.
  Widget _correlationMatrixCard(
      BuildContext context, List<DashboardRecord> allVars) {
    final theme = FlutterFlowTheme.of(context);
    final vars = [...allVars]
      ..sort((a, b) => a.metricLabel.compareTo(b.metricLabel));

    Widget card(Widget child) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: child,
        );

    if (vars.length < 2) {
      return card(Text(
        'Track at least two variables to see a correlation matrix here.',
        style: theme.labelSmall.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
        ),
      ));
    }

    final n = vars.length;
    final matrix = List.generate(n, (_) => List<double?>.filled(n, null));
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final r = sameDayCorrelation(vars[i], vars[j]);
        matrix[i][j] = r;
        matrix[j][i] = r;
      }
    }

    const cellSize = 32.0;
    const labelColWidth = 24.0;

    // A flat, clearly-visible neutral fill for "not enough overlapping days
    // yet" cells - needs to read as its own distinct cell next to a
    // strongly-tinted real value, not as a gap in the grid.
    final noDataColor = theme.alternate.withValues(alpha: 0.7);

    Color cellColor(double? r) {
      if (r == null) return noDataColor;
      final t = r.abs().clamp(0.0, 1.0);
      final tint = r >= 0 ? const Color(0xFFE67532) : kCrystalBlue;
      return Color.lerp(theme.primaryBackground, tint, 0.18 + t * 0.72)!;
    }

    Widget headerCell(int index) => Container(
          width: cellSize,
          height: cellSize,
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              color: theme.secondaryText,
            ),
          ),
        );

    Widget dataCell(int i, int j) {
      final isDiagonal = i == j;
      final r = matrix[i][j];
      return Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(1.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDiagonal
              ? theme.alternate.withValues(alpha: 0.5)
              : cellColor(r),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: isDiagonal
            ? Icon(Icons.remove, size: 10.0, color: theme.secondaryText)
            : Text(
                r == null ? '·' : r.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w700,
                  color: r == null ? theme.secondaryText : Colors.white,
                ),
              ),
      );
    }

    return card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Correlation matrix',
            style: theme.titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: theme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            'How every tracked variable relates to every other, same day.',
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: cellSize),
                child: Column(
                  children: [
                    for (var i = 0; i < n; i++)
                      Container(
                        width: labelColWidth,
                        height: cellSize,
                        margin: const EdgeInsets.all(1.0),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w700,
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      Row(children: [
                        for (var j = 0; j < n; j++) headerCell(j),
                      ]),
                      for (var i = 0; i < n; i++)
                        Row(children: [
                          for (var j = 0; j < n; j++) dataCell(i, j),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Wrap(
            spacing: 12.0,
            runSpacing: 4.0,
            children: [
              for (var i = 0; i < n; i++)
                Text(
                  '${i + 1}. ${vars[i].metricLabel}',
                  style: theme.labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Negative',
                  style:
                      TextStyle(fontSize: 10.0, color: theme.secondaryText)),
              const SizedBox(width: 6.0),
              Container(
                width: 64.0,
                height: 8.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  gradient: LinearGradient(colors: [
                    kCrystalBlue,
                    theme.primaryBackground,
                    const Color(0xFFE67532),
                  ]),
                ),
              ),
              const SizedBox(width: 6.0),
              Text('Positive',
                  style:
                      TextStyle(fontSize: 10.0, color: theme.secondaryText)),
              const SizedBox(width: 14.0),
              Container(
                width: 12.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: noDataColor,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(width: 6.0),
              Text('· = not enough overlapping days',
                  style:
                      TextStyle(fontSize: 10.0, color: theme.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeaderRow(BuildContext context, String text,
      {VoidCallback? onViewAll}) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.labelMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
              color: theme.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                color: theme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12.0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  // Donut-style ring showing the connection strength as a percentage -
  // built from two PieChart sections (filled + remainder) rather than a
  // CustomPainter, matching how ClinicalDonutChart already draws rings
  // elsewhere in the app.
  Widget _overlapRing(
    BuildContext context, {
    required int percent,
    required Color color,
    double size = 68.0,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: 270,
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: size / 2 - 8.0,
              sections: [
                PieChartSectionData(
                  color: color,
                  value: clamped.toDouble(),
                  radius: 8.0,
                  showTitle: false,
                ),
                PieChartSectionData(
                  color: theme.alternate,
                  value: (100 - clamped).toDouble(),
                  radius: 8.0,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$clamped%',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                ),
              ),
              Text('overlap',
                  style: TextStyle(fontSize: 9.0, color: theme.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }

  // The strongest detected connection, promoted above the compact list:
  // strength ring, plain-language sentence (reusing the discovery engine's
  // own title copy), and the two symptoms' trends overlaid on one chart.
  Widget _heroConnectionCard(
    BuildContext context,
    DashboardRecord anchor,
    DashboardRecord other,
    SymptomConnection connection,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final tier = connectionStrengthTier(connection.strengthPct);
    final sentence = connection.title.isEmpty
        ? connection.title
        : '${connection.title[0].toUpperCase()}${connection.title.substring(1)}.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: tier.color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tier.label} connection',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w800,
                        color: tier.color,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${anchor.metricLabel} ↔ ${other.metricLabel}',
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        color: theme.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              _overlapRing(context,
                  percent: connection.strengthPct, color: tier.color),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            sentence,
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              lineHeight: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              _legendDot(theme.primary),
              const SizedBox(width: 6.0),
              Text(anchor.metricLabel,
                  style: TextStyle(fontSize: 11.0, color: theme.secondaryText)),
              const SizedBox(width: 14.0),
              _legendDot(theme.accent2),
              const SizedBox(width: 6.0),
              Text(other.metricLabel,
                  style: TextStyle(fontSize: 11.0, color: theme.secondaryText)),
            ],
          ),
          const SizedBox(height: 8.0),
          DualTrendChart(
            aValues: anchor.dailyValues,
            aColor: theme.primary,
            bValues: other.dailyValues,
            bColor: theme.accent2,
          ),
          const SizedBox(height: 8.0),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  _openConnectionDetail(context, anchor, other, connection),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: Text(
                'Why might this be happening?',
                style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact row for every other detected connection under "All detected
  // connections" - tapping it opens the same connection-detail sheet the
  // hero card's link does.
  Widget _connectionListRow(
    BuildContext context,
    DashboardRecord anchor,
    DashboardRecord other,
    SymptomConnection connection,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final tier = connectionStrengthTier(connection.strengthPct);
    return InkWell(
      onTap: () => _openConnectionDetail(context, anchor, other, connection),
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: theme.alternate, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(Icons.hub_outlined, size: 16.0, color: tier.color),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                '${anchor.metricLabel} ↔ ${other.metricLabel}',
                overflow: TextOverflow.ellipsis,
                style: theme.bodySmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: theme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
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
                tier.label,
                style: TextStyle(
                    color: tier.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5),
              ),
            ),
            const SizedBox(width: 8.0),
            Text(
              '${connection.strengthPct}%',
              style: TextStyle(
                  color: theme.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.0),
            ),
            const SizedBox(width: 2.0),
            Icon(Icons.chevron_right_rounded,
                size: 16.0, color: theme.secondaryText),
          ],
        ),
      ),
    );
  }

  // "View all" from the detected-connections list opens the symptoms that
  // don't have a strong-enough pattern yet, reusing the full _relationshipCard
  // treatment (which already explains that state) instead of dropping them
  // silently.
  void _showStillGathering(
    BuildContext context,
    DashboardRecord anchor,
    List<(DashboardRecord, SymptomConnection?)> undetected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (sheetContext, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Still gathering data',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      fontWeight: FontWeight.w700,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              const SizedBox(height: 14.0),
              ...undetected.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _relationshipCard(context, anchor, p.$1),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _relationshipCard(
      BuildContext context, DashboardRecord anchor, DashboardRecord other) {
    final theme = FlutterFlowTheme.of(context);
    final connection = buildSymptomConnection(anchor, other);
    final (overlapDays, totalDays) = symptomOverlap(anchor, other);
    final overlapPct =
        totalDays == 0 ? 0 : (overlapDays / totalDays * 100).round();
    final color = connection == null ? theme.secondaryText : theme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_outlined, size: 16.0, color: color),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  '${anchor.metricLabel} ↔ ${other.metricLabel}',
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    color: theme.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (connection != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${connection.strengthPct}% connection',
                    style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.0),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'Overlap: logged together on $overlapDays of $totalDays tracked '
            'days ($overlapPct%).',
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              lineHeight: 1.4,
            ),
          ),
          if (connection == null) ...[
            const SizedBox(height: 10.0),
            Text(
              'Not enough of a pattern yet between ${anchor.metricLabel.toLowerCase()} '
              'and ${other.metricLabel.toLowerCase()} — keep tracking both.',
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                lineHeight: 1.4,
              ),
            ),
          ] else ...[
            const SizedBox(height: 14.0),
            Text(
              'Correlated trend',
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                color: theme.secondaryText,
                fontSize: 11.0,
              ),
            ),
            const SizedBox(height: 6.0),
            _CompareBars(
              leftLabel: connection.groupALabel,
              leftValue: connection.groupAValue,
              rightLabel: connection.groupBLabel,
              rightValue: connection.groupBValue,
              highlightLeft: connection.highlightA,
            ),
            const SizedBox(height: 14.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(connection.icon, size: 16.0, color: theme.primary),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          connection.title,
                          style: theme.bodySmall.override(
                            font:
                                GoogleFonts.inter(fontWeight: FontWeight.w600),
                            color: theme.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Text(
                          connection.detail,
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
            ),
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    _openConnectionDetail(context, anchor, other, connection),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text(
                  'Why might this be happening?',
                  style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Opens the connection-detail sheet (Summary/Timeline): runs episode
  // detection + the -3d..+3d timeline aggregation for this pair, then hands
  // the already-built data to ConnectionDetailSheet, which is pure
  // presentation (episode_analytics.dart owns the math).
  void _openConnectionDetail(
    BuildContext context,
    DashboardRecord anchor,
    DashboardRecord other,
    SymptomConnection connection,
  ) {
    final episodes = detectEpisodes(anchor);
    final timeline = buildEpisodeTimeline(episodes, other);
    final summary = buildConnectionSummary(episodes, other, connection);
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => ConnectionDetailSheet(
        anchor: anchor,
        other: other,
        connection: connection,
        episodes: episodes,
        timeline: timeline,
        summary: summary,
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String message) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.alternate, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.secondaryText, size: 18.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                lineHeight: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Two thin horizontal bars comparing a highlighted group against a
// baseline. Values are scaled to the larger of the two so the bars stay
// readable even when both numbers are small (e.g. a 0-1 boolean-derived
// mean).
class _CompareBars extends StatelessWidget {
  const _CompareBars({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.highlightLeft,
  });

  final String leftLabel;
  final double leftValue;
  final String rightLabel;
  final double rightValue;
  final bool highlightLeft;

  @override
  Widget build(BuildContext context) {
    final accent = FlutterFlowTheme.of(context).primary;
    final baseline = FlutterFlowTheme.of(context).alternate;
    final maxValue = [leftValue.abs(), rightValue.abs(), 0.001]
        .reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(context, leftLabel, leftValue, maxValue,
            highlightLeft ? accent : baseline),
        const SizedBox(height: 6.0),
        _bar(context, rightLabel, rightValue, maxValue,
            highlightLeft ? baseline : accent),
      ],
    );
  }

  Widget _bar(BuildContext context, String label, double value, double maxValue,
      Color color) {
    final fraction = (value.abs() / maxValue).clamp(0.05, 1.0);
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 110.0,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              fontSize: 10.0,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8.0,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.0)),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8.0,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4.0)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        SizedBox(
          width: 34.0,
          child: Text(
            value.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 11.0),
          ),
        ),
      ],
    );
  }
}
