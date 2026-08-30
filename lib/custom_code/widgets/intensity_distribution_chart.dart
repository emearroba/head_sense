// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'symptom_analytics.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// How many tracked days landed on each 0-10 intensity value, as 11 bars
// colored across the same crystal-clear -> severe rainbow used everywhere
// else in the app (see symptom_analytics.dart's intensityColorForValue).
class IntensityDistributionChart extends StatelessWidget {
  const IntensityDistributionChart({
    super.key,
    required this.histogram,
    this.height = 120.0,
  });

  final Map<int, int> histogram;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final maxCount =
        histogram.values.fold<int>(0, (best, v) => v > best ? v : best);
    final safeMax = maxCount <= 0 ? 1 : maxCount;
    final maxBarHeight = height - 34.0;

    if (maxCount <= 0) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No tracked days yet in this window.',
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(11, (value) {
          final count = histogram[value] ?? 0;
          final color = intensityColorForValue(value.toDouble());
          final barHeight =
              count == 0 ? 2.0 : (count / safeMax) * maxBarHeight;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 14.0,
                    child: count > 0
                        ? Center(
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                color: theme.secondaryText,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    height: barHeight.clamp(2.0, maxBarHeight),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w500,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
