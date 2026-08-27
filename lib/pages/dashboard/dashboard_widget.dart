import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/intensity_card_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/results/results_widget.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({
    super.key,
    String? metricKey,
  }) : this.metricKey = metricKey ?? 'headache_intensity';

  final String metricKey;

  static String routeName = 'Dashboard';
  static String routePath = '/Dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  late DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DashboardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text(
          title,
          style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
        ),
        content: Text(
          message,
          style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Got it',
              style: TextStyle(color: FlutterFlowTheme.of(context).primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, String infoMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                color: FlutterFlowTheme.of(context).primaryText,
                fontWeight: FontWeight.w600,
              ),
        ),
        FlutterFlowIconButton(
          borderRadius: 6.0,
          buttonSize: 26.0,
          icon: Icon(
            Icons.info_outline,
            color: FlutterFlowTheme.of(context).info,
            size: 14.0,
          ),
          onPressed: () => _showInfoDialog(context, title, infoMessage),
        ),
      ],
    );
  }

  Widget _intensityLegend(BuildContext context) {
    final items = [
      ('Crystal clear', const Color(0xFF4FA8B2)),
      ('Mild', const Color(0xFF7ABA5A)),
      ('Moderate', const Color(0xFFCB9A61)),
      ('Severe', const Color(0xFFBD3A31)),
    ];
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(
                color: item.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              item.$1,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DashboardRecord>>(
      stream: queryDashboardRecord(
        queryBuilder: (dashboardRecord) => dashboardRecord
            .where(
              'userRef',
              isEqualTo: currentUserReference,
            )
            .where(
              'metricKey',
              isEqualTo: _model.selectedMetricKey,
            )
            .where(
              'periodType',
              isEqualTo: _model.selectedPeriod,
            )
            .orderBy('periodStart', descending: true),
        singleRecord: true,
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
        List<DashboardRecord> dashboardDashboardRecordList = snapshot.data!;
        // Return an empty Container when the item does not exist.
        if (snapshot.data!.isEmpty) {
          return Container();
        }
        final dashboardDashboardRecord = dashboardDashboardRecordList.isNotEmpty
            ? dashboardDashboardRecordList.first
            : null;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: SingleChildScrollView(
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Results',
                                    style: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .override(
                                          font: GoogleFonts.interTight(
                                              fontWeight: FontWeight.w600),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  FlutterFlowIconButton(
                                    borderRadius: 6.0,
                                    buttonSize: 30.0,
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: FlutterFlowTheme.of(context).info,
                                      size: 16.0,
                                    ),
                                    onPressed: () => _showInfoDialog(
                                      context,
                                      'Results',
                                      'This page shows your tracking '
                                          'progress and how your symptoms '
                                          'have changed over time, based on '
                                          'your diary entries.',
                                    ),
                                  ),
                                ],
                              ),
                              StreamBuilder<UsersRecord>(
                                stream: UsersRecord.getDocument(
                                    currentUserReference!),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final trackedKeys = userSnapshot
                                      .data!.trackedMetricKeys
                                      .toSet();
                                  return StreamBuilder<List<MetricsRecord>>(
                                    stream: queryMetricsRecord(
                                      queryBuilder: (metricsRecord) =>
                                          metricsRecord
                                              .where('isActive',
                                                  isEqualTo: true)
                                              .orderBy('order'),
                                    ),
                                    builder: (context, metricsSnapshot) {
                                      if (!metricsSnapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      return custom_widgets
                                          .SymptomSelectorBubble(
                                        metrics: metricsSnapshot.data!,
                                        trackedKeys: trackedKeys,
                                        alwaysOnKeys: const {
                                          'headache_intensity',
                                          'analgesia',
                                        },
                                        selectedKey: _model.selectedMetricKey,
                                        onSelected: (key) {
                                          _model.selectedMetricKey = key;
                                          safeSetState(() {});
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Text(
                            'Select time range',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  fontSize: 12.0,
                                ),
                          ),
                          const SizedBox(height: 2.0),
                          Container(
                            height: 48.0,
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FFButtonWidget(
                                  onPressed: () async {
                                    _model.selectedPeriod = 'last30';
                                    safeSetState(() {});
                                  },
                                  text: '30 days',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: EdgeInsets.all(4.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: _model.selectedPeriod == 'last30'
                                        ? Color(0xFF123C45)
                                        : Color(0x001A2A33),
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w200,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color:
                                              _model.selectedPeriod == 'last30'
                                                  ? Color(0xFF2DE2D1)
                                                  : FlutterFlowTheme.of(context)
                                                      .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w200,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: _model.selectedPeriod == 'last30'
                                          ? FlutterFlowTheme.of(context).primary
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    _model.selectedPeriod = 'last60';
                                    safeSetState(() {});
                                  },
                                  text: '60 days',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: EdgeInsets.all(4.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: _model.selectedPeriod == 'last60'
                                        ? FlutterFlowTheme.of(context)
                                            .secondaryBackground
                                        : Colors.transparent,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w200,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color:
                                              _model.selectedPeriod == 'last60'
                                                  ? Color(0xFF2DE2D1)
                                                  : FlutterFlowTheme.of(context)
                                                      .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w200,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: _model.selectedPeriod == 'last60'
                                          ? Color(0xFF2DE2D1)
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    _model.selectedPeriod = 'last90';
                                    safeSetState(() {});
                                  },
                                  text: '90 days',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: EdgeInsets.all(4.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: _model.selectedPeriod == 'last90'
                                        ? Color(0xFF123C45)
                                        : Colors.transparent,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w200,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color:
                                              _model.selectedPeriod == 'last90'
                                                  ? Color(0xFF2DE2D1)
                                                  : FlutterFlowTheme.of(context)
                                                      .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w200,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: _model.selectedPeriod == 'last90'
                                          ? Color(0xFF2DE2D1)
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    _model.selectedPeriod = 'last180';
                                    safeSetState(() {});
                                  },
                                  text: '180 days',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: EdgeInsets.all(4.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: _model.selectedPeriod == 'last180'
                                        ? Color(0xFF123C45)
                                        : Colors.transparent,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w200,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color:
                                              _model.selectedPeriod == 'last180'
                                                  ? Color(0xFF2DE2D1)
                                                  : FlutterFlowTheme.of(context)
                                                      .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w200,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: _model.selectedPeriod == 'last180'
                                          ? Color(0xFF2DE2D1)
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    _model.selectedPeriod = 'last365';
                                    safeSetState(() {});
                                  },
                                  text: '1 year',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: EdgeInsets.all(4.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: _model.selectedPeriod == 'last365'
                                        ? Color(0xFF123C45)
                                        : Colors.transparent,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.rubik(
                                            fontWeight: FontWeight.w200,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color:
                                              _model.selectedPeriod == 'last365'
                                                  ? Color(0xFF2DE2D1)
                                                  : FlutterFlowTheme.of(context)
                                                      .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w200,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderSide: BorderSide(
                                      color: _model.selectedPeriod == 'last365'
                                          ? Color(0xFF2DE2D1)
                                          : Colors.transparent,
                                    ),
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${dashboardDashboardRecord?.metricLabel} overview',
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              font: GoogleFonts.interTight(
                                                  fontWeight: FontWeight.w600),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      FlutterFlowIconButton(
                                        borderRadius: 6.0,
                                        buttonSize: 26.0,
                                        icon: Icon(
                                          Icons.info_outline,
                                          color:
                                              FlutterFlowTheme.of(context).info,
                                          size: 14.0,
                                        ),
                                        onPressed: () => _showInfoDialog(
                                          context,
                                          '${dashboardDashboardRecord?.metricLabel} overview',
                                          'A quick summary of your '
                                              '${dashboardDashboardRecord?.metricLabel} '
                                              'data for the selected time range.',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Showing results since ${dateTimeFormat("d/M/y", dashboardDashboardRecord?.periodStart)}',
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          StreamBuilder<List<DailyValuesRecord>>(
                            stream: queryDailyValuesRecord(
                              parent: dashboardDashboardRecord?.reference,
                              queryBuilder: (dailyValuesRecord) =>
                                  dailyValuesRecord.orderBy('date'),
                            ),
                            builder: (context, snapshot) {
                              // Customize what your widget looks like when it's loading.
                              if (!snapshot.hasData) {
                                return Center(
                                  child: SizedBox(
                                    width: 50.0,
                                    height: 50.0,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              List<DailyValuesRecord>
                                  symptomBarChartDailyValuesRecordList =
                                  snapshot.data!;

                              return Container(
                                width: 350.0,
                                height: 200.0,
                                child: custom_widgets.SymptomBarChart(
                                  width: 350.0,
                                  height: 200.0,
                                  documents:
                                      symptomBarChartDailyValuesRecordList,
                                  yAxisLabel:
                                      '${dashboardDashboardRecord?.metricLabel} (0-10)',
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20.0),
                          Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionHeader(
                                    context,
                                    'Intensity over time',
                                    'A day-by-day calendar view of your '
                                        'symptom intensity, so you can spot '
                                        'patterns over weeks and months.',
                                  ),
                                  const SizedBox(height: 8.0),
                                  _intensityLegend(context),
                                  const SizedBox(height: 12.0),
                                  SizedBox(
                                    width: 350.0,
                                    child:
                                        StreamBuilder<List<DailyValuesRecord>>(
                                      stream: queryDailyValuesRecord(
                                        parent:
                                            dashboardDashboardRecord?.reference,
                                        queryBuilder: (dailyValuesRecord) =>
                                            dailyValuesRecord.orderBy('date'),
                                      ),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 24.0,
                                              height: 24.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        final calendarDailyValuesRecordList =
                                            snapshot.data!;

                                        return custom_widgets
                                            .SeverityCalendarPanel(
                                          width: double.infinity,
                                          // Cap so a long tracking history
                                          // scrolls instead of growing the
                                          // card without bound; shorter
                                          // histories size down to fit.
                                          height: 420.0,
                                          documents:
                                              calendarDailyValuesRecordList,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Card(
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionHeader(
                                    context,
                                    'Intensity Breakdown',
                                    'How your tracked days split across '
                                        'symptom-free, mild, moderate, and '
                                        'severe.',
                                  ),
                                  const SizedBox(height: 8.0),
                                  Container(
                                    width: 350.0,
                                    height: 300.0,
                                    child: custom_widgets.ClinicalDonutChart(
                                      width: 350.0,
                                      height: 300.0,
                                      crystalDays: dashboardDashboardRecord!
                                          .symptomFreeDays,
                                      mildDays: dashboardDashboardRecord!
                                          .mildSymptomDays,
                                      moderateDays: dashboardDashboardRecord!
                                          .moderateSymptomDays,
                                      severeDays: dashboardDashboardRecord!
                                          .severeSymptomDays,
                                      missingDays:
                                          dashboardDashboardRecord!.missingDays,
                                      painkillerDays: dashboardDashboardRecord!
                                          .painkillerDays,
                                      periodDays:
                                          dashboardDashboardRecord!.periodDays,
                                      metricLabel:
                                          dashboardDashboardRecord!.metricLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StreamBuilder<List<DiaryEntriesRecord>>(
                            stream: queryDiaryEntriesRecord(
                              queryBuilder: (q) => q
                                  .where('userRef',
                                      isEqualTo: currentUserReference)
                                  .where('isComplete', isEqualTo: true),
                            ),
                            builder: (context, medPatternsSnapshot) {
                              final medPatternsTotalDays =
                                  (medPatternsSnapshot.data ?? [])
                                      .map((e) => e.entryDateKey)
                                      .where((k) => k.isNotEmpty)
                                      .toSet()
                                      .length;
                              final medPatternsDaysRemaining =
                                  medPatternsTotalDays < 30
                                      ? 30 - medPatternsTotalDays
                                      : 0;
                              return custom_widgets.PatternLockCard(
                                title: 'Medication Patterns',
                                daysRemaining: medPatternsDaysRemaining,
                                onTapUpgrade: () =>
                                    context.pushNamed(ResultsWidget.routeName),
                              );
                            },
                          ),
                          Container(
                            height: 24.0,
                          ),
                        ].divide(SizedBox(height: 24.0)),
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
  }
}
