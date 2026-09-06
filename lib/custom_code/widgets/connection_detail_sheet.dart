// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'episode_analytics.dart';
import 'episode_timeline_chart.dart';
import 'symptom_analytics.dart';

// The Connections tab's per-connection drill-down: tapping a connection card
// (in connections_panel.dart) opens this instead of the old plain-text "why"
// bottom sheet. Summary reuses the existing sentence/why copy from
// SymptomConnection plus new episode-based stat tiles; Timeline is the new
// -3d..+3d chart. All the actual math (episode detection, per-offset
// averaging, consistency scoring) is computed by the caller via
// episode_analytics.dart and handed in already-built, so this widget is pure
// presentation.
class ConnectionDetailSheet extends StatefulWidget {
  const ConnectionDetailSheet({
    super.key,
    required this.anchor,
    required this.other,
    required this.connection,
    required this.episodes,
    required this.timeline,
    required this.summary,
    this.windowDays = 3,
  });

  final DashboardRecord anchor;
  final DashboardRecord other;
  final SymptomConnection connection;
  final List<Episode> episodes;
  final List<OffsetPoint> timeline;
  final ConnectionSummaryStats summary;
  final int windowDays;

  @override
  State<ConnectionDetailSheet> createState() => _ConnectionDetailSheetState();
}

class _ConnectionDetailSheetState extends State<ConnectionDetailSheet> {
  int _tab = 0; // 0 = Summary, 1 = Timeline

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (sheetContext, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.anchor.metricLabel} ↔ ${widget.other.metricLabel}',
              style: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 14.0),
            _tabsPill(context),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView(
                controller: scrollController,
                children:
                    _tab == 0 ? _summaryChildren(context) : _timelineChildren(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Same hand-rolled pill pattern as the Results screen's main Overview/
  // Connections/Interventions tabs (results_widget.dart's _mainTabButton) -
  // this codebase doesn't use TabController anywhere, so a local int +
  // setState stays consistent with the rest of the app.
  Widget _tabsPill(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    Widget button(int index, String label) {
      final selected = _tab == index;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = index),
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9.0),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF123C45) : Colors.transparent,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: selected ? theme.primary : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: selected ? theme.primary : theme.primaryText,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(13.0),
      ),
      child: Row(children: [button(0, 'Summary'), button(1, 'Timeline')]),
    );
  }

  List<Widget> _summaryChildren(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final connection = widget.connection;
    final summary = widget.summary;
    final sentence = connection.title.isEmpty
        ? connection.title
        : '${connection.title[0].toUpperCase()}${connection.title.substring(1)}.';
    return [
      Text(
        sentence,
        style: theme.bodyMedium.override(
          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
          color: theme.primaryText,
          fontWeight: FontWeight.w600,
          lineHeight: 1.4,
        ),
      ),
      const SizedBox(height: 18.0),
      Text(
        'Key takeaway',
        style: theme.labelMedium.override(
          font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
          color: theme.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10.0),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _statTile(
                context,
                value: summary.checkableEpisodes == 0
                    ? '—'
                    : '${summary.episodesWithPattern} of ${summary.checkableEpisodes}',
                label: 'episodes',
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _statTile(
                context,
                value: summary.typicalTiming,
                label: 'typical timing',
                small: true,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _statTile(
                context,
                value: summary.consistencyLabel,
                label: 'consistency',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18.0),
      Text(
        connection.why,
        style: theme.bodySmall.override(
          color: theme.secondaryText,
          lineHeight: 1.5,
        ),
      ),
      const SizedBox(height: 16.0),
      _disclaimer(context),
    ];
  }

  List<Widget> _timelineChildren(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return [
      Text(
        'Your typical pattern',
        style: theme.labelMedium.override(
          font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
          color: theme.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2.0),
      Text(
        'How ${widget.other.metricLabel.toLowerCase()} changes vs your average, '
        'around the start of your ${widget.anchor.metricLabel.toLowerCase()} '
        'episodes.',
        style: theme.labelSmall.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
        ),
      ),
      const SizedBox(height: 18.0),
      EpisodeTimelineChart(
        points: widget.timeline,
        windowDays: widget.windowDays,
        anchorLabel: widget.anchor.metricLabel,
        lineColor: theme.primary,
      ),
      const SizedBox(height: 16.0),
      Text(
        'Based on ${widget.episodes.length} detected episode'
        '${widget.episodes.length == 1 ? '' : 's'} in this period.',
        style: theme.labelSmall.override(
          font: GoogleFonts.inter(),
          color: theme.secondaryText,
        ),
      ),
      const SizedBox(height: 16.0),
      _disclaimer(context),
    ];
  }

  Widget _statTile(
    BuildContext context, {
    required String value,
    required String label,
    bool small = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: theme.alternate.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: small ? 14.0 : 19.0,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(
            label,
            style: theme.labelSmall.override(
              font: GoogleFonts.inter(),
              color: theme.secondaryText,
              fontSize: 10.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      'General information, not a diagnosis — talk to your doctor about what '
      'fits your situation.',
      style: theme.labelSmall.override(
        font: GoogleFonts.inter(fontStyle: FontStyle.italic),
        color: theme.secondaryText,
      ),
    );
  }
}
