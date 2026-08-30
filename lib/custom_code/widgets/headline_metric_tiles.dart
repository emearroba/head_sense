// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// The 4 compact headline metrics at the top of a Results period ("Average
// intensity", "Spikes", "Crystal clear days", "Most common intensity") -
// deliberately the most visually prominent thing on the Results tab, per the
// "results should dominate the screen" priority. A 2x2 grid of bold numbers
// reads as a dashboard headline; the discovery/insight cards below carry the
// narrative detail.
class HeadlineMetric {
  const HeadlineMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sublabel,
  });

  final String label;
  final String value;
  final String? sublabel;
  final IconData icon;
  final Color color;
}

class HeadlineMetricTiles extends StatelessWidget {
  const HeadlineMetricTiles({super.key, required this.metrics});

  final List<HeadlineMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10.0,
      crossAxisSpacing: 10.0,
      childAspectRatio: 2.15,
      children: metrics.map((m) => _tile(context, m)).toList(),
    );
  }

  Widget _tile(BuildContext context, HeadlineMetric m) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: m.color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icon, size: 13.0, color: m.color),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  m.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.secondaryText,
                    fontSize: 11.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                m.value,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                ),
              ),
              if (m.sublabel != null) ...[
                const SizedBox(width: 5.0),
                Flexible(
                  child: Text(
                    m.sublabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.0, color: theme.secondaryText),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
