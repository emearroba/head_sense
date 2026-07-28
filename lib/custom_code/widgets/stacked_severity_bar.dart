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

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!

class StackedSeverityBar extends StatelessWidget {
  const StackedSeverityBar({
    super.key,
    this.width,
    this.height,
    this.symptomFreeDays,
    this.mildDays,
    this.moderateDays,
    this.severeDays,
    this.missingDays,
    this.barHeight = 24,
  });

  final double? width;
  final double? height;
  final int? symptomFreeDays;
  final int? mildDays;
  final int? moderateDays;
  final int? severeDays;
  final int? missingDays;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    // Se filtran únicamente los días con un número mayor a 0
    final items = [
      _BarItem(symptomFreeDays ?? 0, const Color(0xFF2AD4C9)),
      _BarItem(mildDays ?? 0, const Color(0xFFFFC533)),
      _BarItem(moderateDays ?? 0, const Color(0xFFFF8A1C)),
      _BarItem(severeDays ?? 0, const Color(0xFFFF4B55)),
      _BarItem(missingDays ?? 0, const Color(0xFF8D8FD6)),
    ].where((item) => item.days > 0).toList();

    final double effectiveHeight = height ?? barHeight;

    return Container(
      width: width ?? double.infinity,
      height: effectiveHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveHeight / 2),
      ),
      child: items.isEmpty
          ? Container(
              height: effectiveHeight,
              color:
                  const Color(0xFF8D8FD6), // Color por defecto si no hay datos
            )
          : Row(
              children: items.map((item) {
                return Expanded(
                  flex: item.days,
                  child: Container(
                    height: effectiveHeight,
                    color: item.color,
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _BarItem {
  const _BarItem(this.days, this.color);

  final int days;
  final Color color;
}
