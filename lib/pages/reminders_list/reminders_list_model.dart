import '/components/reminder_items_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'reminders_list_widget.dart' show RemindersListWidget;
import 'package:flutter/material.dart';

class RemindersListModel extends FlutterFlowModel<RemindersListWidget> {
  ///  State fields for stateful widgets in this page.

  // Models for the dynamic list of ReminderItems components.
  late FlutterFlowDynamicModels<ReminderItemsModel> reminderItemsModels;

  @override
  void initState(BuildContext context) {
    reminderItemsModels = FlutterFlowDynamicModels(() => ReminderItemsModel());
  }

  @override
  void dispose() {
    reminderItemsModels.dispose();
  }
}
