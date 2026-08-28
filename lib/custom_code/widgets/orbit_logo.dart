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

class OrbitLogo extends StatefulWidget {
  const OrbitLogo({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<OrbitLogo> createState() => _OrbitLogoState();
}

class _OrbitLogoState extends State<OrbitLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSize = widget.width ?? widget.height ?? 160.0;
    return SizedBox(
      width: widget.width ?? resolvedSize,
      height: widget.height ?? resolvedSize,
      child: AnimatedBuilder(
        animation: _driftController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(
              widget.width ?? resolvedSize,
              widget.height ?? resolvedSize,
            ),
            painter: _OrbitLogoPainter(drift: _driftController.value),
          );
        },
      ),
    );
  }
}

class _Ring {
  const _Ring({
    required this.radiusFactor,
    required this.strokeFactor,
    required this.dotRadiusFactor,
    required this.dotTurns,
    required this.speed,
  });

  final double radiusFactor;
  final double strokeFactor;
  final double dotRadiusFactor;
  final List<double> dotTurns; // starting angle, in turns (0..1)
  final double speed; // signed turns-per-drift-cycle
}

class _OrbitLogoPainter extends CustomPainter {
  _OrbitLogoPainter({required this.drift});

  final double drift;

  static const _rings = [
    _Ring(
      radiusFactor: 0.22,
      strokeFactor: 0.014,
      dotRadiusFactor: 0.032,
      dotTurns: [0.62],
      speed: 1.3,
    ),
    _Ring(
      radiusFactor: 0.40,
      strokeFactor: 0.014,
      dotRadiusFactor: 0.036,
      dotTurns: [0.18, 0.72],
      speed: -0.9,
    ),
    _Ring(
      radiusFactor: 0.58,
      strokeFactor: 0.015,
      dotRadiusFactor: 0.040,
      dotTurns: [0.02, 0.60],
      speed: 0.6,
    ),
    _Ring(
      radiusFactor: 0.76,
      strokeFactor: 0.016,
      dotRadiusFactor: 0.044,
      dotTurns: [0.30, 0.82],
      speed: -0.4,
    ),
  ];

  static Color _wheelColor(double t) {
    final hue = (180 - 360 * (t % 1.0)) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.72, 1.0).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Soft white core, matching the reference mark instead of the amber sun.
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, radius * 0.16, glowPaint);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, Colors.white.withOpacity(0.85)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.11));
    canvas.drawCircle(center, radius * 0.11, corePaint);

    for (final ring in _rings) {
      final ringRadius = radius * ring.radiusFactor;
      final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
      final driftAngle = drift * 2 * math.pi * ring.speed;

      final gradient = SweepGradient(
        colors: [for (var i = 0; i <= 12; i++) _wheelColor(i / 12)],
        transform: GradientRotation(-math.pi / 2 + driftAngle),
      );

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * ring.strokeFactor
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(ringRect);

      canvas.drawCircle(center, ringRadius, ringPaint);

      for (final baseTurn in ring.dotTurns) {
        final angle = baseTurn * 2 * math.pi + driftAngle;
        final dotCenter =
            center + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
        final dotColor = _wheelColor((angle / (2 * math.pi)) + 0.25);
        final dotRadius = radius * ring.dotRadiusFactor;

        final dotGlow = Paint()
          ..color = dotColor.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(dotCenter, dotRadius * 1.8, dotGlow);

        canvas.drawCircle(dotCenter, dotRadius, Paint()..color = dotColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitLogoPainter oldDelegate) =>
      oldDelegate.drift != drift;
}
