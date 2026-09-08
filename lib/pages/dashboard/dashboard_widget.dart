import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/results/results_widget.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static const _weekdaysShort = ['Su', 'M', 'Tu', 'W', 'Th', 'F', 'Sa'];

  // Sun=0..Sat=6, matching update_dashboard_metric.js's WEEKDAYS_SHORT
  // indexing (JS Date#getUTCDay()) - Dart's DateTime#weekday is Mon=1..Sun=7,
  // so %7 remaps Sun from 7 to 0 while leaving Mon..Sat unchanged.
  String _dayOfWeekFor(String dateKey) =>
      _weekdaysShort[DateTime.parse(dateKey).weekday % 7];

  // Builds the same per-day records the removed `dashboard/{doc}/daily_values`
  // subcollection used to provide, directly from the parent DashboardRecord's
  // own `dailyValues` array (already in memory - no separate Firestore
  // listener needed). That subcollection duplicated data already inline on
  // the parent doc; SymptomBarChart/SeverityCalendarPanel/IntensityStatsPanel
  // still take `List<DailyValuesRecord>`, so this adapts without touching
  // those three widgets' internals. `dayOfWeek`/`dayOfWeekIndex` aren't
  // exposed on DailyValueStruct (see dashboard_record.dart), so they're
  // recomputed here from `date`; the synthetic per-day DocumentReference is
  // never read from by any of the three widgets, just a placeholder
  // getDocumentFromData requires.
  List<DailyValuesRecord> _dailyValuesFromDashboard(DashboardRecord record) {
    return record.dailyValues.map((d) {
      final dayOfWeekIndex = DateTime.parse(d.date).weekday % 7;
      return DailyValuesRecord.getDocumentFromData(
        {
          'day': d.day,
          'date': d.date,
          'category': d.category,
          'isTracked': d.isTracked,
          'isSpike': d.isSpike,
          'deltaFromPreviousDay': d.deltaFromPreviousDay,
          'value': d.value,
          'barColor': d.barColor,
          'dayOfWeek': _dayOfWeekFor(d.date),
          'dayOfWeekIndex': dayOfWeekIndex,
          'isMild': d.isMild,
          'isModerate': d.isModerate,
          'isSevere': d.isSevere,
          'isMissing': d.isMissing,
        },
        record.reference.collection('daily_values').doc(d.date),
      );
    }).toList();
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

  // Compact stat used in the "X overview" card header (Average intensity /
  // Spikes / Clear days) - replaces what used to be separate headline-tile
  // cards, integrated directly above the chart instead.
  Widget _overviewStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.0,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
      ],
    );
  }

  // Tracking-progress row (days tracked / consistency / streak / insights
  // ready), moved here from the Patterns tab's TrackingProgressCard - reuses
  // fields the update_dashboard_metric.js cloud function already computes
  // for the currently selected metric/period, so it needs no extra query
  // and stays in sync with the period pill above it. Coins/milestones (the
  // rest of the old card) were dropped, not moved - see CLAUDE.md session
  // notes on the Patterns header cleanup.
  Widget _trackingStatsRow(BuildContext context, DashboardRecord? focus) {
    final theme = FlutterFlowTheme.of(context);
    final consistencyPct = (focus?.completionRate ?? 0.0) * 100;
    final insightsReady = focus?.analysisEligible ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 2.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            'Your progress',
            'How consistently you\'ve been tracking this period.',
          ),
          Row(
            children: [
              Expanded(
                child: _miniTrackingStat(
                  context,
                  Icons.calendar_today,
                  theme.primary,
                  '${focus?.daysTracked ?? 0}',
                  'days tracked',
                ),
              ),
              Expanded(
                child: _miniTrackingStat(
                  context,
                  Icons.check_circle_outline,
                  const Color(0xFF66E0C2),
                  '${consistencyPct.round()}%',
                  'consistency',
                ),
              ),
              Expanded(
                child: _miniTrackingStat(
                  context,
                  Icons.local_fire_department,
                  const Color(0xFFE67532),
                  '${focus?.currentDiaryStreak ?? 0}',
                  'day streak',
                ),
              ),
              Expanded(
                child: _miniTrackingStat(
                  context,
                  Icons.insights,
                  insightsReady ? theme.primary : theme.secondaryText,
                  insightsReady ? 'Ready' : 'Soon',
                  'insights ready',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTrackingStat(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14.0, color: color),
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.0, color: theme.secondaryText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The 7-day pill has no server-computed period of its own (see
    // PERIODS in update_dashboard_metric.js) - it's derived client-side
    // from the trailing 7 days of the last30 doc, same as the Patterns tab.
    final queryPeriod =
        _model.selectedPeriod == 'last7' ? 'last30' : _model.selectedPeriod;
    return StreamBuilder<List<DashboardRecord>>(
      stream: queryDashboardRecord(
        queryBuilder: (dashboardRecord) => dashboardRecord
            .where(
              'subjectId',
              isEqualTo: currentSubjectId,
            )
            .where(
              'metricKey',
              isEqualTo: _model.selectedMetricKey,
            )
            .where(
              'periodType',
              isEqualTo: queryPeriod,
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
        // No dashboard doc yet for this metric/period - update_dashboard_metric.js
        // only writes one once there's at least one diary entry to aggregate, so
        // this is the normal state for a brand-new account. Was `return
        // Container()` - an unstyled, background-less empty box that rendered as
        // a blank white page instead of a "nothing to show yet" message.
        if (snapshot.data!.isEmpty) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No data yet. Log a few diary entries to see your dashboard here.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ),
            ),
          );
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
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              automaticallyImplyLeading: false,
              toolbarHeight: 68.0,
              title: const custom_widgets.AppSectionHeader(
                title: 'Dashboard',
                subtitle: 'Your symptom history',
              ),
              elevation: 0.0,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20.0, 16.0, 20.0, 120.0),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                            children: [
                              Text(
                                'Looking at',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                    ),
                              ),
                              const SizedBox(width: 8.0),
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
                          StreamBuilder<UsersRecord>(
                            stream:
                                UsersRecord.getDocument(currentUserReference!),
                            builder: (context, userSnapshot) {
                              final isPremium =
                                  userSnapshot.data?.plan == 'premium';
                              return custom_widgets.PeriodSelectorBubble(
                                selectedPeriod: _model.selectedPeriod,
                                onPeriodChanged: (p) {
                                  _model.selectedPeriod = p;
                                  safeSetState(() {});
                                },
                                isPremium: isPremium,
                              );
                            },
                          ),
                          _trackingStatsRow(context, dashboardDashboardRecord),
                          Card(
                            margin: EdgeInsets.zero,
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
                                  const SizedBox(height: 16.0),
                                  Builder(
                                    builder: (context) {
                                      if (dashboardDashboardRecord == null) {
                                        return const Center(
                                          child: SizedBox(
                                            width: 50.0,
                                            height: 50.0,
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      final allDays =
                                          _dailyValuesFromDashboard(
                                              dashboardDashboardRecord!);
                                      // The 7-day pill shares the last30 doc
                                      // (see queryPeriod above) - slice its
                                      // trailing 7 tracked days client-side
                                      // rather than querying separately.
                                      final periodDays =
                                          _model.selectedPeriod == 'last7' &&
                                                  allDays.length > 7
                                              ? allDays.sublist(
                                                  allDays.length - 7)
                                              : allDays;
                                      final tracked = periodDays
                                          .where((d) => d.isTracked)
                                          .toList();
                                      final symptomDays = tracked
                                          .where((d) => d.value > 0)
                                          .toList();
                                      final avgIntensity = symptomDays.isEmpty
                                          ? null
                                          : symptomDays.fold<int>(
                                                  0, (sum, d) => sum + d.value) /
                                              symptomDays.length;
                                      final spikes = periodDays
                                          .where((d) => d.isSpike)
                                          .length;
                                      final clearDays = tracked
                                          .where((d) => d.value <= 0)
                                          .length;

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _overviewStat(
                                                  context,
                                                  avgIntensity == null
                                                      ? '—'
                                                      : avgIntensity
                                                          .toStringAsFixed(1),
                                                  'Average intensity',
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                              Expanded(
                                                child: _overviewStat(
                                                  context,
                                                  '$spikes',
                                                  'Spikes',
                                                  const Color(0xFFFFC533),
                                                ),
                                              ),
                                              Expanded(
                                                child: _overviewStat(
                                                  context,
                                                  '$clearDays',
                                                  'Clear days',
                                                  const Color(0xFF36D6D6),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16.0),
                                          Container(
                                            width: 350.0,
                                            height: 200.0,
                                            child: custom_widgets.SymptomBarChart(
                                              width: 350.0,
                                              height: 200.0,
                                              documents: periodDays,
                                              yAxisLabel:
                                                  '${dashboardDashboardRecord?.metricLabel} (0-10)',
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            margin: EdgeInsets.zero,
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
                                    child: Builder(
                                      builder: (context) {
                                        if (dashboardDashboardRecord == null) {
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
                                            _dailyValuesFromDashboard(
                                                dashboardDashboardRecord!);

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
                          Card(
                            margin: EdgeInsets.zero,
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
                                  .where('subjectId',
                                      isEqualTo: currentSubjectId)
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
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}
