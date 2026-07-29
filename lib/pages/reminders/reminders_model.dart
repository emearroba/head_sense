import '/components/reminder_items_widget.dart';
import '/components/recurrent_reminder_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'reminders_widget.dart' show RemindersWidget;
import 'package:flutter/material.dart';

class RemindersModel extends FlutterFlowModel<RemindersWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Switch widget.
  bool? switchValue;
  DateTime? datePicked;
  // Model for RecurrentReminder component.
  late RecurrentReminderModel recurrentReminderModel;
  // Models for the dynamic list of wellness ReminderItems components.
  late FlutterFlowDynamicModels<ReminderItemsModel> reminderItemsModels;

  @override
  void initState(BuildContext context) {
    recurrentReminderModel =
        createModel(context, () => RecurrentReminderModel());
    reminderItemsModels = FlutterFlowDynamicModels(() => ReminderItemsModel());
  }

  @override
  void dispose() {
    recurrentReminderModel.dispose();
    reminderItemsModels.dispose();
  }
}
