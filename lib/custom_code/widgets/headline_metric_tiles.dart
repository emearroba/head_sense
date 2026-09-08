// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// The 4 compact headline metrics at the top of a Results period ("Average
// intensity", "Spikes", "Crystal clear days", "Most common intensity") -
// deliberately the most visually prominent thing on the Results tab, per the
// "results should dominate the screen" priority. A single row of bold
// numbers reads as a dashboard headline; the discovery/insight cards below
// carry the narrative detail. `footer` is a variable-height slot below the
// value - a delta indicator, a sparkle, or a colored ring - so all 4 tiles
// keep the same rhythm whether or not a given metric has one (the row
// stretches every tile to the tallest one via IntrinsicHeight).
class HeadlineMetric {
  const HeadlineMetric({
    required this.label,
    required this.value,
    required this.color,
    this.footer,
  });

  final String label;
  final String value;
  final Color color;
  final Widget? footer;
}

class HeadlineMetricTiles extends StatelessWidget {
  const HeadlineMetricTiles({super.key, required this.metrics});

  final List<HeadlineMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 8.0),
            Expanded(child: _tile(context, metrics[i])),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, HeadlineMetric m) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: m.color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            m.value,
            style: TextStyle(
              fontSize: 21.0,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 3.0),
          // Fixed height for exactly 2 lines at this font/line-height,
          // regardless of whether this particular label actually wraps to 1
          // or 2 lines - IntrinsicHeight (which stretches every tile in the
          // row to the tallest) measures each child's intrinsic height using
          // a different width pass than the real Expanded layout gets, so a
          // label that wraps only at the real (narrower) width was being
          // under-measured, overflowing the row by a few px. Reserving a
          // constant, width-independent height here removes that ambiguity.
          SizedBox(
            height: 24.0,
            child: Text(
              m.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall.override(
                font: GoogleFonts.inter(),
                color: theme.secondaryText,
                fontSize: 10.5,
                lineHeight: 1.15,
              ),
            ),
          ),
          if (m.footer != null) ...[
            const SizedBox(height: 6.0),
            // Same fixed-height trick as the label above, and for the same
            // reason: HeadlineDelta's `Flexible(child: Text(..., overflow:
            // ellipsis))` is itself width-dependent, so IntrinsicHeight's
            // dry-layout pass under-measured it too - this was the actual
            // remaining source of the "9.0 pixels" bottom overflow on tiles
            // that have a footer (the label fix alone didn't touch this).
            SizedBox(height: 18.0, child: m.footer!),
          ],
        ],
      ),
    );
  }
}

// A small "↓18% vs earlier" / "↑2 vs earlier" delta line for a headline
// tile footer. `goodWhenDown` says which direction counts as improvement
// for this metric (e.g. true for intensity/spikes, since lower is better).
class HeadlineDelta extends StatelessWidget {
  const HeadlineDelta({
    super.key,
    required this.isDown,
    required this.magnitudeLabel,
    required this.goodWhenDown,
  });

  final bool isDown;
  final String magnitudeLabel;
  final bool goodWhenDown;

  static const _good = Color(0xFF4CAF6D);
  static const _bad = Color(0xFFE5484D);

  @override
  Widget build(BuildContext context) {
    final good = isDown == goodWhenDown;
    final color = good ? _good : _bad;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${isDown ? '↓' : '↑'} $magnitudeLabel',
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.0),
        ),
        const SizedBox(width: 4.0),
        Flexible(
          child: Text(
            'vs earlier',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FlutterFlowTheme.of(context).secondaryText,
              fontSize: 10.0,
            ),
          ),
        ),
      ],
    );
  }
}

// A small colored ring - used on the "Most common intensity" tile so the
// category (crystal/mild/moderate/severe) reads at a glance from color
// alone, same as the rainbow legend used elsewhere in the app.
class HeadlineRing extends StatelessWidget {
  const HeadlineRing({super.key, required this.color, this.label});

  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14.0,
          height: 14.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2.5),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 5.0),
          Flexible(
            child: Text(
              label!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: FlutterFlowTheme.of(context).secondaryText,
                fontSize: 10.0,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
