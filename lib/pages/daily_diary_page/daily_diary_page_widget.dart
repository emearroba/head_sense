import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'daily_diary_page_model.dart';
export 'daily_diary_page_model.dart';

class DailyDiaryPageWidget extends StatefulWidget {
  const DailyDiaryPageWidget({
    super.key,
    bool? editMode,
  }) : this.editMode = editMode ?? false;

  final bool editMode;

  static String routeName = 'DailyDiaryPage';
  static String routePath = '/dailyDiaryPage';

  @override
  State<DailyDiaryPageWidget> createState() => _DailyDiaryPageWidgetState();
}

class _DailyDiaryPageWidgetState extends State<DailyDiaryPageWidget> {
  late DailyDiaryPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DailyDiaryPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.todayDiaryEntry = await queryDiaryEntriesRecordOnce(
        queryBuilder: (diaryEntriesRecord) => diaryEntriesRecord
            .where(
              'userRef',
              isEqualTo: currentUserReference,
            )
            .where(
              'entryDateKey',
              isEqualTo: valueOrDefault<String>(
                dateTimeFormat("yyyy-MM-dd", getCurrentTimestamp),
                '2026-06-02',
              ),
            ),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
      if ((_model.todayDiaryEntry?.reference != null) &&
          !widget!.editMode &&
          _model.todayDiaryEntry!.isComplete) {
        context.goNamed(DiaryCompletePageRetryWidget.routeName);

        return;
      }
      if (_model.todayDiaryEntry?.reference != null) {
        _model.currentDiaryEntryRef = _model.todayDiaryEntry?.reference;
        _model.checkingTodayEntry = false;
        safeSetState(() {});
        return;
      }
      // 1. Create diary_entry document

      var diaryEntriesRecordReference =
          DiaryEntriesRecord.collection.doc('${valueOrDefault<String>(
        currentUserReference?.id,
        'user',
      )}_${valueOrDefault<String>(
        dateTimeFormat("yyyy-MM-dd", getCurrentTimestamp),
        '2026-06-01',
      )}');
      await diaryEntriesRecordReference.set({
        ...createDiaryEntriesRecordData(
          entryDateKey: dateTimeFormat("yyyy-MM-dd", getCurrentTimestamp),
          isComplete: false,
          userRef: currentUserReference,
          completedAt: getCurrentTimestamp,
        ),
        ...mapToFirestore(
          {
            'entryDate': FieldValue.serverTimestamp(),
          },
        ),
      });
      _model.createdDiaryEntry = DiaryEntriesRecord.getDocumentFromData({
        ...createDiaryEntriesRecordData(
          entryDateKey: dateTimeFormat("yyyy-MM-dd", getCurrentTimestamp),
          isComplete: false,
          userRef: currentUserReference,
          completedAt: getCurrentTimestamp,
        ),
        ...mapToFirestore(
          {
            'entryDate': DateTime.now(),
          },
        ),
      }, diaryEntriesRecordReference);
      _model.currentDiaryEntryRef = _model.createdDiaryEntry?.reference;
      _model.checkingTodayEntry = false;
      safeSetState(() {});
      // Action 6 - show next symptom
      await queryMetricsRecordOnce(
        queryBuilder: (metricsRecord) => metricsRecord
            .where(
              'isActive',
              isEqualTo: true,
            )
            .orderBy('order'),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // Headache + painkillers are always asked about, regardless of the
  // user's Track selection.
  static const _alwaysOnMetricKeys = {'headache_intensity', 'analgesia'};

  // Scale questions (the 0-10 style ones) come first, then schedule/time
  // questions, then everything else (boolean, numeric) - within each group
  // the original Firestore `order` is preserved.
  static int _questionGroup(String answerType) {
    switch (answerType) {
      case 'time':
        return 1;
      case 'boolean':
      case 'numeric':
        return 2;
      default:
        return 0;
    }
  }

  static List<MetricsRecord> _orderQuestions(List<MetricsRecord> metrics) {
    final indexed = metrics.asMap().entries.toList()
      ..sort((a, b) {
        final groupCompare = _questionGroup(a.value.answerType)
            .compareTo(_questionGroup(b.value.answerType));
        if (groupCompare != 0) return groupCompare;
        return a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_model.checkingTodayEntry) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ),
      );
    }
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        final trackedKeys = userSnapshot.data!.trackedMetricKeys.toSet();

