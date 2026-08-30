// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'symptom_analytics.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

// Compact trend bar chart for the Results tab, driven directly by a
// DashboardRecord's embedded dailyValues (no extra Firestore query needed,
// unlike the Dashboard tab's SymptomBarChart which reads the daily_values
// subcollection). Deliberately smaller/simpler than SymptomBarChart - this
// lives inside a Results period card, not a full-page chart.
class SymptomTrendChart extends StatelessWidget {
  const SymptomTrendChart({
    super.key,
    required this.values,
    this.height = 150.0,
  });

  final List<DailyValueStruct> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final sorted = [...values]..sort((a, b) => a.day.compareTo(b.day));
    final totalDays = sorted.length;

    if (totalDays == 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data yet for this window.',
            style: FlutterFlowTheme.of(context)
                .labelSmall
                .override(color: FlutterFlowTheme.of(context).secondaryText),
          ),
        ),
      );
    }

    double barWidth = 10.0;
    if (totalDays > 180) {
      barWidth = 1.8;
    } else if (totalDays > 90) {
      barWidth = 3.0;
    } else if (totalDays > 30) {
      barWidth = 5.0;
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < totalDays; i++) {
      final d = sorted[i];
      final isMissing = d.isMissing || !d.isTracked;
      final barHeight = isMissing ? 0.0 : (d.value <= 0 ? 0.35 : d.value);
      final color = isMissing
          ? Colors.transparent
          : hexToColor(d.barColor, fallback: intensityColorForValue(d.value));

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: barHeight,
              color: color,
              width: barWidth,
              borderRadius: BorderRadius.circular(totalDays > 90 ? 0.5 : 2.0),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 10,
          alignment: BarChartAlignment.spaceAround,
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
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x.toInt();
                if (index < 0 || index >= sorted.length) return null;
                final d = sorted[index];
                final label = (d.isMissing || !d.isTracked)
                    ? 'No entry'
                    : '${d.value.toStringAsFixed(0)}/10';
                return BarTooltipItem(
                  '${d.date}\n$label',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
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
          barGroups: barGroups,
        ),
      ),
    );
  }
}
