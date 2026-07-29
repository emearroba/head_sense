import '/backend/schema/reminders_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reminder_items_model.dart';
export 'reminder_items_model.dart';

class ReminderItemsWidget extends StatefulWidget {
  const ReminderItemsWidget({
    super.key,
    required this.reminderRecord,
  });

  final RemindersRecord reminderRecord;

  @override
  State<ReminderItemsWidget> createState() => _ReminderItemsWidgetState();
}

class _ReminderItemsWidgetState extends State<ReminderItemsWidget> {
  late ReminderItemsModel _model;
  bool _isUpdating = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReminderItemsModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  IconData get _icon {
    switch (widget.reminderRecord.type) {
      case 'rest_eyes':
        return Icons.visibility_outlined;
      case 'drink_water':
        return Icons.water_drop_outlined;
      case 'stand_up':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String get _frequencyLabel {
    switch (widget.reminderRecord.frequencyType) {
      case 'every_30_min':
        return 'Every 30 min';
      case 'every_60_min':
        return 'Every hour';
      case 'every_90_min':
        return 'Every 90 min';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      default:
        return 'Repeats';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminderRecord;
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 8.0,
              color: Color(0x1A000000),
              offset: Offset(
                0.0,
                2.0,
              ),
            )
          ],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Icon(
                          _icon,
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder.title.isNotEmpty
                                  ? reminder.title
                                  : 'Reminder',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _frequencyLabel,
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: _isUpdating
                    ? SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      )
                    : Switch(
                        value: reminder.isActive,
                        onChanged: (newValue) async {
                          safeSetState(() => _isUpdating = true);
                          await reminder.reference.update(
                            createRemindersRecordData(isActive: newValue),
                          );
                          safeSetState(() => _isUpdating = false);
                        },
                        activeThumbColor: FlutterFlowTheme.of(context).primary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
