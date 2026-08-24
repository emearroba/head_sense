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

// Calendar-grid heatmap: weekday columns, one row per week, day-of-month
// numbers in each cell (e.g. "13" under the "Aug" row label reads as "Aug 13")
// so a specific date is easy to spot when scrolling through several months.
class SeverityCalendarPanel extends StatelessWidget {
  const SeverityCalendarPanel({
    super.key,
    required this.documents,
    this.width,
    this.height,
  });

  final List<DailyValuesRecord> documents;
  final double? width;
  final double? height;

  // Shared with ClinicalDonutChart so the palette matches.
  static const Color severeColor = Color(0xFFBD3A31);
  static const Color moderateColor = Color(0xFFCB9A61);
  static const Color mildColor = Color(0xFF7ABA5A);
  static const Color crystalColor = Color(0xFF4FA8B2);
  static const Color missingColor = Color(0xFF2C3B44);
  static const double spacing = 3.0;
  static const double headerHeight = 16.0;
  static const double monthColWidth = 30.0;

  static const _monthNames = [
    '',
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

  Color _colorForValue(int value, bool isMissing) {
    if (isMissing) return missingColor;
    if (value == 0) return crystalColor;
    if (value <= 3) return mildColor;
    if (value <= 6) return moderateColor;
    return severeColor;
  }

  // The record's own "day" field is a sequential counter over the tracked
  // period (1..365), not the calendar day-of-month, so parse it from date.
  int _dayOfMonth(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return 0;
    return int.tryParse(parts[2]) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...documents]..sort((a, b) => a.date.compareTo(b.date));

    // Bucket into calendar weeks (Mon..Sun columns) using the server-computed
    // dayOfWeekIndex (0=Sun..6=Sat, JS convention), remapped so Monday is the
    // first column and Sunday the last, and a new row starts on each Monday.
    final weeks = <List<DailyValuesRecord?>>[];
    List<DailyValuesRecord?> currentWeek = List.filled(7, null);
    int? lastDow;
    final columnLabels = List<String>.filled(7, '');
    for (final doc in sorted) {
      final rawDow = doc.dayOfWeekIndex.clamp(0, 6);
      final dow = (rawDow + 6) % 7;
      if (lastDow != null && dow <= lastDow) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
      currentWeek[dow] = doc;
      if (columnLabels[dow].isEmpty && doc.dayOfWeek.isNotEmpty) {
        columnLabels[dow] = doc.dayOfWeek.substring(0, 1).toUpperCase();
      }
      lastDow = dow;
    }
    if (sorted.isNotEmpty) weeks.add(currentWeek);

    // Label the first week of every new month so a date like "Aug 13" is
    // easy to locate when scrolling through several months.
    final weekMonthLabel = List<String>.filled(weeks.length, '');
    int? lastLabeledMonth;
    int? lastLabeledYear;
    for (var i = 0; i < weeks.length; i++) {
      final firstDoc = weeks[i].firstWhere(
        (d) => d != null,
        orElse: () => null,
      );
      if (firstDoc == null) continue;
      final parts = firstDoc.date.split('-');
      if (parts.length != 3) continue;
      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 0;
      if (month != lastLabeledMonth || year != lastLabeledYear) {
        weekMonthLabel[i] =
            (month >= 1 && month <= 12) ? _monthNames[month] : '';
        lastLabeledMonth = month;
        lastLabeledYear = year;
      }
    }

    // Most-recent week first, top-anchored, so it renders right under the
    // weekday header instead of floating at the bottom of the scroll area.
    final orderedWeeks = weeks.reversed.toList();
    final orderedWeekMonthLabel = weekMonthLabel.reversed.toList();

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (width ?? 320.0);
          final double cellSize =
              ((availableWidth - monthColWidth - 6 * spacing) / 7)
                  .clamp(20.0, 36.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: monthColWidth),
                  ...List.generate(7, (col) {
                    return Padding(
                      padding: const EdgeInsets.only(right: spacing),
                      child: SizedBox(
                        width: cellSize,
                        height: headerHeight,
                        child: Center(
                          child: Text(
                            columnLabels[col],
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: spacing),
              Expanded(
                child: ListView.builder(
                  itemCount: orderedWeeks.length,
                  itemBuilder: (context, weekIndex) {
                    final week = orderedWeeks[weekIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: spacing),
                      child: Row(
                        children: [
                          SizedBox(
                            width: monthColWidth,
                            height: cellSize,
                            child: orderedWeekMonthLabel[weekIndex].isEmpty
                                ? null
                                : Center(
                                    child: Text(
                                      orderedWeekMonthLabel[weekIndex],
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                          ...List.generate(7, (col) {
                            final doc = week[col];
                            final color = doc == null
                                ? Colors.transparent
                                : _colorForValue(doc.value, doc.isMissing);
                            return Padding(
                              padding: const EdgeInsets.only(right: spacing),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: doc == null
                                    ? null
                                    : Text(
                                        '${_dayOfMonth(doc.date)}',
                                        style: TextStyle(
                                          color: doc.isMissing
                                              ? Colors.white38
                                              : Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
