import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_goals_model.dart';
export 'onboarding_goals_model.dart';

// First-run step, shown right after account creation: asks what the user
// wants to understand and pre-populates trackedMetricKeys accordingly, so
// the diary isn't a wall of 85 unrelated questions on day one.
class OnboardingGoalsWidget extends StatefulWidget {
  const OnboardingGoalsWidget({super.key});

  static String routeName = 'OnboardingGoals';
  static String routePath = '/onboardingGoals';

  @override
  State<OnboardingGoalsWidget> createState() => _OnboardingGoalsWidgetState();
}

class _OnboardingGoalsWidgetState extends State<OnboardingGoalsWidget> {
  late OnboardingGoalsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> _selectedGoals = {};
  bool _saving = false;

  static const _goals = [
    'Headaches',
    'Bloating',
    'Sleep',
    'Energy',
    'Brain fog',
    'Digestion',
    'Mood',
    'Focus',
    'Something else',
  ];

  // Curated starter metricKeys per goal. Headache/painkillers are always
  // tracked separately, so they're not listed here.
  static const _goalMetricKeys = {
    'Headaches': ['photophobia', 'phonophobia'],
    'Bloating': ['bloated', 'gas', 'abdominal_pain', 'constipation'],
    'Sleep': [
      'insomnia',
      'poor_sleep_quality',
      'hours_slept',
      'bed_time',
      'wake_time',
      'lethargy',
    ],
    'Energy': ['energy', 'fatigue', 'lethargy'],
    'Brain fog': [
      'brain_fog',
      'memory_problems',
      'word_finding_difficulties',
      'focus',
      'mental_clarity',
    ],
    'Digestion': [
      'nausea',
      'bloated',
      'gas',
      'constipation',
      'diarrhoea',
      'reflux',
      'abdominal_pain',
      'bowel_urgency',
      'stool_quality',
    ],
    'Mood': ['happiness', 'sadness', 'low_mood', 'irritability', 'stress'],
    'Focus': ['focus', 'mental_clarity', 'brain_fog', 'productivity'],
    'Something else': <String>[],
  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingGoalsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (currentUserReference == null || _saving) return;
    setState(() => _saving = true);

    final metricKeys = <String>{
      for (final goal in _selectedGoals) ...?_goalMetricKeys[goal],
    };

    await currentUserReference!.update({
      'trackedMetricKeys': metricKeys.toList(),
    });

    if (mounted) {
      context.goNamed(LocationPermissionPageWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What would you like to understand?',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 24.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick as many as you like — you can always change this '
                'later in Settings.',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: _goals.map((goal) {
                      final selected = _selectedGoals.contains(goal);
                      return InkWell(
                        onTap: () => setState(() {
                          selected
                              ? _selectedGoals.remove(goal)
                              : _selectedGoals.add(goal);
                        }),
                        borderRadius: BorderRadius.circular(24.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: selected
                                ? FlutterFlowTheme.of(context).primary
                                : FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: selected
                                  ? FlutterFlowTheme.of(context).primary
                                  : FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            goal,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : FlutterFlowTheme.of(context).primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.0),
                    ),
                  ),
                  child: Text(
                    _selectedGoals.isEmpty ? 'Skip for now' : 'Continue',
                    style: const TextStyle(
                        fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
