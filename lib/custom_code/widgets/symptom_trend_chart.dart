// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'symptom_analytics.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

// Compact trend chart for the Results tab, driven directly by a
// DashboardRecord's embedded dailyValues (no extra Firestore query needed,
// unlike the Dashboard tab's SymptomBarChart which reads the daily_values
// subcollection). A smooth line with a green->red gradient fill under it
// (worse days read as "hotter") and a tap/hover tooltip with the date and
// value - deliberately smaller/simpler than SymptomBarChart, since this
// lives inside a Results period card, not a full-page chart.
class SymptomTrendChart extends StatelessWidget {
  const SymptomTrendChart({
    super.key,
    required this.values,
    this.height = 150.0,
    this.markerDate,
    this.markerLabel,
  });

  final List<DailyValueStruct> values;
  final double height;

  // "yyyy-MM-dd" date to draw a vertical marker line at (e.g. when an
  // intervention started) - used by the Patterns > Interventions before/
  // after comparison. Ignored when it falls outside the plotted range.
  final String? markerDate;
  final String? markerLabel;

  @override
  Widget build(BuildContext context) {
    final sorted = [...values]..sort((a, b) => a.day.compareTo(b.day));
    final totalDays = sorted.length;
    final theme = FlutterFlowTheme.of(context);

    if (totalDays == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet for this window.',
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < totalDays; i++)
        if (sorted[i].isTracked && !sorted[i].isMissing)
          FlSpot(i.toDouble(), sorted[i].value.clamp(0.0, 10.0)),
    ];

    if (spots.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Not enough tracked days yet for a trend line.',
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ),
      );
    }

    final markerIndex = markerDate == null
        ? -1
        : sorted.indexWhere((d) => d.date == markerDate);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 10,
          minX: 0,
          maxX: (totalDays - 1).toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final index = spot.x.round();
                if (index < 0 || index >= sorted.length) return null;
                final d = sorted[index];
                return LineTooltipItem(
                  '${d.date}\n${d.value.toStringAsFixed(0)}/10',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                reservedSize: 20.0,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 9.0),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22.0,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= totalDays) {
                    return const SizedBox.shrink();
                  }
                  var showEveryNth = 1;
                  if (totalDays > 60) {
                    showEveryNth = (totalDays / 5).round().clamp(1, 999);
                  } else if (totalDays > 14) {
                    showEveryNth = 7;
                  }
                  if (index % showEveryNth != 0) {
                    return const SizedBox.shrink();
                  }
                  final parts = sorted[index].date.split('-');
                  final label =
                      parts.length == 3 ? '${parts[2]}/${parts[1]}' : sorted[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white54, fontSize: 8.0),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              barWidth: 2.5,
              gradient: const LinearGradient(
                colors: [kMildGreen, kModerateTan, kSevereRed],
              ),
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kSevereRed.withValues(alpha: 0.32),
                    kMildGreen.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ],
          extraLinesData: markerIndex < 0
              ? null
              : ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: markerIndex.toDouble(),
                      color: Colors.redAccent,
                      strokeWidth: 1.5,
                      dashArray: [4, 3],
                      label: VerticalLineLabel(
                        show: markerLabel != null,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (_) => markerLabel ?? '',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
