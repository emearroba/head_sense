import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
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

  @override
  Widget build(BuildContext context) {
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
        List<MetricsRecord> dailyDiaryPageMetricsRecordList = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(24.0),
              child: AppBar(
                backgroundColor: Color(0xFF0D1E26),
                automaticallyImplyLeading: false,
                title: Text(
                  'Daily Diary',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontStyle,
                        ),
                        color: Colors.white,
                        fontSize: 22.0,
                        letterSpacing: 0.0,
                        fontWeight: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontWeight,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                ),
                actions: [],
                centerTitle: false,
                elevation: 2.0,
              ),
            ),
            body: SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            22.0, 22.0, 22.0, 0.0),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 170),
                          curve: Curves.bounceOut,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Container(
                                  decoration: BoxDecoration(),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 10.0, 0.0, 0.0),
                                child: Container(
                                  width: 30.0,
                                  height: 30.0,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/images/fingerprint_icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment:
                                            AlignmentDirectional(-1.0, 0.0),
                                        child: Text(
                                          'How are you feeling today?',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                        ),
                                      ),
                                      Text(
                                        'Select the intensity of your sensations',
                                        style: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight: FontWeight.w300,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w300,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
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
                      ),
                    ],
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
                  Wrap(
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
                            22.0, 20.0, 22.0, 22.0),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 173.79,
                                  decoration: BoxDecoration(),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 12.0, 0.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 339.84,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Maximum level',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFFD64541),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Icon(
                                                Icons.add,
                                                color: Color(0xFFD64541),
                                                size: 24.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Extremely High',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFFE16235),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Very High',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFFE57A2B),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'High',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFFD99A32),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Moderately High',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFFD0B13C),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Moderate',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFFAEB94A),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Midly Present',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF76B759),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Low',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF59BE73),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Very Low',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF42C29B),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Minimal',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF36C9BB),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 339.8,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: Color(0x001A2A33),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                'Not present',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF32D6D3),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Icon(
                                                Icons.horizontal_rule,
                                                color: Color(0xFF32D6D3),
                                                size: 24.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 10.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '10',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFFD64541),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 9.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '9',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFFE16235),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 8.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '8',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFFE67532),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 7.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '7',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFFDD9433),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 6.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '6',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFFD2B03A),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 5.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '5',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFFAEB94A),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 4.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '4',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFF76B759),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 3.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '3',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFF59BE73),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 2.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          if ((_model.todayDiaryEntry
                                                      ?.reference !=
                                                  null) &&
                                              _model.todayDiaryEntry!
                                                  .isComplete) {
                                            context.pushNamed(
                                                DiaryCompletePageWidget
                                                    .routeName);
                                          }
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '2',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFF42C29B),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 1.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));

                                            context.pushNamed(
                                                DiaryCompletePageWidget
                                                    .routeName);
                                          }
                                        },
                                        text: '1',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFF36C9BB),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      FFButtonWidget(
                                        onPressed: () async {
                                          // Crear documento con valor del sintoma

                                          await ResponsesRecord.createDoc(
                                            _model.currentDiaryEntryRef!,
                                            id: dailyDiaryPageMetricsRecordList
                                                .elementAtOrNull(_model
                                                    .currentQuestionIndex!)!
                                                .metricKey,
                                          ).set({
                                            ...createResponsesRecordData(
                                              metricLabel:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricLabel,
                                              valueNumber: 0.0,
                                              metricKey:
                                                  dailyDiaryPageMetricsRecordList
                                                      .elementAtOrNull(_model
                                                          .currentQuestionIndex!)
                                                      ?.metricKey,
                                            ),
                                            ...mapToFirestore(
                                              {
                                                'capturedAt': FieldValue
                                                    .serverTimestamp(),
                                              },
                                            ),
                                          });
                                          // Recargar pagina al siguiente sintoma
                                          _model.currentQuestionIndex =
                                              _model.currentQuestionIndex! + 1;
                                          safeSetState(() {});
                                          if (_model.currentQuestionIndex! <
                                              dailyDiaryPageMetricsRecordList
                                                  .length) {
                                            safeSetState(() {});
                                            return;
                                          } else {
                                            await _model.currentDiaryEntryRef!
                                                .update(
                                                    createDiaryEntriesRecordData(
                                              completedAt: getCurrentTimestamp,
                                              isComplete: true,
                                              coinsEarned: 0,
                                            ));
                                          }

                                          context.pushNamed(
                                              DiaryCompletePageWidget
                                                  .routeName);
                                        },
                                        text: '0',
                                        options: FFButtonOptions(
                                          width: 120.0,
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  16.0, 0.0, 16.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: Color(0xFF32D6D3),
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.interTight(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
