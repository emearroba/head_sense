// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

class ClinicalDonutChart extends StatefulWidget {
  const ClinicalDonutChart({
    super.key,
    this.width,
    this.height,
    required this.crystalDays,
    required this.mildDays,
    required this.moderateDays,
    required this.severeDays,
    required this.missingDays,
    required this.painkillerDays,
    required this.periodDays,
    required this.metricLabel,
  });

  final double? width;
  final double? height;
  final int crystalDays;
  final int mildDays;
  final int moderateDays;
  final int severeDays;
  final int missingDays;
  final int painkillerDays;
  final int periodDays;
  final String metricLabel;

  @override
  State<ClinicalDonutChart> createState() => _ClinicalDonutChartState();
}

class _ClinicalDonutChartState extends State<ClinicalDonutChart> {
  static const Color crystalColor = Color(0xFF4FA8B2);
  static const Color mildColor = Color(0xFF7ABA5A);
  static const Color moderateColor = Color(0xFFCB9A61);
  static const Color severeColor = Color(0xFFBD3A31);
  static const Color missingColor = Color(0xFF7E8AA7);
  static const Color painkillerColor = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    final int totalHeadacheDays =
        widget.mildDays + widget.moderateDays + widget.severeDays;
    final int totalDays = widget.periodDays > 0 ? widget.periodDays : 30;
    final int trackedDays = widget.crystalDays + totalHeadacheDays;

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 340,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (totalHeadacheDays >= (totalDays / 2))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    border: Border.all(color: Colors.redAccent, width: 1.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '≥${(totalDays / 2).round()}d High Frequency',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          startDegreeOffset: 270,
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _generateInnerRingSections(),
                        ),
                      ),
                      PieChart(
                        PieChartData(
                          startDegreeOffset: 270,
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 0,
                          centerSpaceRadius: 64,
                          sections: _generateOuterPainkillerRing(totalDays),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalHeadacheDays/$totalDays',
                            style: TextStyle(
                              color: totalHeadacheDays >= (totalDays / 2)
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Tracked Days',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                          'Severe (7-10)', widget.severeDays, severeColor,
                          total: trackedDays),
                      _buildLegendItem(
                          'Moderate (4-6)', widget.moderateDays, moderateColor,
                          total: trackedDays),
                      _buildLegendItem(
                          'Mild (1-3)', widget.mildDays, mildColor,
                          total: trackedDays),
                      _buildLegendItem(
                          'Crystal Clear', widget.crystalDays, crystalColor,
                          total: trackedDays),
                      _buildLegendItem(
                          'Missing Days', widget.missingDays, missingColor,
                          total: totalDays),
                      const Divider(color: Colors.white24, height: 14),
                      _buildLegendItem('Painkillers Used',
                          widget.painkillerDays, painkillerColor,
                          isOuter: true, total: trackedDays),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Percentages are based on the days you tracked (missing days excluded).',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generateInnerRingSections() {
    final List<PieChartSectionData> sections = [];
    const double innerRadius = 24.0;

    if (widget.severeDays > 0) {
      sections.add(
        PieChartSectionData(
          color: severeColor,
          value: widget.severeDays.toDouble(),
          title: '${widget.severeDays}',
          radius: innerRadius,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (widget.moderateDays > 0) {
      sections.add(
        PieChartSectionData(
          color: moderateColor,
          value: widget.moderateDays.toDouble(),
          title: '${widget.moderateDays}',
          radius: innerRadius,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (widget.mildDays > 0) {
      sections.add(
        PieChartSectionData(
          color: mildColor,
          value: widget.mildDays.toDouble(),
          title: '${widget.mildDays}',
          radius: innerRadius,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (widget.crystalDays > 0) {
      sections.add(
        PieChartSectionData(
          color: crystalColor,
          value: widget.crystalDays.toDouble(),
          title: '${widget.crystalDays}',
          radius: innerRadius,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (widget.missingDays > 0) {
      sections.add(
        PieChartSectionData(
          color: missingColor,
          value: widget.missingDays.toDouble(),
          title: '${widget.missingDays}',
          radius: innerRadius,
          titleStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return sections;
  }

  List<PieChartSectionData> _generateOuterPainkillerRing(int totalDays) {
    final List<PieChartSectionData> sections = [];
    const double outerRadius = 8.0;
    final int painkillerCount = widget.painkillerDays.clamp(0, totalDays);
    final int remainingDays = totalDays - painkillerCount;

    if (painkillerCount > 0) {
      sections.add(
        PieChartSectionData(
          color: painkillerColor,
          value: painkillerCount.toDouble(),
          radius: outerRadius,
          showTitle: false,
        ),
      );
    }

    if (remainingDays > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.white.withOpacity(0.04),
          value: remainingDays.toDouble(),
          radius: outerRadius,
          showTitle: false,
        ),
      );
    }

    return sections;
  }

  int _percent(int days, int total) {
    if (total <= 0) return 0;
    return ((days / total) * 100).round();
  }

  Widget _buildLegendItem(String label, int value, Color color,
      {bool isOuter = false, int? total}) {
    final String trailing =
        total != null ? '$value d · ${_percent(value, total)}%' : '$value d';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: isOuter ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isOuter ? BorderRadius.circular(2) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isOuter ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isOuter ? FontWeight.bold : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
