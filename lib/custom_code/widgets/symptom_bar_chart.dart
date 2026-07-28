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

// Imports de dependencias externas
import 'package:fl_chart/fl_chart.dart';

class SymptomBarChart extends StatelessWidget {
  const SymptomBarChart({
    super.key,
    required this.documents,
    this.width,
    this.height,
  });

  final List<DailyValuesRecord> documents;
  final double? width;
  final double? height;

  // Color para Crystal Clear (0/10)
  static const String crystalColorHex = '#8ECBE8';

  Color _hexToColor(String hex) {
    if (hex.isEmpty) return Colors.grey;
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) cleaned = 'FF$cleaned';
    try {
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  static const _monthNames = [
    '',
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic'
  ];

  String _formatDateLabel(String rawDate, int totalDays) {
    if (rawDate.length < 10) return rawDate;
    final parts = rawDate.split('-');
    if (parts.length != 3) return rawDate;

    final monthInt = int.tryParse(parts[1]) ?? 0;

    if (totalDays > 120) {
      if (monthInt >= 1 && monthInt <= 12) {
        return _monthNames[monthInt];
      }
      return '${parts[1]}/${parts[0].substring(2)}';
    }

    return '${parts[2]}/${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ordenamos todos los documentos por fecha
    final allSorted = [...documents]..sort((a, b) => a.date.compareTo(b.date));

    // 2. FILTRO AUTOMÁTICO DE SEGURIDAD:
    List<DailyValuesRecord> sorted = allSorted;
    if (allSorted.length > 30 && allSorted.length <= 40) {
      sorted = allSorted.sublist(allSorted.length - 30);
    } else if (allSorted.length > 60 && allSorted.length <= 75) {
      sorted = allSorted.sublist(allSorted.length - 60);
    } else if (allSorted.length > 90 && allSorted.length <= 110) {
      sorted = allSorted.sublist(allSorted.length - 90);
    }

    final totalDays = sorted.length;
    final barGroups = <BarChartGroupData>[];

    // Grosor dinámico de la barra
    double barWidth = 10.0;
    if (totalDays > 180) {
      barWidth = 1.8;
    } else if (totalDays > 90) {
      barWidth = 3.0;
    } else if (totalDays > 30) {
      barWidth = 5.0;
    }

    for (var i = 0; i < totalDays; i++) {
      final doc = sorted[i];

      final bool isMissing = doc.isMissing || doc.value == null;
      final double rawValue = isMissing ? 0.0 : doc.value!.toDouble();

      double barHeight = 0.0;
      Color color = Colors.transparent;

      if (isMissing) {
        barHeight = 0.0;
        color = Colors.transparent;
      } else if (rawValue == 0) {
        barHeight = 0.35;
        color = _hexToColor(crystalColorHex);
      } else {
        barHeight = rawValue;
        if (doc.barColor.isNotEmpty) {
          color = _hexToColor(doc.barColor);
        } else {
          color = Colors.grey;
        }
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: barHeight,
              color: color,
              width: barWidth,
              borderRadius: BorderRadius.circular(totalDays > 90 ? 0.5 : 2),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 10,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.08),
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

                final doc = sorted[index];
                final parts = doc.date.split('-');
                String labelFecha = doc.date;
                if (parts.length == 3) {
                  labelFecha = '${parts[2]}/${parts[1]}/${parts[0]}';
                }

                final dayName =
                    doc.dayOfWeek.isNotEmpty ? '${doc.dayOfWeek} ' : '';
                final bool isMissing = doc.isMissing || doc.value == null;

                String valorTexto = 'Sin registro';
                if (!isMissing) {
                  valorTexto = doc.value == 0
                      ? '0/10 (Crystal Clear)'
                      : '${doc.value}/10';
                }

                return BarTooltipItem(
                  '$dayName$labelFecha\n$valorTexto',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                interval: 2,
                reservedSize: 24,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= totalDays) {
                    return const SizedBox.shrink();
                  }

                  int showEveryNth = 1;
                  if (totalDays > 250) {
                    showEveryNth = (totalDays / 6).round();
                  } else if (totalDays > 120) {
                    showEveryNth = (totalDays / 6).round();
                  } else if (totalDays > 60) {
                    showEveryNth = 14;
                  } else if (totalDays > 30) {
                    showEveryNth = 7;
                  } else if (totalDays > 14) {
                    showEveryNth = 4;
                  }

                  if (index % showEveryNth != 0) {
                    return const SizedBox.shrink();
                  }

                  final doc = sorted[index];
                  final dateFormatted = _formatDateLabel(doc.date, totalDays);

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateFormatted,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
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
