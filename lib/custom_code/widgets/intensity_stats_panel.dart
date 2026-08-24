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

// "Your Stats" subsection: totals, avg/min/max, and streaks derived from the
// same daily_values documents used by the calendar and the donut chart.
class IntensityStatsPanel extends StatelessWidget {
  const IntensityStatsPanel({
    super.key,
    required this.documents,
    this.width,
    this.height,
  });

  final List<DailyValuesRecord> documents;
  final double? width;
  final double? height;

  static const double tileSpacing = 8.0;
  static const int tilesPerRow = 4;

  @override
  Widget build(BuildContext context) {
    final sorted = [...documents]..sort((a, b) => a.date.compareTo(b.date));
    final tracked = sorted.where((d) => !d.isMissing).toList();

    double avg = 0;
    int minV = 0;
    int maxV = 0;
    if (tracked.isNotEmpty) {
      final values = tracked.map((d) => d.value).toList();
      avg = values.reduce((a, b) => a + b) / values.length;
      minV = values.reduce((a, b) => a < b ? a : b);
      maxV = values.reduce((a, b) => a > b ? a : b);
    }

    final int totalSymptomDays =
        tracked.where((d) => d.isMild || d.isModerate || d.isSevere).length;
    final int totalTrackedDays = tracked.length;

    // Streaks now live on the Results tab instead of here.
    final statTiles = <Widget>[
      _StatTile(label: 'Symptom days', value: '$totalSymptomDays'),
      _StatTile(label: 'Days tracked', value: '$totalTrackedDays'),
      _StatTile(label: 'Avg', value: avg.toStringAsFixed(1)),
      _StatTile(label: 'Min', value: '$minV'),
      _StatTile(label: 'Max', value: '$maxV'),
    ];

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : (width ?? 320.0);
          final double tileWidth =
              ((availableWidth - (tilesPerRow - 1) * tileSpacing) / tilesPerRow)
                  .clamp(60.0, 120.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: tileSpacing,
                runSpacing: tileSpacing,
                children: statTiles
                    .map((tile) => SizedBox(width: tileWidth, child: tile))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A33),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
