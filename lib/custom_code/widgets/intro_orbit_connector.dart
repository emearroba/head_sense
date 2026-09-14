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

// Used by WelcomeIntroWidget: one dot per intro slide, arranged around a
// ring. As the user pages forward (activeIndex increases), the dot for the
// new slide pops in and a line grows from the previous dot to it - so by the
// last slide ("Discover patterns") the whole thing reads as a connected
// network, echoing what the app itself does with the user's symptom data.
// Paging backward instantly retracts to the target index (no reverse
// animation) since that's not the story being told.
class IntroOrbitConnector extends StatefulWidget {
  const IntroOrbitConnector({
    super.key,
    required this.activeIndex,
    required this.count,
    this.size,
  });

  final int activeIndex;
  final int count;
  final double? size;

  @override
  State<IntroOrbitConnector> createState() => _IntroOrbitConnectorState();
}

class _IntroOrbitConnectorState extends State<IntroOrbitConnector>
    with TickerProviderStateMixin {
  late final AnimationController _driftController;
  late final AnimationController _stepController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.activeIndex;
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward(from: 1.0);
  }

  @override
  void didUpdateWidget(covariant IntroOrbitConnector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != _lastIndex) {
      final movedForwardOneStep = widget.activeIndex == _lastIndex + 1;
      _lastIndex = widget.activeIndex;
      if (movedForwardOneStep) {
        _stepController.forward(from: 0.0);
      } else {
        // Jumped more than one slide (e.g. Skip, or paging backward) -
        // just settle fully connected up to the target, no animation.
        _stepController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _driftController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSize = widget.size ?? 200.0;
    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_driftController, _stepController]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(resolvedSize, resolvedSize),
            painter: _OrbitConnectorPainter(
              activeIndex: widget.activeIndex,
              count: widget.count,
              stepProgress: _stepController.value,
              drift: _driftController.value,
            ),
          );
        },
      ),
    );
  }
}

class _OrbitConnectorPainter extends CustomPainter {
  _OrbitConnectorPainter({
    required this.activeIndex,
    required this.count,
    required this.stepProgress,
    required this.drift,
  });

  final int activeIndex;
  final int count;
  final double stepProgress; // 0..1 reveal of the newest connection
  final double drift;

  static double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  static double _easeOutBack(double x) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final p = x - 1;
    return 1 + c3 * p * p * p + c1 * p * p;
  }

  static Color _wheelColor(double t) {
    final hue = (200 - 360 * (t % 1.0)) % 360;
    return HSVColor.fromAHSV(1.0, hue < 0 ? hue + 360 : hue, 0.72, 1.0)
        .toColor();
  }

  Offset _dotPosition(int i, Offset center, double ringRadius) {
    // Slow continuous drift keeps the ring feeling alive between steps,
    // matching OrbitLogo/OrbitCelebrationAnimation elsewhere in the app.
    final angle =
        (i / count) * 2 * math.pi - math.pi / 2 + drift * 2 * math.pi * 0.06;
    return center + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (count <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final ringRadius = radius * 0.72;

    final positions = [
      for (var i = 0; i < count; i++) _dotPosition(i, center, ringRadius),
    ];

    // Faint guide ring so unlit dots read as "part of the shape" rather
    // than floating randomly.
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, ringRadius, guidePaint);

    // Fully-connected segments (0->1->2->...->activeIndex-1) plus the
    // newest one animating in from activeIndex-1 -> activeIndex.
    for (var i = 0; i < activeIndex && i < count - 1; i++) {
      final isNewest = i == activeIndex - 1;
      final segmentProgress = isNewest ? _easeOutCubic(stepProgress) : 1.0;
      if (segmentProgress <= 0) continue;
      final from = positions[i];
      final to = Offset.lerp(positions[i], positions[i + 1], segmentProgress)!;
      final lineColor = _wheelColor(i / count);
      final linePaint = Paint()
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            lineColor.withOpacity(0.85),
            _wheelColor((i + 1) / count).withOpacity(0.85),
          ],
        ).createShader(Rect.fromPoints(from, to));
      canvas.drawLine(from, to, linePaint);
    }

    for (var i = 0; i < count; i++) {
      final lit = i <= activeIndex;
      final justArrived = i == activeIndex;
      final popScale =
          justArrived ? _easeOutBack(stepProgress).clamp(0.0, 1.25) : 1.0;
      final dotCenter = positions[i];
      final baseRadius = radius * 0.075;
      final dotColor = _wheelColor(i / count);

      if (lit) {
        final glowPaint = Paint()
          ..color = dotColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(dotCenter, baseRadius * 1.9 * popScale, glowPaint);
        canvas.drawCircle(
            dotCenter, baseRadius * popScale, Paint()..color = dotColor);
      } else {
        final dimPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = Colors.white.withOpacity(0.22);
        canvas.drawCircle(dotCenter, baseRadius * 0.8, dimPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitConnectorPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.stepProgress != stepProgress ||
      oldDelegate.drift != drift;
}
