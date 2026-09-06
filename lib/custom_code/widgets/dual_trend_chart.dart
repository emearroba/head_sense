// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

// Two symptom trends overlaid on one chart, for the Connections tab's
// strongest-connection card. Each series is independently min-max
// normalized to 0-1 before plotting, since the two metrics being compared
// can live on different scales (a 0-10 intensity vs. a boolean, say) -
// that's also why the axis just says "High"/"Low" rather than real numbers.
class DualTrendChart extends StatelessWidget {
  const DualTrendChart({
    super.key,
    required this.aValues,
    required this.aColor,
    required this.bValues,
    required this.bColor,
    this.height = 140.0,
  });

  final List<DailyValueStruct> aValues;
  final Color aColor;
  final List<DailyValueStruct> bValues;
  final Color bColor;
  final double height;

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final aByDate = {
      for (final d in aValues.where((d) => d.isTracked && !d.isMissing))
        d.date: d.value,
    };
    final bByDate = {
      for (final d in bValues.where((d) => d.isTracked && !d.isMissing))
        d.date: d.value,
    };
    final dates = {...aByDate.keys, ...bByDate.keys}.toList()..sort();

    if (dates.length < 2 || aByDate.isEmpty || bByDate.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Not enough overlapping days yet for a trend line.',
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ),
      );
    }

    double normalize(double value, double min, double max) =>
        max > min ? (value - min) / (max - min) : 0.5;

    final aMin = aByDate.values.reduce((x, y) => x < y ? x : y);
    final aMax = aByDate.values.reduce((x, y) => x > y ? x : y);
    final bMin = bByDate.values.reduce((x, y) => x < y ? x : y);
    final bMax = bByDate.values.reduce((x, y) => x > y ? x : y);

    final aSpots = <FlSpot>[];
    final bSpots = <FlSpot>[];
    for (var i = 0; i < dates.length; i++) {
      final av = aByDate[dates[i]];
      if (av != null) {
        aSpots.add(FlSpot(i.toDouble(), normalize(av, aMin, aMax)));
      }
      final bv = bByDate[dates[i]];
      if (bv != null) {
        bSpots.add(FlSpot(i.toDouble(), normalize(bv, bMin, bMax)));
      }
    }

    Widget dateLabel(int index) {
      final parts = dates[index].split('-');
      final label = parts.length == 3
          ? '${_monthNames[(int.parse(parts[1]) - 1).clamp(0, 11)]} ${int.parse(parts[2])}'
          : dates[index];
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9.0)),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('High', style: TextStyle(fontSize: 9.0, color: theme.secondaryText)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text('Low', style: TextStyle(fontSize: 9.0, color: theme.secondaryText)),
                ),
              ],
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1,
                minX: 0,
                maxX: (dates.length - 1).toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20.0,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index != 0 && index != dates.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return dateLabel(index);
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: aSpots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    color: aColor,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: bSpots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    color: bColor,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
