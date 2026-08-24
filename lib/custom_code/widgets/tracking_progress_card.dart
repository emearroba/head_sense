// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/results/results_widget.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart' as custom_functions;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Compact version of the Patterns tab's progress module, surfaced at the top
// of the Dashboard: the 100-day progress bar, day streak / days tracked /
// days to insights / coins, and the same "N more days" message.
// Self-contained (queries diary_entries + the user doc itself).
//
// Also the sole place that awards milestone coins (every 30 logged days,
// matching the period-selector groups) and pops the milestone celebration
// modal, so award logic can't double-fire between here and the Patterns tab.
class TrackingProgressCard extends StatefulWidget {
  const TrackingProgressCard({super.key});

  @override
  State<TrackingProgressCard> createState() => _TrackingProgressCardState();
}

class _TrackingProgressCardState extends State<TrackingProgressCard> {
  static const _milestones = [30, 60, 90];
  static const _coinsPerMilestone = 30;

  Future<void> _maybeAwardMilestone(
    UsersRecord user,
    int totalDays,
    int streak,
  ) async {
    final claimed = user.milestoneCoinsClaimed;
    final eligible = _milestones
        .where((m) => totalDays >= m)
        .fold<int>(0, (best, m) => m > best ? m : best);
    if (eligible <= claimed) return;

    await user.reference.update({
      'coins': FieldValue.increment(_coinsPerMilestone),
      'milestoneCoinsClaimed': eligible,
    });

    if (!mounted) return;
    final isSubscribed = user.plan.isNotEmpty && user.plan != 'free';
    _showMilestoneModal(
      context,
      eligible,
      totalDays: totalDays,
      streak: streak,
      isSubscribed: isSubscribed,
    );
  }

  void _showMilestoneModal(
    BuildContext context,
    int milestone, {
    required int totalDays,
    required int streak,
    required bool isSubscribed,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: Color(0xFFFFC533)),
            const SizedBox(width: 8.0),
            Text(
              '$milestone-day milestone!',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontWeight: FontWeight.w600,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve logged $totalDays days, with a $streak-day streak '
              'going. A new Patterns report just unlocked for this cycle.',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSubscribed
                    ? const Color(0x1A36D6D6)
                    : const Color(0x1AFFC533),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isSubscribed
                      ? FlutterFlowTheme.of(context).primary
                      : const Color(0xFFFFC533),
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSubscribed ? Icons.insights : Icons.workspace_premium,
                    color: isSubscribed
                        ? FlutterFlowTheme.of(context).primary
                        : const Color(0xFFFFC533),
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      isSubscribed
                          ? 'Preview: your $streak-day streak is a strong '
                              'signal for reliable patterns. Open Patterns '
                              'to see the full report.'
                          : 'Subscribe to unlock this cycle\'s Pattern '
                              'Analysis report and see what your data shows.',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            color: FlutterFlowTheme.of(context).primaryText,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Not now',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.pushNamed(ResultsWidget.routeName);
            },
            child: Text(
              isSubscribed ? 'View in Patterns' : 'See Patterns',
              style: TextStyle(
                color: FlutterFlowTheme.of(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox.shrink();
        final user = userSnapshot.data!;
        final coins = user.coins;

        return StreamBuilder<List<DiaryEntriesRecord>>(
          stream: queryDiaryEntriesRecord(
            queryBuilder: (q) => q
                .where('userRef', isEqualTo: currentUserReference)
                .where('isComplete', isEqualTo: true),
          ),
          builder: (context, snapshot) {
            final dateKeys = (snapshot.data ?? [])
                .map((e) => e.entryDateKey)
                .where((k) => k.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final totalDays = dateKeys.length;
            final capped = totalDays.clamp(0, 100);
            final streak = custom_functions.calculateLoggingStreak(dateKeys);
            final daysToInsights = totalDays < 30
                ? 30 - totalDays
                : (totalDays < 90 ? 90 - totalDays : 0);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _maybeAwardMilestone(user, totalDays, streak);
            });

            return Container(
              width: double.infinity,
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
                  Text(
                    'Tracking Progress',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          fontWeight: FontWeight.w600,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Day $capped',
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                      Text(
                        '$capped / 100 days',
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
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
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _milestones.map((m) {
                      final reached = totalDays >= m;
                      return Text(
                        '$m',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              reached ? FontWeight.bold : FontWeight.normal,
                          color: reached
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).secondaryText,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14.0),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(context, Icons.local_fire_department,
                            const Color(0xFFE67532), '$streak', 'day streak'),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _tile(
                            context,
                            Icons.calendar_today,
                            FlutterFlowTheme.of(context).primary,
                            '$totalDays',
                            'days tracked'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                        child: _tile(
                            context,
                            Icons.show_chart,
                            const Color(0xFF8D8FD6),
                            '$daysToInsights',
                            'days to insights'),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: _tile(context, Icons.monetization_on,
                            const Color(0xFFFFC533), '$coins', 'coins'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    _message(totalDays),
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _message(int totalDays) {
    if (totalDays < 30) {
      final remaining = 30 - totalDays;
      return '$remaining more day${remaining == 1 ? '' : 's'} of tracking '
          'to start seeing early patterns.';
    } else if (totalDays < 90) {
      final remaining = 90 - totalDays;
      return '$remaining more day${remaining == 1 ? '' : 's'} to confirm '
          'your patterns with more confidence.';
    }
    return 'You have enough data for confirmed patterns.';
  }

  Widget _tile(BuildContext context, IconData icon, Color color, String value,
      String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A33),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.0),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 9.0),
          ),
        ],
      ),
    );
  }
}
