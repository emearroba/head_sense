import '/components/reminder_items_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'reminders_list_widget.dart' show RemindersListWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RemindersListModel extends FlutterFlowModel<RemindersListWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ReminderItems component.
  late ReminderItemsModel reminderItemsModel;

  @override
  void initState(BuildContext context) {
    reminderItemsModel = createModel(context, () => ReminderItemsModel());
  }

  @override
  void dispose() {
    reminderItemsModel.dispose();
  }
}
