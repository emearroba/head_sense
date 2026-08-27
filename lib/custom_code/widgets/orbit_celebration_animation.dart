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

class OrbitCelebrationAnimation extends StatefulWidget {
  const OrbitCelebrationAnimation({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<OrbitCelebrationAnimation> createState() =>
      _OrbitCelebrationAnimationState();
}

class _OrbitCelebrationAnimationState extends State<OrbitCelebrationAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _introController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSize = widget.width ?? widget.height ?? 260.0;
    return SizedBox(
      width: widget.width ?? resolvedSize,
      height: widget.height ?? resolvedSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_introController, _driftController]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(
              widget.width ?? resolvedSize,
              widget.height ?? resolvedSize,
            ),
            painter: _OrbitPainter(
              intro: _introController.value,
              drift: _driftController.value,
            ),
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
    required this.revealStart,
    required this.revealEnd,
  });

  final double radiusFactor;
  final double strokeFactor;
  final double dotRadiusFactor;
  final List<double> dotTurns; // starting angle, in turns (0..1)
  final double speed; // signed turns-per-drift-cycle
  final double revealStart;
  final double revealEnd;
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter({required this.intro, required this.drift});

  final double intro;
  final double drift;

  static const _rings = [
    _Ring(
      radiusFactor: 0.22,
      strokeFactor: 0.014,
      dotRadiusFactor: 0.032,
      dotTurns: [0.62],
      speed: 1.3,
      revealStart: 0.0,
      revealEnd: 0.35,
    ),
    _Ring(
      radiusFactor: 0.40,
      strokeFactor: 0.014,
      dotRadiusFactor: 0.036,
      dotTurns: [0.18, 0.72],
      speed: -0.9,
      revealStart: 0.08,
      revealEnd: 0.45,
    ),
    _Ring(
      radiusFactor: 0.58,
      strokeFactor: 0.015,
      dotRadiusFactor: 0.040,
      dotTurns: [0.02, 0.60],
      speed: 0.6,
      revealStart: 0.16,
      revealEnd: 0.55,
    ),
    _Ring(
      radiusFactor: 0.76,
      strokeFactor: 0.016,
      dotRadiusFactor: 0.044,
      dotTurns: [0.30, 0.82],
      speed: -0.4,
      revealStart: 0.24,
      revealEnd: 0.65,
    ),
  ];

  static Color _wheelColor(double t) {
    final hue = (180 - 360 * (t % 1.0)) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.72, 1.0).toColor();
  }

  static double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

  static double _intervalEase(double t, double start, double end) {
    if (end <= start) return t >= end ? 1.0 : 0.0;
    final v = ((t - start) / (end - start)).clamp(0.0, 1.0);
    return _easeOutCubic(v);
  }

  static double _easeOutElastic(double x) {
    if (x <= 0) return 0.0;
    if (x >= 1) return 1.0;
    const c4 = (2 * math.pi) / 3;
    return math.pow(2, -10 * x).toDouble() * math.sin((x * 10 - 0.75) * c4) +
        1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final centerPop = _intervalEase(intro, 0.0, 0.32);
    if (centerPop > 0) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFB020).withOpacity(0.35 * centerPop)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(center, radius * 0.16 * centerPop, glowPaint);

      final corePaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFE066), Color(0xFFFF9F1C)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.11));
      canvas.drawCircle(center, radius * 0.11 * centerPop, corePaint);
    }

    for (final ring in _rings) {
      final reveal = _intervalEase(intro, ring.revealStart, ring.revealEnd);
      if (reveal <= 0) continue;

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

      canvas.drawArc(
        ringRect,
        -math.pi / 2 + driftAngle,
        2 * math.pi * reveal,
        false,
        ringPaint,
      );

      final dotPop = _intervalEase(
        intro,
        ring.revealEnd - 0.12,
        math.min(ring.revealEnd + 0.18, 1.0),
      );
      if (dotPop <= 0) continue;
      final dotScale = _easeOutElastic(dotPop).clamp(0.0, 1.15);

      for (final baseTurn in ring.dotTurns) {
        final angle = baseTurn * 2 * math.pi + driftAngle;
        final dotCenter =
            center + Offset(math.cos(angle), math.sin(angle)) * ringRadius;
        final dotColor = _wheelColor((angle / (2 * math.pi)) + 0.25);
        final dotRadius = radius * ring.dotRadiusFactor * dotScale;

        final dotGlow = Paint()
          ..color = dotColor.withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(dotCenter, dotRadius * 1.8, dotGlow);

        canvas.drawCircle(dotCenter, dotRadius, Paint()..color = dotColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.intro != intro || oldDelegate.drift != drift;
}
