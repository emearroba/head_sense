import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/custom_code/health_sync_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_model.dart';
export 'settings_model.dart';

// Hub for things that used to live in the bottom nav (Track, Reminders) but
// aren't used often enough to deserve a permanent tab.
class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late SettingsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsModel());
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
        title: Text(
          'Settings',
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _settingsTile(
              context,
              icon: Icons.tune,
              title: 'Track your variables',
              subtitle: 'Choose which symptoms and predictors to log',
              onTap: () => context.pushNamed(TrackVariablesWidget.routeName),
            ),
            const SizedBox(height: 12),
            _settingsTile(
              context,
              icon: Icons.access_alarm_sharp,
              title: 'Reminders',
              subtitle: 'Configure your daily diary reminders',
              onTap: () => context.pushNamed(RemindersWidget.routeName),
            ),
            const SizedBox(height: 12),
            _settingsTile(
              context,
              icon: Icons.medication_outlined,
              title: 'Interventions',
              subtitle: 'Medications, doses, and diet types you\'re using',
              onTap: () => context.pushNamed(InterventionsWidget.routeName),
            ),
            if (HealthSyncService.instance.isSupported) ...[
              const SizedBox(height: 28),
              _sectionTitle(context, 'Connected Health'),
              const SizedBox(height: 12),
              _healthSyncCard(context),
            ],
            const SizedBox(height: 28),
            _sectionTitle(context, 'Your Profile'),
            const SizedBox(height: 12),
            _profileCard(context),
            const SizedBox(height: 12),
            _signOutTile(context),
            const SizedBox(height: 28),
            _sectionTitle(context, 'Available Studies'),
            const SizedBox(height: 12),
            _availableStudiesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: FlutterFlowTheme.of(context).titleSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: FlutterFlowTheme.of(context).secondaryText,
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _profileCard(BuildContext context) {
    if (currentUserReference == null) return const SizedBox.shrink();
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final user = userSnapshot.data!;
        final planLabel = user.plan.isEmpty ? 'Free' : user.plan;
        final locationLabel =
            user.locationLabel.isEmpty ? 'Not set' : user.locationLabel;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileRow(context, Icons.workspace_premium_outlined, 'Plan',
                  planLabel),
              const SizedBox(height: 12),
              _profileRow(
                context,
                Icons.location_on_outlined,
                'Location',
                locationLabel,
                onTap: () => _editLocation(context, user.locationLabel),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<StudiesRecord>>(
                stream: queryStudiesRecord(),
                builder: (context, studiesSnapshot) {
                  final joinedNames = (studiesSnapshot.data ?? [])
                      .where((s) => user.joinedStudyIds.contains(s.reference.id))
                      .map((s) => s.studyName)
                      .where((n) => n.isNotEmpty)
                      .toList();
                  return _profileRow(
                    context,
                    Icons.science_outlined,
                    'Studies',
                    joinedNames.isEmpty ? 'None yet' : joinedNames.join(', '),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileRow(
      BuildContext context, IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 20.0),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                    ),
              ),
              Text(
                value,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.edit_outlined,
              color: FlutterFlowTheme.of(context).secondaryText, size: 18.0),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: row,
    );
  }

  Widget _healthSyncCard(BuildContext context) {
    if (currentUserReference == null) return const SizedBox.shrink();
    final service = HealthSyncService.instance;

    return ListenableBuilder(
      listenable: FFAppState(),
      builder: (context, _) {
        final enabled = FFAppState().healthSyncEnabled;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      color: FlutterFlowTheme.of(context).primary, size: 20.0),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync with ${service.platformLabel}',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                    color:
                                        FlutterFlowTheme.of(context).primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          'Bring in sleep, steps and resting heart rate automatically',
                          style:
                              FlutterFlowTheme.of(context).labelSmall.override(
                                    font: GoogleFonts.inter(),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (value) => _toggleHealthSync(context, value),
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _syncHealthNow(context),
                  child: Row(
                    children: [
                      Icon(Icons.sync,
                          color: FlutterFlowTheme.of(context).primary,
                          size: 18.0),
                      const SizedBox(width: 8),
                      Text(
                        'Sync now',
                        style:
                            FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600),
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: FlutterFlowTheme.of(context).alternate),
                const SizedBox(height: 4),
                StreamBuilder<UsersRecord>(
                  stream: UsersRecord.getDocument(currentUserReference!),
                  builder: (context, userSnapshot) {
                    final consent =
                        userSnapshot.data?.healthDataResearchConsent ?? false;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Allow this data to be used for research',
                            style: FlutterFlowTheme.of(context)
                                .labelSmall
                                .override(
                                  font: GoogleFonts.inter(),
                                  color:
                                      FlutterFlowTheme.of(context).secondaryText,
                                ),
                          ),
                        ),
                        Switch(
                          value: consent,
                          onChanged: (value) =>
                              currentUserReference!.update({
                            'healthDataResearchConsent': value,
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleHealthSync(BuildContext context, bool value) async {
    final service = HealthSyncService.instance;

    if (!value) {
      FFAppState().healthSyncEnabled = false;
      if (currentUserReference != null) {
        await currentUserReference!.update({
          'trackedMetricKeys':
              FieldValue.arrayRemove(HealthSyncService.trackedMetricKeys),
        });
      }
      return;
    }

    if (!await service.isAvailable()) {
      await service.promptInstall();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Install ${service.platformLabel} first, then try again'),
          ),
        );
      }
      return;
    }

    final granted = await service.requestPermissions();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission was not granted')),
        );
      }
      return;
    }

    FFAppState().healthSyncEnabled = true;
    if (currentUserReference != null) {
      await currentUserReference!.update({
        'trackedMetricKeys':
            FieldValue.arrayUnion(HealthSyncService.trackedMetricKeys),
      });
    }
    if (!context.mounted) return;
    await _syncHealthNow(context, lookback: const Duration(days: 30));
  }

  Future<void> _syncHealthNow(BuildContext context,
      {Duration lookback = const Duration(days: 7)}) async {
    final count = await HealthSyncService.instance
        .syncRecentData(lookback: lookback);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $count health samples')),
      );
    }
  }

  Widget _signOutTile(BuildContext context) {
    return InkWell(
      onTap: () => _confirmSignOut(context),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            Icon(Icons.logout,
                color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Sign out',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: FlutterFlowTheme.of(context).secondaryText),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Text(
          'Sign out?',
          style: FlutterFlowTheme.of(context).titleSmall.override(
                fontWeight: FontWeight.w600,
                color: FlutterFlowTheme.of(context).primaryText,
              ),
        ),
        content: Text(
          'You\'ll need to sign in again to access your account.',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Sign out',
                style: TextStyle(
                    color: FlutterFlowTheme.of(context).error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await authManager.signOut();
      if (context.mounted) {
        context.goNamed(AuthenticationWidget.routeName);
      }
    }
  }

  Future<void> _editLocation(BuildContext context, String currentLabel) async {
    final controller = TextEditingController(text: currentLabel);
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            'Your location',
            style: FlutterFlowTheme.of(context).titleSmall.override(
                  fontWeight: FontWeight.w600,
                  color: FlutterFlowTheme.of(context).primaryText,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. "London"',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                final city = controller.text.trim();
                if (city.isEmpty) return;
                setDialogState(() => error = null);
                final response = await WeatherrCall.call(city: city);
                if (!response.succeeded) {
                  setDialogState(() => error =
                      "Couldn't find that city. Check the spelling.");
                  return;
                }
                final resolvedCity =
                    WeatherrCall.cityWeather(response.jsonBody) ?? city;
                final lat = WeatherrCall.lat(response.jsonBody);
                final lon = WeatherrCall.lon(response.jsonBody);
                await currentUserReference!.update({
                  'locationLabel': resolvedCity,
                  if (lat != null && lon != null)
                    'userTimezone': LatLng(lat, lon),
                });
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('Save',
                  style: TextStyle(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated')),
      );
    }
  }

  Widget _availableStudiesCard(BuildContext context) {
    if (currentUserReference == null) return const SizedBox.shrink();
    return StreamBuilder<UsersRecord>(
      stream: UsersRecord.getDocument(currentUserReference!),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final joinedStudyIds = userSnapshot.data!.joinedStudyIds;

        return StreamBuilder<List<StudiesRecord>>(
          stream: queryStudiesRecord(
            queryBuilder: (q) => q.where('isActive', isEqualTo: true),
          ),
          builder: (context, studiesSnapshot) {
            if (!studiesSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final available = studiesSnapshot.data!
                .where((s) => !joinedStudyIds.contains(s.reference.id))
                .toList();

            if (available.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).alternate,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'No studies are currently available to join.',
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              );
            }

            return Column(
              children: available
                  .map((study) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _studyTile(context, study),
                      ))
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _studyTile(BuildContext context, StudiesRecord study) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
          Icon(Icons.science_outlined,
              color: FlutterFlowTheme.of(context).primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              study.studyName.isEmpty ? 'Untitled study' : study.studyName,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(
            onPressed: () => _joinStudy(context, study),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinStudy(BuildContext context, StudiesRecord study) async {
    if (currentUserReference == null) return;
    await currentUserReference!.update({
      'joinedStudyIds': FieldValue.arrayUnion([study.reference.id]),
      'studyParticipant': true,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined ${study.studyName}')),
      );
    }
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
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
            Icon(icon, color: FlutterFlowTheme.of(context).primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: FlutterFlowTheme.of(context).secondaryText),
          ],
        ),
      ),
    );
  }
}
