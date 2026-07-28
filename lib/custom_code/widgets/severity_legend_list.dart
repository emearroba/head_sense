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

import 'dart:math' as math;

class SeverityLegendList extends StatelessWidget {
  const SeverityLegendList({
    super.key,
    this.width,
    this.height,
    this.symptomFreeDays,
    this.mildDays,
    this.moderateDays,
    this.severeDays,
  });

  final double? width;
  final double? height;

  final int? symptomFreeDays;
  final int? mildDays;
  final int? moderateDays;
  final int? severeDays;

  int _percent(int days, int total) {
    if (total <= 0) return 0;
    return ((days / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = (symptomFreeDays ?? 0) +
        (mildDays ?? 0) +
        (moderateDays ?? 0) +
        (severeDays ?? 0);

    final totalSymptomDays =
        (mildDays ?? 0) + (moderateDays ?? 0) + (severeDays ?? 0);

    final rows = [
      _LegendItem('Severe', severeDays ?? 0, const Color(0xFFFF4B55), false),
      _LegendItem(
          'Moderate', moderateDays ?? 0, const Color(0xFFFF8A1C), false),
      _LegendItem('Mild', mildDays ?? 0, const Color(0xFFFFC533), false),
      _LegendItem(
        'Crystal Clear (symptom-free)',
        symptomFreeDays ?? 0,
        const Color(0xFF2AD4C9),
        true,
      ),
    ];

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...rows.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  item.isDiamond
                      ? Transform.rotate(
                          angle: math.pi / 4,
                          child: Container(
                            width: 10,
                            height: 10,
                            color: item.color,
                          ),
                        )
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Color(0xFFEAF2F7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${item.days} days',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFEAF2F7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${_percent(item.days, totalDays)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFEAF2F7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total symptom days',
                  style: TextStyle(
                    color: Color(0xFFEAF2F7),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$totalSymptomDays',
                style: const TextStyle(
                  color: Color(0xFFFFC533),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total days',
                  style: TextStyle(
                    color: Color(0xFFB8C2CC),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$totalDays',
                style: const TextStyle(
                  color: Color(0xFFB8C2CC),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  const _LegendItem(this.label, this.days, this.color, this.isDiamond);

  final String label;
  final int days;
  final Color color;
  final bool isDiamond;
}
