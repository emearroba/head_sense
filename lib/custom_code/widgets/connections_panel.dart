// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'symptom_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:collection/collection.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// "Connections" tab content for the Results screen: lets a user pick several
// tracked symptoms (headache is always first/the anchor) and see how each
// other selected symptom relates to it - connection strength, day overlap,
// a compact compare-trend visual, and the plain-language "detected
// connection" finding. Reuses the correlation math from
// symptom_analytics.dart (also used, for the single-focus case, by
// pattern_insights_panel.dart's "What we noticed" cards on My symptoms).
class ConnectionsPanel extends StatefulWidget {
  const ConnectionsPanel({
    super.key,
    required this.trackedMetricKeys,
    required this.userPlan,
  });

  final List<String> trackedMetricKeys;
  final String userPlan;

  @override
  State<ConnectionsPanel> createState() => _ConnectionsPanelState();
}

class _ConnectionsPanelState extends State<ConnectionsPanel> {
  static const _defaultAnchorKey = 'headache_intensity';

  String _selectedPeriod = 'last30';
  bool get _isPremium => widget.userPlan == 'premium';
  static const _premiumPeriods = {'last60', 'last90'};

  // First entry is the anchor everything else is compared against. A plain
  // List (not a Set) so insertion order - and therefore which symptom is
  // "Headache" in "Headache ↔ Fatigue" - stays stable and predictable.
  late List<String> _selectedKeys;
  bool _initializedDefaults = false;

  @override
  void initState() {
    super.initState();
    _selectedKeys = [_defaultAnchorKey];
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          style: FlutterFlowTheme.of(context)
              .bodySmall
              .override(color: FlutterFlowTheme.of(context).secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Not now',
                style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Upgrade',
                style: TextStyle(color: Color(0xFFFFC533), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DashboardRecord>>(
      stream: queryDashboardRecord(
        queryBuilder: (q) => q
            .where('userRef', isEqualTo: currentUserReference)
            .where('periodType', isEqualTo: _selectedPeriod),
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

        // Seed a sensible second symptom the first time real options come
        // in, so the tab opens already showing a relationship (matching the
        // "Headache + Fatigue" example) instead of an empty prompt.
        if (!_initializedDefaults && options.isNotEmpty) {
          _initializedDefaults = true;
          final fallback = options.firstWhereOrNull((d) =>
              d.metricKey != _defaultAnchorKey && d.metricKey != 'analgesia');
          if (fallback != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedKeys.length == 1) {
                setState(() => _selectedKeys.add(fallback.metricKey));
              }
            });
          }
        }

        final byKey = {for (final d in options) d.metricKey: d};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _symptomChips(context, options),
            const SizedBox(height: 10.0),
            _periodSelector(context),
            const SizedBox(height: 18.0),
            _body(context, byKey),
          ],
        );
      },
    );
  }

  String _labelFor(List<DashboardRecord> options, String key) =>
      options.firstWhereOrNull((d) => d.metricKey == key)?.metricLabel ?? key;

  Widget _symptomChips(BuildContext context, List<DashboardRecord> options) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (final key in _selectedKeys)
          _symptomChip(
            context,
            _labelFor(options, key),
            isAnchor: key == _selectedKeys.first,
            onRemove: _selectedKeys.length > 1
                ? () => setState(() => _selectedKeys.remove(key))
                : null,
          ),
        _addSymptomChip(context, options),
      ],
    );
  }

  Widget _symptomChip(
    BuildContext context,
    String label, {
    required bool isAnchor,
    VoidCallback? onRemove,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isAnchor ? const Color(0xFF123C45) : const Color(0xFF1A2A33),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isAnchor ? theme.primary : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: isAnchor ? theme.primary : theme.primaryText,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6.0),
            InkWell(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, size: 14.0, color: theme.secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addSymptomChip(BuildContext context, List<DashboardRecord> options) {
    final theme = FlutterFlowTheme.of(context);
    final available = options.where((d) => !_selectedKeys.contains(d.metricKey)).toList();
    return InkWell(
      onTap: available.isEmpty ? null : () => _openAddSymptomSheet(context, available),
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
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: theme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddSymptomSheet(BuildContext context, List<DashboardRecord> available) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            children: available
                .map((d) => ListTile(
                      title: Text(
                        d.metricLabel,
                        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() => _selectedKeys.add(d.metricKey));
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _periodSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _pill(context, 'last7', '7 days')),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last30', '30 days')),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last60', '60 days', premium: !_isPremium)),
        const SizedBox(width: 8.0),
        Expanded(child: _pill(context, 'last90', '90 days', premium: !_isPremium)),
      ],
    );
  }

  Widget _pill(BuildContext context, String period, String label, {bool premium = false}) {
    final selected = _selectedPeriod == period;
    final selectedColor = FlutterFlowTheme.of(context).primary;
    return InkWell(
      onTap: () => _selectPeriod(period),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF123C45) : const Color(0xFF1A2A33),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: selected ? selectedColor : Colors.transparent, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: selected ? selectedColor : FlutterFlowTheme.of(context).primaryText,
              ),
            ),
            if (premium) ...[
              const SizedBox(width: 3.0),
              const Text('✦', style: TextStyle(fontSize: 10.0, color: Color(0xFFFFC533))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Map<String, DashboardRecord> byKey) {
    final theme = FlutterFlowTheme.of(context);
    if (_selectedKeys.length < 2) {
      return _emptyCard(
        context,
        'Add another symptom above to see how it connects with '
        '${byKey[_selectedKeys.first]?.metricLabel.toLowerCase() ?? "this symptom"}.',
      );
    }

    final anchor = byKey[_selectedKeys.first];
    if (anchor == null) {
      return _emptyCard(context, 'No data yet for this window.');
    }
    final others = _selectedKeys.skip(1).map((k) => byKey[k]).whereType<DashboardRecord>().toList();
    if (others.isEmpty) {
      return _emptyCard(context, 'No data yet for the symptoms you added in this window.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How your symptoms connect',
          style: theme.headlineSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
            color: theme.primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 20.0,
          ),
        ),
        const SizedBox(height: 14.0),
        ...others.map((other) => Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: _relationshipCard(context, anchor, other),
            )),
      ],
    );
  }

  Widget _relationshipCard(BuildContext context, DashboardRecord anchor, DashboardRecord other) {
    final theme = FlutterFlowTheme.of(context);
    final connection = buildSymptomConnection(anchor, other);
    final (overlapDays, totalDays) = symptomOverlap(anchor, other);
    final overlapPct = totalDays == 0 ? 0 : (overlapDays / totalDays * 100).round();
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
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${connection.strengthPct}% connection',
                    style: TextStyle(color: theme.primary, fontWeight: FontWeight.w700, fontSize: 11.0),
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
                            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
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
                onPressed: () => _showWhy(context, connection),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text(
                  'Why might this be happening?',
                  style: TextStyle(color: theme.primary, fontWeight: FontWeight.w600, fontSize: 12.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWhy(BuildContext context, SymptomConnection connection) {
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
              connection.why,
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
        _bar(context, leftLabel, leftValue, maxValue, highlightLeft ? accent : baseline),
        const SizedBox(height: 6.0),
        _bar(context, rightLabel, rightValue, maxValue, highlightLeft ? baseline : accent),
      ],
    );
  }

  Widget _bar(BuildContext context, String label, double value, double maxValue, Color color) {
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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4.0)),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8.0,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.0)),
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
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.0),
          ),
        ),
      ],
    );
  }
}
