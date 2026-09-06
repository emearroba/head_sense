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

// Renders the right input for a diary question based on the metric's
// answerType, replacing what used to be 11 duplicated 0-10 button widgets
// hardcoded in daily_diary_page_widget.dart (that version couldn't handle
// boolean predictors like "on period?" or open-ended ones like hours slept).
class MetricAnswerInput extends StatefulWidget {
  const MetricAnswerInput({
    super.key,
    required this.answerType,
    required this.scaleMin,
    required this.scaleMax,
    required this.step,
    required this.unit,
    required this.onSubmit,
    this.metricKey = '',
    this.initialValue,
  });

  // 'boolean' | 'numeric' | 'time' | anything else falls back to the 0-10
  // style scale.
  final String answerType;
  final int scaleMin;
  final int scaleMax;
  final double step;
  final String unit;
  final Future<void> Function(double value) onSubmit;
  // Identifies which metric this is for, so a handful of questions can get
  // bespoke treatment (water intake's L stepper, the Bristol stool icons)
  // without every scale/numeric question needing its own widget.
  final String metricKey;
  // Previously-submitted value for this question in the current diary
  // entry, if any - lets the "back" button show what was already answered.
  final double? initialValue;

  @override
  State<MetricAnswerInput> createState() => _MetricAnswerInputState();
}

class _MetricAnswerInputState extends State<MetricAnswerInput> {
  bool _submitting = false;
  double? _numericValue;
  // The value the user just tapped in the scale list, kept selected/lit up
  // for a beat before onSubmit fires, so the tap always reads as "confirmed,
  // moving to the next symptom" rather than an instant, jarring swap.
  double? _pendingScaleValue;

  // Index 0 = highest value (10), matching the original hand-tuned palette.
  static const _scaleLabels = [
    'Maximum level',
    'Extremely High',
    'Very High',
    'High',
    'Moderately High',
    'Moderate',
    'Mildly Present',
    'Low',
    'Very Low',
    'Minimal',
    'Crystal clear',
  ];

  // Same four semantic anchors as the Dashboard's intensity legend
  // (Severe / Moderate / Mild / Crystal clear), interpolated across the
  // scale so every intensity screen in the app reads as one palette.
  static const _severeRed = Color(0xFFBD3A31);
  static const _moderateTan = Color(0xFFCB9A61);
  static const _mildGreen = Color(0xFF7ABA5A);
  static const _crystalBlue = Color(0xFFAEE0EA);

  // t: 0 = highest intensity -> 1 = lowest ("Crystal clear").
  static Color _colorForT(double t) {
    if (t <= 1 / 3) return Color.lerp(_severeRed, _moderateTan, t / (1 / 3))!;
    if (t <= 2 / 3) {
      return Color.lerp(_moderateTan, _mildGreen, (t - 1 / 3) / (1 / 3))!;
    }
    return Color.lerp(_mildGreen, _crystalBlue, (t - 2 / 3) / (1 / 3))!;
  }

