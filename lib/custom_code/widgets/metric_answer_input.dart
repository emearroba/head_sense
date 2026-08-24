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
  });

  // 'boolean' | 'numeric' | 'time' | anything else falls back to the 0-10
  // style scale.
  final String answerType;
  final int scaleMin;
  final int scaleMax;
  final double step;
  final String unit;
  final Future<void> Function(double value) onSubmit;

  @override
  State<MetricAnswerInput> createState() => _MetricAnswerInputState();
}

class _MetricAnswerInputState extends State<MetricAnswerInput> {
  bool _submitting = false;
  double? _numericValue;

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
    'Not present',
  ];
  static const _scaleColors = [
    Color(0xFFD64541),
    Color(0xFFE16235),
    Color(0xFFE67532),
    Color(0xFFDD9433),
    Color(0xFFD2B03A),
    Color(0xFFAEB94A),
    Color(0xFF76B759),
    Color(0xFF59BE73),
    Color(0xFF42C29B),
    Color(0xFF36C9BB),
    Color(0xFF32D6D3),
  ];

  Future<void> _handleSubmit(double value) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onSubmit(value);
    if (mounted) setState(() => _submitting = false);
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

  Widget _buildNumeric(BuildContext context) {
    _numericValue ??= widget.scaleMin.toDouble();
    final display = widget.step == widget.step.roundToDouble()
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
                _numericValue = (_numericValue! - widget.step)
                    .clamp(widget.scaleMin.toDouble(), widget.scaleMax.toDouble());
              }),
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
              iconSize: 32,
            ),
            SizedBox(
              width: 120,
              child: Text(
                widget.unit.isEmpty ? display : '$display ${widget.unit}',
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
                _numericValue = (_numericValue! + widget.step)
                    .clamp(widget.scaleMin.toDouble(), widget.scaleMax.toDouble());
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

  Widget _buildScale(BuildContext context) {
    final levels = widget.scaleMax - widget.scaleMin + 1;
    final useNamedPalette = widget.scaleMin == 0 && widget.scaleMax == 10;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(levels, (i) {
        final value = widget.scaleMax - i; // descending, matches original UX
        final label =
            useNamedPalette ? _scaleLabels[i] : '$value';
        final color = useNamedPalette
            ? _scaleColors[i]
            : Color.lerp(
                const Color(0xFF32D6D3),
                const Color(0xFFD64541),
                levels <= 1 ? 0 : i / (levels - 1),
              )!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ElevatedButton(
            onPressed: _submitting ? null : () => _handleSubmit(value.toDouble()),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }),
    );
  }
}
