import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/recurrent_reminder_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'reminders_widget.dart' show RemindersWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RemindersModel extends FlutterFlowModel<RemindersWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Switch widget.
  bool? switchValue;
  DateTime? datePicked;
  // Model for RecurrentReminder component.
  late RecurrentReminderModel recurrentReminderModel;

  @override
  void initState(BuildContext context) {
    recurrentReminderModel =
        createModel(context, () => RecurrentReminderModel());
  }

  @override
  void dispose() {
    recurrentReminderModel.dispose();
  }
}
