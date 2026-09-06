import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'daily_diary_page_widget.dart' show DailyDiaryPageWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DailyDiaryPageModel extends FlutterFlowModel<DailyDiaryPageWidget> {
  ///  Local state fields for this page.

  int? currentQuestionIndex = 0;

  DocumentReference? currentDiaryEntryRef;

  // True until the initState lookup of today's diary entry resolves.
  // Keeps the questionnaire from flashing on screen for a frame before a
  // redirect to the "already completed" page kicks in.
  bool checkingTodayEntry = true;

  // Answers given so far this session, keyed by metricKey, so the "back"
  // button can show what was previously entered for a question.
  final Map<String, double> localAnswers = {};

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in DailyDiaryPage widget.
  DiaryEntriesRecord? todayDiaryEntry;
  // Stores action output result for [Backend Call - Create Document] action in DailyDiaryPage widget.
  DiaryEntriesRecord? createdDiaryEntry;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
