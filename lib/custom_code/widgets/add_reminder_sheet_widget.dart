import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/reminders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _ReminderPreset {
  const _ReminderPreset(this.type, this.label, this.message, this.icon);
  final String type;
  final String label;
  final String message;
  final IconData icon;
}

const _presets = [
  _ReminderPreset(
    'rest_eyes',
    'Rest your eyes',
    'Look at something 20 feet away for 20 seconds.',
    Icons.visibility_outlined,
  ),
  _ReminderPreset(
    'drink_water',
    'Drink water',
    'Time to hydrate.',
    Icons.water_drop_outlined,
  ),
  _ReminderPreset(
    'stand_up',
    'Stand up',
    'Stand up and stretch for a minute.',
    Icons.accessibility_new_rounded,
  ),
];

const _frequencyLabels = {
  'every_30_min': 'Every 30 min',
  'every_60_min': 'Every hour',
  'every_90_min': 'Every 90 min',
};

const _frequencyMinutes = {
  'every_30_min': 30,
  'every_60_min': 60,
  'every_90_min': 90,
};

/// Bottom sheet for creating a recurring reminder. Show with
/// `showModalBottomSheet(context: context, isScrollControlled: true,
/// builder: (_) => AddReminderSheetWidget())`.
class AddReminderSheetWidget extends StatefulWidget {
  const AddReminderSheetWidget({super.key});

  @override
  State<AddReminderSheetWidget> createState() =>
      _AddReminderSheetWidgetState();
}

class _AddReminderSheetWidgetState extends State<AddReminderSheetWidget> {
  String _selectedType = _presets.first.type;
  String _selectedFrequency = _frequencyLabels.keys.first;
  final _customTitleController = TextEditingController();
  final _customMessageController = TextEditingController();
  bool _isSaving = false;

  bool get _isCustom => _selectedType == 'custom';

  @override
  void dispose() {
    _customTitleController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _isCustom
        ? _customTitleController.text.trim()
        : _presets.firstWhere((p) => p.type == _selectedType).label;
    final message = _isCustom
        ? _customMessageController.text.trim()
        : _presets.firstWhere((p) => p.type == _selectedType).message;

    if (title.isEmpty) {
      showSnackbar(context, 'Give the reminder a title');
      return;
    }
    final userRef = currentUserReference;
    if (userRef == null) {
      showSnackbar(context, 'You need to be signed in to add a reminder');
      return;
    }

    safeSetState(() => _isSaving = true);

    final now = DateTime.now();
    final intervalMinutes = _frequencyMinutes[_selectedFrequency]!;

    try {
      await RemindersRecord.createDoc(userRef).set(
        createRemindersRecordData(
          title: title,
          message: message,
          type: _selectedType,
          frequencyType: _selectedFrequency,
          isActive: true,
          createdTime: now,
          scheduledTime: now.add(Duration(minutes: intervalMinutes)),
          userRef: userRef,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      safeSetState(() => _isSaving = false);
      if (mounted) showSnackbar(context, 'Could not save the reminder');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New reminder',
              style: theme.headlineSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            ..._presets.map(
              (preset) => _OptionTile(
                selected: _selectedType == preset.type,
                icon: preset.icon,
                label: preset.label,
                onTap: () => safeSetState(() => _selectedType = preset.type),
              ),
            ),
            _OptionTile(
              selected: _isCustom,
              icon: Icons.edit_outlined,
              label: 'Custom',
              onTap: () => safeSetState(() => _selectedType = 'custom'),
            ),
            if (_isCustom) ...[
              SizedBox(height: 4),
              TextField(
                controller: _customTitleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _customMessageController,
                decoration: InputDecoration(labelText: 'Message'),
              ),
            ],
            SizedBox(height: 20),
            Text(
              'Frequency',
              style: theme.labelLarge.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencyLabels.entries.map((entry) {
                final selected = _selectedFrequency == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (_) =>
                      safeSetState(() => _selectedFrequency = entry.key),
                  selectedColor: theme.primary,
                  backgroundColor: theme.secondaryBackground,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : theme.primaryText,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            FFButtonWidget(
              onPressed: _isSaving ? null : _save,
              text: _isSaving ? 'Saving...' : 'Add reminder',
              options: FFButtonOptions(
                width: double.infinity,
                height: 50,
                color: theme.primary,
                textStyle: theme.titleSmall.override(
                  font: GoogleFonts.interTight(),
                  color: Colors.white,
                ),
                elevation: 0,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? theme.primary.withValues(alpha: 0.1)
                : theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.primary : theme.alternate,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? theme.primary : theme.secondaryText,
              ),
              SizedBox(width: 12),
              Text(label, style: theme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
