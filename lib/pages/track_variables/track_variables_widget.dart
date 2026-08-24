import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'track_variables_model.dart';
export 'track_variables_model.dart';

// Lets the user pick which predictors/outcomes they want on their diary,
// beyond the always-on headache + painkiller tracking. Replaces the old
// static "Tasks" tab.
class TrackVariablesWidget extends StatefulWidget {
  const TrackVariablesWidget({super.key});

  static String routeName = 'TrackVariables';
  static String routePath = '/trackVariables';

  @override
  State<TrackVariablesWidget> createState() => _TrackVariablesWidgetState();
}

class _TrackVariablesWidgetState extends State<TrackVariablesWidget> {
  late TrackVariablesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Always tracked, not user-togglable.
  static const _alwaysOnKeys = {'headache_intensity', 'analgesia'};

  // Display order + labels for outcome domains; anything else falls back
  // to its raw domain string (or "Other" if blank).
  static const _domainOrder = [
    'headache',
    'medication',
    'sensitivities',
    'perceptions',
    'productivity',
    'mood',
    'sleep_fatigue',
    'gi',
    'food_cravings',
    'genito_urinary',
    'ent_physical',
    'physical',
    'exercise',
  ];
  static const _domainLabels = {
    'headache': 'Headache',
    'medication': 'Medication',
    'sensitivities': 'Sensitivities',
    'perceptions': 'Perceptions',
    'productivity': 'Productivity',
    'mood': 'Mood & Social',
    'sleep_fatigue': 'Sleep & Fatigue',
    'gi': 'Gastrointestinal',
    'food_cravings': 'Food, Drinks and Cravings',
    'genito_urinary': 'Genito-urinary',
    'ent_physical': 'Head and Neck Symptoms',
    'physical': 'Physical',
    'exercise': 'Exercise',
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TrackVariablesModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _setTracked(String metricKey, bool tracked) async {
    if (currentUserReference == null) return;
    await currentUserReference!.update({
      'trackedMetricKeys': tracked
          ? FieldValue.arrayUnion([metricKey])
          : FieldValue.arrayRemove([metricKey]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        title: Text(
          'Track',
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
            final trackedKeys =
                userSnapshot.data!.trackedMetricKeys.toSet();

            return StreamBuilder<List<MetricsRecord>>(
              stream: queryMetricsRecord(
                queryBuilder: (metricsRecord) => metricsRecord
                    .where('isActive', isEqualTo: true)
                    .orderBy('order'),
              ),
              builder: (context, metricsSnapshot) {
                if (!metricsSnapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  );
                }
                final metrics = metricsSnapshot.data!;

                final byDomain = <String, List<MetricsRecord>>{};
                for (final m in metrics) {
                  final domain = m.domain.isEmpty ? 'other' : m.domain;
                  byDomain.putIfAbsent(domain, () => []).add(m);
                }
                final orderedDomains = [
                  ..._domainOrder.where(byDomain.containsKey),
                  ...byDomain.keys.where((d) => !_domainOrder.contains(d)),
                ];

                final totalTracked = trackedKeys.length + _alwaysOnKeys.length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
                  children: [
                    Text(
                      'Choose what you want to track each day. Headache and '
                      'painkillers are always included.',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    if (totalTracked > 30) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFC533),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: const Color(0xFFFFC533),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFFFFC533), size: 18.0),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'You\'re tracking $totalTracked variables — '
                                'daily entries get harder to keep up with '
                                'past 30. Consider trimming to what matters '
                                'most right now.',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: const Color(0xFFFFC533),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    for (final domain in orderedDomains) ...[
                      const SizedBox(height: 20),
                      _sectionHeader(
                        context,
                        _domainLabels[domain] ?? 'Other',
                      ),
                      ...byDomain[domain]!
                          .map((m) => _metricTile(context, m, trackedKeys)),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: FlutterFlowTheme.of(context).titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: FlutterFlowTheme.of(context).primaryText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _metricTile(
    BuildContext context,
    MetricsRecord metric,
    Set<String> trackedKeys,
  ) {
    final isLocked = _alwaysOnKeys.contains(metric.metricKey);
    final isOn = isLocked || trackedKeys.contains(metric.metricKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.metricLabel,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (isLocked)
                  Text(
                    'Always tracked',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeThumbColor: FlutterFlowTheme.of(context).primary,
            onChanged: isLocked
                ? null
                : (value) => _setTracked(metric.metricKey, value),
          ),
        ],
      ),
    );
  }
}
