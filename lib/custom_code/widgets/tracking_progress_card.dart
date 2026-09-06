// Automatic FlutterFlow imports
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/custom_functions.dart' as custom_functions;
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Progress module surfaced at the top of the Patterns tab: the 100-day
// progress bar, day streak / days tracked / days to insights / coins, and
// the "N more days" message. Self-contained (queries diary_entries + the
// user doc itself).
//
// Also the sole place that awards milestone coins (every 30 logged days,
// matching the period-selector groups) and pops the milestone celebration
// modal.
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
                              'signal for reliable patterns. Open Insights '
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              isSubscribed ? 'View patterns' : 'See patterns',
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
            final streak = custom_functions.calculateLoggingStreak(dateKeys);
            final daysToInsights = totalDays < 30
                ? 30 - totalDays
                : (totalDays < 90 ? 90 - totalDays : 0);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _maybeAwardMilestone(user, totalDays, streak);
            });

            final theme = FlutterFlowTheme.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          context,
                          Icons.local_fire_department,
                          const Color(0xFFE67532),
                          '$streak',
                          'day streak',
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          Icons.calendar_today,
                          theme.primary,
                          '$totalDays',
                          'days tracked',
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          Icons.show_chart,
                          const Color(0xFF8D8FD6),
                          '$daysToInsights',
                          'days to insights',
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          Icons.monetization_on,
                          const Color(0xFFFFC533),
                          '$coins',
                          'coins',
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalDays < 90) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    _message(totalDays),
                    style:
                        TextStyle(fontSize: 10.0, color: theme.secondaryText),
                  ),
                ],
              ],
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

  Widget _miniStat(
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
}
