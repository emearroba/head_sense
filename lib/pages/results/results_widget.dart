import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        automaticallyImplyLeading: false,
        title: Text(
          'Patterns',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                font: GoogleFonts.interTight(
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 22.0,
              ),
        ),
        elevation: 0.0,
      ),
      body: SafeArea(
        child: StreamBuilder<UsersRecord>(
          stream: UsersRecord.getDocument(currentUserReference!),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              );
            }
            final user = userSnapshot.data!;
            final isPaying = user.plan == 'core' || user.plan == 'premium';

            return StreamBuilder<List<DiaryEntriesRecord>>(
              stream: queryDiaryEntriesRecord(
                queryBuilder: (q) => q
                    .where('userRef', isEqualTo: currentUserReference)
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
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 120.0),
                  children: [
                    const custom_widgets.TrackingProgressCard(),
                    const SizedBox(height: 28),
                    if (isPaying)
                      custom_widgets.PatternInsightsPanel(
                        trackedMetricKeys: user.trackedMetricKeys,
                        userPlan: user.plan,
                      )
                    else
                      _lockedAnalysisCard(context, totalDays),
                  ],
                );
              },
            );
          },
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
          'Your Pattern, What Seems Connected, How You\'re Changing, and '
          'Worth Watching will unlock here.',
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
}