        return StreamBuilder<List<MetricsRecord>>(
      stream: queryMetricsRecord(
        queryBuilder: (metricsRecord) => metricsRecord
            .where(
              'isActive',
              isEqualTo: true,
            )
            .orderBy('order'),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<MetricsRecord> dailyDiaryPageMetricsRecordList = _orderQuestions(
          snapshot.data!
              .where((m) =>
                  _alwaysOnMetricKeys.contains(m.metricKey) ||
                  trackedKeys.contains(m.metricKey))
              .toList(),
        );

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              automaticallyImplyLeading: false,
              toolbarHeight: 68.0,
              title: const custom_widgets.AppSectionHeader(
                title: 'Daily Diary',
                subtitle: 'How are you feeling today?',
              ),
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(22.0, 14.0, 22.0, 0.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3.0),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                        tween: Tween<double>(
                          end: dailyDiaryPageMetricsRecordList.isEmpty
                              ? 0.0
                              : (_model.currentQuestionIndex! /
                                      dailyDiaryPageMetricsRecordList.length)
                                  .clamp(0.0, 1.0),
                        ),
                        builder: (context, progress, _) => LinearProgressIndicator(
                          value: progress,
                          minHeight: 5.0,
                          backgroundColor: Color(0xFF1A2A33),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              FlutterFlowTheme.of(context).primary),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.07,
                    decoration: BoxDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 20.0, 0.0, 0.0),
                          child: Visibility(
                            visible: _model.currentQuestionIndex! > 0,
                            maintainSize: true,
                            maintainAnimation: true,
                            maintainState: true,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: FlutterFlowTheme.of(context)
                                    .primaryText,
                              ),
                              tooltip: 'Go back to previous question',
                              onPressed: () {
                                _model.currentQuestionIndex =
                                    _model.currentQuestionIndex! - 1;
                                safeSetState(() {});
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 20.0, 0.0, 0.0),
                          child: Text(
                            valueOrDefault<String>(
                              dailyDiaryPageMetricsRecordList
                                  .elementAtOrNull(_model.currentQuestionIndex!)
                                  ?.metricLabel,
                              'Loading your sensations...',
                            ),
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                    spacing: 0.0,
                    runSpacing: 0.0,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    direction: Axis.horizontal,
                    runAlignment: WrapAlignment.start,
                    verticalDirection: VerticalDirection.down,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            22.0, 20.0, 22.0, 120.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF0D1E26),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 6.0,
                                color: Color(0xFF1F3A45),
                                offset: Offset(
                                  0.0,
                                  2.0,
                                ),
                              )
                            ],
                            borderRadius: BorderRadius.circular(18.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: custom_widgets.MetricAnswerInput(
                              key: ValueKey(dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.metricKey ??
                                  _model.currentQuestionIndex),
                              metricKey: dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.metricKey ??
                                  '',
                              initialValue: _model.localAnswers[
                                  dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.metricKey],
                              answerType: dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.answerType ??
                                  '',
                              scaleMin: dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.scaleMin ??
                                  0,
                              scaleMax: dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.scaleMax ??
                                  10,
                              step: dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.step ??
                                  1.0,
                              unit: dailyDiaryPageMetricsRecordList
                                      .elementAtOrNull(
                                          _model.currentQuestionIndex!)
                                      ?.unit ??
                                  '',
                              onSubmit: (value) async {
                                final currentMetric =
                                    dailyDiaryPageMetricsRecordList
                                        .elementAtOrNull(
                                            _model.currentQuestionIndex!)!;
                                _model.localAnswers[currentMetric.metricKey] =
                                    value;
                                await ResponsesRecord.createDoc(
                                  _model.currentDiaryEntryRef!,
                                  id: currentMetric.metricKey,
                                ).set({
                                  ...createResponsesRecordData(
                                    metricLabel: currentMetric.metricLabel,
                                    valueNumber: value,
                                    metricKey: currentMetric.metricKey,
                                  ),
                                  ...mapToFirestore(
                                    {
                                      'capturedAt':
                                          FieldValue.serverTimestamp(),
                                    },
                                  ),
                                });
                                _model.currentQuestionIndex =
                                    _model.currentQuestionIndex! + 1;
                                safeSetState(() {});
                                if (_model.currentQuestionIndex! <
                                    dailyDiaryPageMetricsRecordList.length) {
                                  return;
                                }
                                await _model.currentDiaryEntryRef!.update(
                                    createDiaryEntriesRecordData(
                                  completedAt: getCurrentTimestamp,
                                  isComplete: true,
                                  coinsEarned: 0,
                                ));
                                if (context.mounted) {
                                  context.pushNamed(
                                      DiaryCompletePageWidget.routeName);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }
}
