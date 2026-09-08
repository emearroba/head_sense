// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

import 'episode_analytics.dart';

// The Connections tab's per-connection "Timeline" chart: how a factor's
// value changes, on average across every detected spike day of the anchor
// symptom (offset 0), in the days before/after each one. Sibling to
// DualTrendChart (same fl_chart styling conventions - curved line, no dot
// markers, muted axis labels) but plots day-offset-from-event rather than
// real calendar dates, and adds a shaded min/max band plus a marker at
// offset 0, neither of which DualTrendChart needs.
class EpisodeTimelineChart extends StatelessWidget {
  const EpisodeTimelineChart({
    super.key,
    required this.points,
    required this.windowDays,
    required this.anchorLabel,
    required this.lineColor,
    this.height = 180.0,
  });

  final List<OffsetPoint> points;
  final int windowDays;
  final String anchorLabel;
  final Color lineColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final withData = points.where((p) => p.pctChangeVsBaseline != null).toList();

    if (withData.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Not enough overlapping days around your spikes yet.',
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ),
      );
    }

    final lowSpots = <FlSpot>[];
    final highSpots = <FlSpot>[];
    final meanSpots = <FlSpot>[];
    for (final p in withData) {
      final x = p.offset.toDouble();
      lowSpots.add(FlSpot(x, p.bandLow!));
      highSpots.add(FlSpot(x, p.bandHigh!));
      meanSpots.add(FlSpot(x, p.pctChangeVsBaseline!));
    }

    final allBandValues = [
      for (final p in withData) ...[p.bandLow!, p.bandHigh!],
    ];
    final rawMin = allBandValues.reduce((a, b) => a < b ? a : b);
    final rawMax = allBandValues.reduce((a, b) => a > b ? a : b);
    // Always straddle 0% ("no change vs baseline") so the chart reads as a
    // deviation from a flat line, even when every point happens to move the
    // same direction, plus a little headroom so the band isn't clipped at
    // the plot edges.
    final span = (rawMax - rawMin).abs().clamp(10.0, double.infinity);
    final minY = (rawMin < 0 ? rawMin : 0.0) - span * 0.15;
    final maxY = (rawMax > 0 ? rawMax : 0.0) + span * 0.15;

    String offsetLabel(int offset) {
      if (offset == 0) return anchorLabel;
      return offset > 0 ? '+${offset}d' : '${offset}d';
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: -windowDays.toDouble(),
          maxX: windowDays.toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: 0,
                color: lineColor.withValues(alpha: 0.5),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
            ],
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: theme.alternate,
                strokeWidth: 1,
              ),
            ],
          ),
          // Shades the region between the invisible low/high bound lines
          // (lineBarsData indices 0 and 1) to form the min/max confidence
          // band behind the visible mean line (index 2).
          betweenBarsData: [
            BetweenBarsData(
              fromIndex: 0,
              toIndex: 1,
              color: lineColor.withValues(alpha: 0.14),
            ),
          ],
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40.0,
                getTitlesWidget: (value, meta) => Text(
                  '${value >= 0 ? '+' : ''}${value.round()}%',
                  style: TextStyle(fontSize: 9.0, color: theme.secondaryText),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22.0,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final offset = value.round();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      offsetLabel(offset),
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: offset == 0 ? FontWeight.w700 : FontWeight.normal,
                        color: offset == 0 ? theme.primaryText : theme.secondaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            // Invisible low/high bounds - only used so the visible high line
            // can shade the region between them into a confidence band.
            LineChartBarData(
              spots: lowSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              barWidth: 0,
              color: Colors.transparent,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: highSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              barWidth: 0,
              color: Colors.transparent,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: meanSpots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              barWidth: 2.5,
              color: lineColor,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: spot.x == 0 ? 4.0 : 2.5,
                  color: lineColor,
                  strokeWidth: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