  Future<void> _handleSubmit(double value) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(value);
    } catch (e) {
      _showSubmitError();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Scale rows get a beat of "lit up + checked" feedback before advancing,
  // instead of submitting (and swapping the whole question out) instantly.
  Future<void> _handleScaleTap(double value) async {
    if (_submitting) return;
    setState(() {
      _pendingScaleValue = value;
      _submitting = true;
    });
    try {
      await Future.delayed(const Duration(milliseconds: 260));
      await widget.onSubmit(value);
    } catch (e) {
      _showSubmitError();
    } finally {
      // Without this in a `finally`, any error from onSubmit (e.g. a
      // permission-denied re-answering a question) left the row stuck
      // showing "confirming" forever with no way to retry.
      if (mounted) {
        setState(() {
          _submitting = false;
          _pendingScaleValue = null;
        });
      }
    }
  }

  void _showSubmitError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't save your answer. Please try again."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.answerType) {
      case 'boolean':
        return _buildBoolean(context);
      case 'numeric':
        return _buildNumeric(context);
      case 'time':
        return _buildTime(context);
      default:
        return _buildScale(context);
    }
  }

  Widget _buildBoolean(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _boolButton(context, label: 'No', value: 0.0)),
        const SizedBox(width: 16),
        Expanded(child: _boolButton(context, label: 'Yes', value: 1.0)),
      ],
    );
  }

  Widget _boolButton(BuildContext context,
      {required String label, required double value}) {
    return ElevatedButton(
      onPressed: _submitting ? null : () => _handleSubmit(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: value == 1.0
            ? FlutterFlowTheme.of(context).primary
            : const Color(0xFF1F3A45),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Water intake is tracked in half-litre increments starting from a 2L
  // default, rather than the generic 1-glass-at-a-time stepper.
  bool get _isWaterIntake => widget.metricKey == 'water_intake';
  bool get _isHoursSlept => widget.metricKey == 'hours_slept';
  double get _effectiveStep => _isWaterIntake ? 0.5 : widget.step;
  double get _effectiveMin =>
      _isWaterIntake ? 0.0 : widget.scaleMin.toDouble();
  double get _effectiveMax =>
      _isWaterIntake ? 6.0 : widget.scaleMax.toDouble();
  String get _effectiveUnit => _isWaterIntake ? 'L' : widget.unit;

  Widget _buildNumeric(BuildContext context) {
    _numericValue ??= widget.initialValue ??
        (_isWaterIntake
            ? 2.0
            : _isHoursSlept
                ? 8.0
                : widget.scaleMin.toDouble());
    final display = _effectiveStep == _effectiveStep.roundToDouble()
        ? _numericValue!.toStringAsFixed(0)
        : _numericValue!.toStringAsFixed(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => setState(() {
                _numericValue = (_numericValue! - _effectiveStep)
                    .clamp(_effectiveMin, _effectiveMax);
              }),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              iconSize: 32,
            ),
            SizedBox(
              width: 120,
              child: Text(
                _effectiveUnit.isEmpty ? display : '$display $_effectiveUnit',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() {
                _numericValue = (_numericValue! + _effectiveStep)
                    .clamp(_effectiveMin, _effectiveMax);
              }),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _submitting ? null : () => _handleSubmit(_numericValue!),
          style: ElevatedButton.styleFrom(
            backgroundColor: FlutterFlowTheme.of(context).primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // Stored as minutes-since-midnight (0-1439) in valueNumber.
  Widget _buildTime(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: _submitting
            ? null
            : () async {
                final now = TimeOfDay.now();
                final picked = await showTimePicker(
                  context: context,
                  initialTime: now,
                );
                if (picked == null) return;
                final minutes = (picked.hour * 60 + picked.minute)
                    .clamp(widget.scaleMin, widget.scaleMax);
                await _handleSubmit(minutes.toDouble());
              },
        icon: const Icon(Icons.access_time),
        label: const Text('Select time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Small pictorial stand-in for each Bristol Stool Chart type (1 = hard
  // lumps, 7 = watery), shown next to the label only for stool_quality.
  static const _bristolIcons = {
    1: '🥜',
    2: '🌰',
    3: '🌭',
    4: '🍌',
    5: '☁️',
    6: '🍦',
    7: '💧',
  };

  Widget _buildScale(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final levels = widget.scaleMax - widget.scaleMin + 1;
    final useNamedPalette = widget.scaleMin == 0 && widget.scaleMax == 10;
    final isBristol = widget.metricKey == 'stool_quality';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(levels, (i) {
        final value = widget.scaleMax - i; // descending: 10 at top, 0 at bottom
        final t = levels <= 1 ? 0.0 : i / (levels - 1);
        final label = useNamedPalette ? _scaleLabels[i] : '$value';
        final color = _colorForT(t);
        final isConfirming = _pendingScaleValue == value.toDouble();
        final isSelected = _pendingScaleValue != null
            ? isConfirming
            : widget.initialValue == value.toDouble();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _IntensityRow(
            theme: theme,
            value: value,
            label: label,
            color: color,
            isSelected: isSelected,
            isConfirming: isConfirming,
            enabled: !_submitting,
            leading: (isBristol && _bristolIcons.containsKey(value))
                ? Text(_bristolIcons[value]!, style: const TextStyle(fontSize: 16))
                : null,
            onTap: () => _handleScaleTap(value.toDouble()),
          ),
        );
      }),
    );
  }
}

// A single intensity row: presses down slightly on touch (like an iOS
// button), ripples a soft "bubble" of its own color from the tap point, and
// lights up its background/border/glow when selected - with a brief
// checkmark swap while a tap is being confirmed, so it's unmistakable the
// app registered the answer and is moving to the next symptom.
class _IntensityRow extends StatefulWidget {
  const _IntensityRow({
    required this.theme,
    required this.value,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isConfirming,
    required this.enabled,
    required this.onTap,
    this.leading,
  });

  final FlutterFlowTheme theme;
  final int value;
  final String label;
  final Color color;
  final bool isSelected;
  final bool isConfirming;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  State<_IntensityRow> createState() => _IntensityRowState();
}

class _IntensityRowState extends State<_IntensityRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (!widget.enabled) return;
    if (pressed) {
      _pressController.forward();
    } else {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final color = widget.color;
    final isSelected = widget.isSelected;

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) => Transform.scale(
        scale: 1.0 - (_pressController.value * 0.03),
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          splashColor: color.withOpacity(0.30),
          highlightColor: color.withOpacity(0.12),
          splashFactory: InkRipple.splashFactory,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(widget.isConfirming ? 0.22 : 0.14)
                  : theme.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color.withOpacity(0.8) : theme.alternate,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(widget.isConfirming ? 0.4 : 0.22),
                        blurRadius: widget.isConfirming ? 18 : 12,
                        spreadRadius: widget.isConfirming ? 1 : 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${widget.value}',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: theme.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? color
                          : theme.secondaryText.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: widget.isConfirming
                        ? const Icon(Icons.check,
                            key: ValueKey('check'), size: 13, color: Colors.white)
                        : (isSelected
                            ? Center(
                                key: const ValueKey('dot'),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty'))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
