import 'dart:math';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'results_model.dart';
export 'results_model.dart';

// Free section: the TrackingProgressCard (100-day progress path, logging
// streak, days tracked, days to insights, coins) — also the sole place that
// awards milestone coins (see tracking_progress_card.dart). Below that,
// Core/Premium users (user.plan) get real pattern analysis (Your Pattern /
// What Seems Connected / How You're Changing / Worth Watching) via
// PatternInsightsPanel; everyone else sees the existing PatternLockCard.
class ResultsWidget extends StatefulWidget {
  const ResultsWidget({super.key});

  static String routeName = 'Results';
  static String routePath = '/results';

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  late ResultsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _seeding = false;
  // 0 = Overview, 1 = Connections, 2 = Interventions.
  int _mainTabIndex = 0;
  // Owned here (not inside PatternInsightsPanel) so the selectors shown
  // above the Overview / Connections tabs and the panel underneath can
  // never disagree about which window/metric is selected. Connections
  // keeps its own independent period + anchor symptom.
  String _selectedPeriod = 'last30';
  String _selectedFocusKey = 'headache_intensity';
  // Set (and _mainTabIndex flipped to 1) when the user taps a "strongest
  // connections" row on Overview - preloads that pair into Connections'
  // Advanced section. Bumped on every tap (even to the same key) via a
  // trailing counter so ConnectionsPanel's key changes and re-applies it.
  String? _connectionsInitialCompareKey;
  int _connectionsInitialCompareNonce = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ResultsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isPaying =
            user != null && (user.plan == 'core' || user.plan == 'premium');

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          appBar: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            automaticallyImplyLeading: false,
            toolbarHeight: 68.0,
            title: const custom_widgets.AppSectionHeader(
              title: 'Insights',
              subtitle: 'What your body is telling you',
            ),
            elevation: 0.0,
          ),
          body: SafeArea(
            child: user == null
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  )
                : StreamBuilder<List<DiaryEntriesRecord>>(
                    stream: queryDiaryEntriesRecord(
                      queryBuilder: (q) => q
                          .where('subjectId', isEqualTo: currentSubjectId)
                          .where('isComplete', isEqualTo: true),
                    ),
                    builder: (context, entriesSnapshot) {
                      if (!entriesSnapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                        );
                      }
                      final dateKeys = entriesSnapshot.data!
                          .map((e) => e.entryDateKey)
                          .where((k) => k.isNotEmpty)
                          .toSet() // de-dupe, just in case
                          .toList()
                        ..sort();
                      final totalDays = dateKeys.length;

                      return ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 120.0),
                        children: [
                          if (isPaying) ...[
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
                                StreamBuilder<List<MetricsRecord>>(
                                  stream: queryMetricsRecord(
                                    queryBuilder: (m) => m
                                        .where('isActive', isEqualTo: true)
                                        .orderBy('order'),
                                  ),
                                  builder: (context, metricsSnapshot) {
                                    return custom_widgets
                                        .SymptomSelectorBubble(
                                      metrics: metricsSnapshot.data ?? [],
                                      trackedKeys:
                                          user.trackedMetricKeys.toSet(),
                                      alwaysOnKeys: const {
                                        'headache_intensity',
                                        'analgesia',
                                      },
                                      selectedKey: _selectedFocusKey,
                                      onSelected: (key) => setState(
                                          () => _selectedFocusKey = key),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            custom_widgets.PeriodSelectorBubble(
                              selectedPeriod: _selectedPeriod,
                              onPeriodChanged: (p) =>
                                  setState(() => _selectedPeriod = p),
                              isPremium: user.plan == 'premium',
                            ),
                            const SizedBox(height: 10.0),
                            _mainTabs(context),
                            const SizedBox(height: 16.0),
                            if (_mainTabIndex == 0)
                              custom_widgets.PatternInsightsPanel(
                                trackedMetricKeys: user.trackedMetricKeys,
                                selectedPeriod: _selectedPeriod,
                                onPeriodChanged: (p) =>
                                    setState(() => _selectedPeriod = p),
                                selectedFocusKey: _selectedFocusKey,
                                totalDays: totalDays,
                                onOpenConnection: (otherKey) => setState(() {
                                  _connectionsInitialCompareKey = otherKey;
                                  _connectionsInitialCompareNonce++;
                                  _mainTabIndex = 1;
                                }),
                                onOpenConnectionsTab: () =>
                                    setState(() => _mainTabIndex = 1),
                                onOpenInterventionsTab: () =>
                                    setState(() => _mainTabIndex = 2),
                              )
                            else if (_mainTabIndex == 1)
                              custom_widgets.ConnectionsPanel(
                                key: ValueKey(
                                    'connections_$_connectionsInitialCompareNonce'),
                                trackedMetricKeys: user.trackedMetricKeys,
                                selectedFocusKey: _selectedFocusKey,
                                selectedPeriod: _selectedPeriod,
                                initialCompareKey:
                                    _connectionsInitialCompareKey,
                              )
                            else
                              custom_widgets.InterventionsComparisonPanel(
                                selectedFocusKey: _selectedFocusKey,
                                selectedPeriod: _selectedPeriod,
                                totalDays: totalDays,
                              ),
                          ] else
                            _lockedAnalysisCard(context, totalDays),
                          // TEMPORARY dev-only affordance to backfill fake
                          // diary days for testing the pattern gates -
                          // remove once no longer needed. kDebugMode-gated so
                          // it never renders (or even runs) in release
                          // builds - it must never be reachable by real
                          // users, since it grants premium for free.
                          if (kDebugMode) ...[
                            const SizedBox(height: 12.0),
                            OutlinedButton(
                              onPressed: _seeding
                                  ? null
                                  : () => _seedAverageUserHistory(context,
                                      dateKeys, user.trackedMetricKeys),
                              child: _seeding
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.0),
                                        ),
                                        SizedBox(width: 10.0),
                                        Text('Seeding…'),
                                      ],
                                    )
                                  : const Text(
                                      'DEV: seed ~90d average-user history (with gaps)'),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  // Three main tabs below the "Patterns" header: single-symptom results,
  // cross-symptom relationships, and before/after intervention comparisons.
  // Deliberately compact (one row, no extra caption) since filters/
  // navigation chrome should take minimal space — the results underneath
  // are what should dominate the screen. One continuous rounded track
  // holding all segments (same construction as PeriodSelectorBubble) so the
  // tabs read as a single split bubble rather than separate ones.
  Widget _mainTabs(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 40.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(13.0),
      ),
      child: Row(
        children: [
          Expanded(child: _mainTabButton(context, 0, 'Overview')),
          Expanded(child: _mainTabButton(context, 1, 'Connections')),
          Expanded(child: _mainTabButton(context, 2, 'Interventions')),
        ],
      ),
    );
  }

  Widget _mainTabButton(BuildContext context, int index, String label) {
    final selected = _mainTabIndex == index;
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: () => setState(() => _mainTabIndex = index),
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF123C45) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: selected ? theme.primary : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: selected ? theme.primary : theme.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _lockedAnalysisCard(BuildContext context, int totalDays) {
    final daysRemaining = totalDays < 30 ? 30 - totalDays : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        custom_widgets.PatternLockCard(
          title: 'Pattern Analysis',
          daysRemaining: daysRemaining,
          onTapUpgrade: () {
            // TODO: wire to the real subscription flow once payment infra
            // (see CLAUDE.md) is built; for now this is a UI-only placeholder.
          },
        ),
        const SizedBox(height: 8.0),
        Text(
          'Your personal discoveries — the habits, days, and trends that '
          'line up with how you feel — will unlock here.',
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Premium users get fresh insights every 7 days.',
          style: FlutterFlowTheme.of(context).labelSmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
      ],
    );
  }

  // TEMPORARY dev-only helper: backfills a realistic ~90-day "average user"
  // history - covers the 30/60/90-day pattern windows, at ~82% logging
  // compliance (comfortably over the 80% periodHasEnoughData bar) so some
  // days come out genuinely missing, and with a mild/moderate/severe/
  // crystal value mix so spikeCount has a realistic chance of clearing the
  // analysisEligible bar too. Also backfills every currently-tracked
  // scale-type variable (boolean/numeric/time ones are skipped - the cloud
  // function doesn't bucket those into a severity dashboard at all), and
  // deliberately engineers ONE of them to lead headache_intensity by 2
  // days so the delayed-effect discovery card has something real to
  // surface - purely for this dev demo, not a claim about that metric.
  //
  // Fake diary_entries are tagged isDevSeed:true so re-running this is
  // safe: brand-new days get created fresh, previously-faked days get the
  // newly-tracked variables backfilled onto them, and real (non-tagged)
  // days are never touched. Remove this whole affordance once no longer
  // needed.
  Future<void> _seedAverageUserHistory(
    BuildContext context,
    List<String> existingDateKeys,
    List<String> trackedMetricKeys,
  ) async {
    // Defense in depth on top of the kDebugMode-gated button above and the
    // Firestore rule that now rejects client writes to `plan` - this must
    // never run (or grant premium) in a release build even if reached some
    // other way.
    if (!kDebugMode) return;
    setState(() => _seeding = true);
    try {
      // PatternInsightsPanel itself is gated behind a paying plan (see the
      // isPaying check above) - bump this dev account to premium too, so
      // seeding actually produces something visible instead of leaving the
      // paywall card up in front of freshly-seeded data. This write only
      // succeeds against the Firestore emulator / a rules deploy that still
      // allows it - production rules reject client-side `plan` changes.
      final user = await UsersRecord.getDocumentOnce(currentUserReference!);
      if (user.plan != 'core' && user.plan != 'premium') {
        await currentUserReference!.update({'plan': 'premium'});
      }
      await _runSeedAverageUserHistory(
          context, existingDateKeys, trackedMetricKeys);
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  // Batches every write (up to Firestore's 500-ops/batch limit) instead of
  // awaiting each .set() one at a time - with ~90 days x (1 entry + 1
  // headache response + N tracked-metric responses) that was several
  // hundred sequential round-trips and visibly slow.
  Future<void> _runSeedAverageUserHistory(
    BuildContext context,
    List<String> existingDateKeys,
    List<String> trackedMetricKeys,
  ) async {
    final existing = existingDateKeys.toSet();
    final rand = Random();
    var seededCount = 0;
    var skippedCount = 0;

    var batch = FirebaseFirestore.instance.batch();
    var opsInBatch = 0;
    Future<void> flushBatch() async {
      if (opsInBatch == 0) return;
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      opsInBatch = 0;
    }

    void batchSet(DocumentReference ref, Map<String, dynamic> data) {
      batch.set(ref, data, SetOptions(merge: true));
      opsInBatch++;
    }

    final activeMetrics = await queryMetricsRecordOnce(
      queryBuilder: (q) => q.where('isActive', isEqualTo: true),
    );
    // Split by answerType since each shape needs different fake data:
    // scale gets the same 0-10 severity distribution as headache, boolean
    // gets a weighted coin flip, numeric gets a uniform value across the
    // metric's own scaleMin/scaleMax. 'time' metrics (bed_time/wake_time)
    // are skipped - update_dashboard_metric.js doesn't compute a dashboard
    // doc for them either, so there'd be nothing to backfill toward.
    final trackedActive =
        activeMetrics.where((m) => trackedMetricKeys.contains(m.metricKey));
    final scaleMetrics = trackedActive
        .where((m) => m.answerType.isEmpty || m.answerType == 'scale')
        .toList();
    final booleanMetrics =
        trackedActive.where((m) => m.answerType == 'boolean').toList();
    final numericMetrics =
        trackedActive.where((m) => m.answerType == 'numeric').toList();
    final backfilledCount =
        scaleMetrics.length + booleanMetrics.length + numericMetrics.length;

    final correlatedKey = scaleMetrics.isEmpty
        ? null
        : (scaleMetrics.firstWhereOrNull((m) => m.metricKey == 'fatigue') ??
                scaleMetrics.firstWhereOrNull((m) =>
                    m.metricKey == 'insomnia' ||
                    m.metricKey == 'poor_sleep_quality') ??
                scaleMetrics.first)
            .metricKey;
    const correlatedLagDays = 2;

    // Days already faked (this run or a previous one) - safe to backfill
    // more metrics onto. Real user days are never in this set.
    final devSeededSnap = await FirebaseFirestore.instance
        .collection('diary_entries')
        .where('subjectId', isEqualTo: currentSubjectId)
        .where('isDevSeed', isEqualTo: true)
        .get();
    final devSeededKeys = {
      for (final d in devSeededSnap.docs)
        if (d.data()['entryDateKey'] != null)
          d.data()['entryDateKey'] as String,
    };

    // headache_intensity values (real + previously dev-seeded) across the
    // window, so the engineered lag can reference values that already
    // existed before this run, not only ones created in it.
    final headacheDashboards = await queryDashboardRecordOnce(
      queryBuilder: (q) => q
          .where('subjectId', isEqualTo: currentSubjectId)
          .where('metricKey', isEqualTo: 'headache_intensity')
          .where('periodType', isEqualTo: 'last90'),
    );
    final headacheByDate = <String, double>{
      for (final d in headacheDashboards.firstOrNull?.dailyValues ?? const [])
        if (d.isTracked) d.date: d.value,
    };

    int sampleValue() {
      final r = rand.nextDouble();
      if (r < 0.45) return 0; // symptom-free ("crystal") day
      if (r < 0.75) return 1 + rand.nextInt(3); // mild: 1-3
      if (r < 0.90) return 4 + rand.nextInt(3); // moderate: 4-6
      return 7 + rand.nextInt(4); // severe: 7-10
    }

    double correlatedValue(String dateKey) {
      final futureKey = dateTimeFormat(
        'yyyy-MM-dd',
        DateTime.parse(dateKey).add(const Duration(days: correlatedLagDays)),
      );
      final futureHeadache = headacheByDate[futureKey];
      if (futureHeadache == null) return sampleValue().toDouble();
      return (futureHeadache + (rand.nextDouble() * 4 - 2))
          .clamp(0, 10)
          .roundToDouble();
    }

    void queueTrackedMetrics(DocumentReference entryRef, String key) {
      for (final metric in scaleMetrics) {
        final value = metric.metricKey == correlatedKey
            ? correlatedValue(key)
            : sampleValue().toDouble();
        batchSet(
          ResponsesRecord.createDoc(entryRef, id: metric.metricKey),
          createResponsesRecordData(
            metricKey: metric.metricKey,
            metricLabel: metric.metricLabel,
            valueNumber: value,
          ),
        );
      }
      for (final metric in booleanMetrics) {
        batchSet(
          ResponsesRecord.createDoc(entryRef, id: metric.metricKey),
          createResponsesRecordData(
            metricKey: metric.metricKey,
            metricLabel: metric.metricLabel,
            valueNumber: rand.nextDouble() < 0.4 ? 1.0 : 0.0,
          ),
        );
      }
      for (final metric in numericMetrics) {
        final min = metric.scaleMin.toDouble();
        final max = metric.scaleMax > metric.scaleMin
            ? metric.scaleMax.toDouble()
            : min + 10.0;
        final value = min + rand.nextDouble() * (max - min);
        batchSet(
          ResponsesRecord.createDoc(entryRef, id: metric.metricKey),
          createResponsesRecordData(
            metricKey: metric.metricKey,
            metricLabel: metric.metricLabel,
            valueNumber: double.parse(value.toStringAsFixed(1)),
          ),
        );
      }
    }

    // Ascending so that when we reach day i and need headache_intensity
    // from day (i - correlatedLagDays) - a more recent day - it's already
    // been generated (smaller i's are processed first).
    final newDayKeys = <String>[];
    final backfillOnlyKeys = <String>[];
    for (var i = 1; i <= 90; i++) {
      final key = dateTimeFormat(
          'yyyy-MM-dd', DateTime.now().subtract(Duration(days: i)));
      if (!existing.contains(key)) {
        if (rand.nextDouble() > 0.82) {
          skippedCount++;
          continue; // left as a genuinely missing day
        }
        newDayKeys.add(key);
      } else if (devSeededKeys.contains(key)) {
        backfillOnlyKeys.add(key);
      }
      // else: a real, non-dev-seeded day - left untouched.
    }

    // Phase 1: create every new diary_entries parent doc and commit before
    // queuing any responses subcollection write. The responses rule checks
    // ownership via get(diary_entries/$(parent)).data.subjectId - security
    // rules only see already-committed state, never a sibling write from
    // the same batch, so creating a parent doc and its responses in one
    // batch made every responses write in that batch permission-denied
    // (and, since batches are all-or-nothing, rolled back the parent docs
    // too - every "new day" silently seeded nothing).
    for (final key in newDayKeys) {
      final date = DateTime.parse(key);
      final entryRef =
          DiaryEntriesRecord.collection.doc('${currentSubjectId}_$key');
      batchSet(entryRef, {
        ...createDiaryEntriesRecordData(
          subjectId: currentSubjectId,
          entryDateKey: key,
          entryDate: date,
          completedAt: date,
          isComplete: true,
          coinsEarned: 0,
        ),
        'isDevSeed': true,
      });
      if (opsInBatch >= 400) await flushBatch();
    }
    await flushBatch();

    // Phase 2: parent docs are now committed - safe to queue their
    // responses. Order matters here (not in phase 1): correlatedValue looks
    // up headacheByDate for a more recent date than the one it's computing,
    // so newDayKeys must stay in the same oldest-first-processed order it
    // was collected in.
    for (final key in newDayKeys) {
      final entryRef =
          DiaryEntriesRecord.collection.doc('${currentSubjectId}_$key');
      final headacheValue = sampleValue().toDouble();
      headacheByDate[key] = headacheValue;
      batchSet(
        ResponsesRecord.createDoc(entryRef, id: 'headache_intensity'),
        createResponsesRecordData(
          metricKey: 'headache_intensity',
          metricLabel: 'Headache intensity',
          valueNumber: headacheValue,
        ),
      );
      queueTrackedMetrics(entryRef, key);
      seededCount++;
      if (opsInBatch >= 400) await flushBatch();
    }
    for (final key in backfillOnlyKeys) {
      final entryRef =
          DiaryEntriesRecord.collection.doc('${currentSubjectId}_$key');
      queueTrackedMetrics(entryRef, key);
      if (opsInBatch >= 400) await flushBatch();
    }
    await flushBatch();

    if (context.mounted) {
      final correlatedLabel = correlatedKey == null
          ? null
          : scaleMetrics
              .firstWhere((m) => m.metricKey == correlatedKey)
              .metricLabel;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seeded $seededCount new days (skipped $skippedCount as '
            'missing), backfilled $backfilledCount tracked variable(s) '
            '(${scaleMetrics.length} scale, ${booleanMetrics.length} '
            'boolean, ${numericMetrics.length} numeric).'
            '${correlatedLabel != null ? ' "$correlatedLabel" engineered to lead headache by $correlatedLagDays days.' : ''}',
          ),
        ),
      );
    }
  }
}
