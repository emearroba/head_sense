// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Shared time-range selector for the Results and Patterns tabs: one
// continuous rounded track (Results' original look) holding 4 segments -
// only the selected segment gets a fill + cyan border/text, the rest stay
// transparent. 60/90 days are Premium-gated (lock/plus mark + upsell
// dialog), matching the gate that already existed on Patterns' pill row.
class PeriodSelectorBubble extends StatelessWidget {
  const PeriodSelectorBubble({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isPremium,
  });

  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;
  final bool isPremium;

  static const _premiumPeriods = {'last60', 'last90'};
  static const _periods = [
    ('last7', '7 days'),
    ('last30', '30 days'),
    ('last60', '60 days'),
    ('last90', '90 days'),
  ];

  void _select(BuildContext context, String period) {
    if (_premiumPeriods.contains(period) && !isPremium) {
      _showUpsell(context, period);
      return;
    }
    onPeriodChanged(period);
  }

  void _showUpsell(BuildContext context, String period) {
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
          style: FlutterFlowTheme.of(context).bodySmall.override(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Not now',
              style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            // TODO: wire to the real subscription flow once payment infra
            // (see CLAUDE.md) is built; for now this is a UI-only
            // placeholder.
            child: const Text(
              'Upgrade',
              style: TextStyle(color: Color(0xFFFFC533), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 34.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(11.0),
      ),
      child: Row(
        children: [
          for (final period in _periods)
            Expanded(child: _segment(context, period.$1, period.$2)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String period, String label) {
    final theme = FlutterFlowTheme.of(context);
    final selected = selectedPeriod == period;
    final premium = _premiumPeriods.contains(period) && !isPremium;
    final premiumIcon = period == 'last60' ? Icons.lock_outline : Icons.add;
    return InkWell(
      onTap: () => _select(context, period),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF123C45) : Colors.transparent,
          borderRadius: BorderRadius.circular(9.0),
          border: Border.all(
            color: selected ? theme.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: selected ? theme.primary : theme.primaryText,
              ),
            ),
            if (premium) ...[
              const SizedBox(width: 3.0),
              Icon(premiumIcon, size: 10.0, color: const Color(0xFFFFC533)),
            ],
          ],
        ),
      ),
    );
  }
}
