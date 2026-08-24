// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Shared "locked feature" card for paywalled Pattern Analysis surfaces
// (Dashboard's "Medication Patterns" and the Patterns tab's "Pattern
// Analysis"). Visually distinguishes two different reasons a feature is
// locked, so users don't read "not enough data yet" as "pay to unlock":
//   - progress-gated: daysRemaining > 0, still building up data. Hourglass
//     icon, primary/teal color, no tap action.
//   - premium-gated: daysRemaining <= 0, data is ready but the analysis
//     itself is behind the subscription. Crown icon, gold color, tappable.
class PatternLockCard extends StatelessWidget {
  const PatternLockCard({
    super.key,
    required this.title,
    required this.daysRemaining,
    this.onTapUpgrade,
  });

  final String title;
  final int daysRemaining;
  final VoidCallback? onTapUpgrade;

  bool get _isProgressGated => daysRemaining > 0;

  @override
  Widget build(BuildContext context) {
    final color = _isProgressGated
        ? FlutterFlowTheme.of(context).primary
        : const Color(0xFFFFC533);
    final icon =
        _isProgressGated ? Icons.hourglass_top : Icons.workspace_premium;
    final subtitle = _isProgressGated
        ? '$daysRemaining more day${daysRemaining == 1 ? '' : 's'} to unlock'
        : 'Unlocks with Premium';

    return InkWell(
      onTap: _isProgressGated ? null : onTapUpgrade,
      borderRadius: BorderRadius.circular(24.0),
      child: Opacity(
        opacity: _isProgressGated ? 0.6 : 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(24.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(icon, color: color, size: 20.0),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                              font: GoogleFonts.inter(),
                              color: color,
                              lineHeight: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!_isProgressGated)
                  Icon(
                    Icons.chevron_right,
                    color: FlutterFlowTheme.of(context).secondaryText,
                    size: 18.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
