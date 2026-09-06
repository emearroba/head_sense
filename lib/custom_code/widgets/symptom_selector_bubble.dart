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

// Replaces the plain FlutterFlowDropDown symptom picker: FlutterFlowDropDown
// has no per-item styling hook, and the dashboard needs tracked metrics
// shown in bold vs. untracked ones greyed out.
class SymptomSelectorBubble extends StatelessWidget {
  const SymptomSelectorBubble({
    super.key,
    required this.metrics,
    required this.trackedKeys,
    required this.alwaysOnKeys,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<MetricsRecord> metrics;
  final Set<String> trackedKeys;
  final Set<String> alwaysOnKeys;
  final String selectedKey;
  final void Function(String metricKey) onSelected;

  // Metric labels aren't consistently cased in Firestore (some are
  // ALL CAPS, some are already "Sentence case") - normalize to sentence
  // case here so the picker reads consistently regardless of source data.
  static String _sentenceCase(String label) => label.isEmpty
      ? label
      : '${label[0].toUpperCase()}${label.substring(1).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final selected = metrics.where((m) => m.metricKey == selectedKey);
    final selectedLabel = selected.isNotEmpty
        ? _sentenceCase(selected.first.metricLabel)
        : 'Select symptom';

    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xD21A2A33),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                selectedLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FlutterFlowTheme.of(context).secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.0,
                ),
              ),
            ),
            const SizedBox(width: 4.0),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 22.0),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              children: metrics.map((m) {
                final isTracked = alwaysOnKeys.contains(m.metricKey) ||
                    trackedKeys.contains(m.metricKey);
                final isSelected = m.metricKey == selectedKey;
                return ListTile(
                  title: Text(
                    _sentenceCase(m.metricLabel),
                    style: TextStyle(
                      color: isTracked
                          ? FlutterFlowTheme.of(context).primaryText
                          : FlutterFlowTheme.of(context).secondaryText,
                      fontWeight:
                          isTracked ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check,
                          color: FlutterFlowTheme.of(context).primary)
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(m.metricKey);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
