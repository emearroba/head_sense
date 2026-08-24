import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as custom_functions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'results_model.dart';
export 'results_model.dart';

// Free section: 100-day progress path, logging streak, coins, and how many
// more days until pattern analysis unlocks (30d tentative / 90d confirmed).
// Below that, the actual pattern analysis (Your Pattern / What Seems
// Connected / How You're Changing / Worth Watching) is a locked premium
// placeholder until payment infra is wired up.
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

  // Milestones match the period-selector groups (30/60/90 days). Coin
  // awarding for these lives solely in the Dashboard's TrackingProgressCard
  // (lib/custom_code/widgets/tracking_progress_card.dart) to avoid
  // double-awarding; this page only mirrors the same progress visually.
  static const _milestones = [30, 60, 90];

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
                final streak =
                    custom_functions.calculateLoggingStreak(dateKeys);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 120.0),
                  children: [
                    _progressPath(context, totalDays),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _bigStat(
                            context,
                            icon: Icons.local_fire_department,
                            iconColor: const Color(0xFFE67532),
                            value: '$streak',
                            label: streak == 1 ? 'day streak' : 'day streak',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _bigStat(
                            context,
                            icon: Icons.monetization_on,
                            iconColor: const Color(0xFFFFC533),
                            value: '${user.coins}',
                            label: 'coins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _unlockMessage(context, totalDays),
                    const SizedBox(height: 28),
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

  Widget _progressPath(BuildContext context, int totalDays) {
    final capped = totalDays.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your 100-day journey',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '$capped / 100 days',
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: capped / 100,
              minHeight: 10.0,
              backgroundColor: const Color(0xFF1A2A33),
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _milestones.map((m) {
              final reached = totalDays >= m;
              return Text(
                '$m',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                  color: reached
                      ? FlutterFlowTheme.of(context).primary
                      : FlutterFlowTheme.of(context).secondaryText,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bigStat(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26.0),
          const SizedBox(height: 6),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.inter(),
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ),
        ],
      ),
    );
  }

  Widget _unlockMessage(BuildContext context, int totalDays) {
    String message;
    if (totalDays < 30) {
      final remaining = 30 - totalDays;
      message = '$remaining more day${remaining == 1 ? '' : 's'} of tracking '
          'to start seeing early patterns.';
    } else if (totalDays < 90) {
      final remaining = 90 - totalDays;
      message = 'You have enough data for early patterns. $remaining more '
          'day${remaining == 1 ? '' : 's'} to confirm them with confidence.';
    } else {
      message = 'You have enough data for confirmed patterns.';
    }
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0x1A36D6D6),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline,
              color: FlutterFlowTheme.of(context).primary, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
          ),
        ],
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
      ],
    );
  }
}
