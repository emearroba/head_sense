import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Bump this (and the "Last updated" line in both section lists below)
// whenever _termsSections/_privacySections materially change, so
// UsersRecord.termsVersion (written at signup - see
// authentication_widget.dart) records which version a given user agreed
// to.
const String kLegalVersion = '2026-09-14';

class LegalWidget extends StatelessWidget {
  const LegalWidget({super.key});

  static String routeName = 'Legal';
  static String routePath = '/legal';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryText),
        title: Text(
          'Terms & Privacy',
          style: theme.titleMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            color: theme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _sectionHeading(theme, 'Terms of Service'),
            const SizedBox(height: 12.0),
            ..._termsSections.map((s) => _paragraph(theme, s)),
            const SizedBox(height: 32.0),
            _sectionHeading(theme, 'Privacy Policy'),
            const SizedBox(height: 12.0),
            ..._privacySections.map((s) => _paragraph(theme, s)),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(FlutterFlowTheme theme, String text) {
    return Text(
      text,
      style: theme.titleMedium.override(
        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        color: theme.primaryText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _paragraph(FlutterFlowTheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Text(
        text,
        style: theme.bodyMedium.override(
          color: theme.secondaryText,
          lineHeight: 1.5,
        ),
      ),
    );
  }

  static const List<String> _termsSections = [
    'Last updated: September 14, 2026 — version $kLegalVersion.',
    '1. Acceptance. By creating an account you agree to these Terms and to '
        'the Privacy Policy below. If you do not agree, do not use the app.',
    '2. Not medical advice. Somatica helps you track symptoms, triggers, '
        'and patterns. It is not a medical device, does '
        'not diagnose any condition, and nothing shown in the app — '
        'including charts, streaks, or "pattern" correlations — is medical '
        'advice. Always talk to a qualified doctor about your symptoms and '
        'before changing any treatment.',
    '3. Eligibility. You must be at least 18 years old to create an '
        'account. Somatica is not directed at, and does not knowingly '
        'collect data from, anyone under 18.',
    '4. Your account. You are responsible for keeping your login '
        'credentials secure and for all activity under your account. You '
        'can delete your account and all associated data at any time from '
        'Settings.',
    '5. Research participation. Enrolling in a study, or turning on '
        '"Allow this data to be used for research" in Settings, is '
        'optional and can be withdrawn at any time by leaving the study or '
        'turning the setting back off. Each study you can join in the app '
        'describes its own specific purpose and data use before you enroll.',
    '6. Fees. Somatica is a paid app. Current pricing and any free trial '
        'are shown in the App Store / Play Store listing and inside the '
        'app before you\'re charged. Purchases and subscriptions are '
        'billed and managed through Apple\'s or Google\'s standard in-app '
        'purchase system — you can view, change, or cancel a subscription '
        'at any time from your Apple ID / Google Play account settings. '
        'We\'ll update these Terms if the pricing model materially '
        'changes.',
    '7. No warranty; limitation of liability. Somatica is provided "as '
        'is" and "as available," without warranties of any kind, to the '
        'maximum extent permitted by applicable law. We are not liable for '
        'any indirect, incidental, or consequential damages arising from '
        'your use of the app, including decisions made based on data or '
        'patterns it shows you. Nothing in these Terms limits liability '
        'that cannot be limited under the law that applies to you.',
    '8. Governing law. These Terms don\'t designate a specific country or '
        'state\'s law to govern them; whatever consumer-protection and '
        'other laws apply in your place of residence apply to your use of '
        'the app.',
    '9. Changes to these Terms. If we make a material change, we\'ll ask '
        'you to review and accept the updated Terms the next time you open '
        'the app before you can continue using it.',
    '10. Contact. Questions about these Terms: picklelabs.support@gmail.com.',
  ];

  static const List<String> _privacySections = [
    'Last updated: September 14, 2026 — version $kLegalVersion.',
    '1. What we collect. Account info (email); diary entries you log '
        '(symptom severity, triggers, medication use); if you connect '
        'Apple Health / Health Connect, read-only sleep, steps, and heart '
        'rate data; app diagnostics (crash reports, performance data) via '
        'Firebase Crashlytics/Performance.',
    '2. How it\'s used. To show your own diary, dashboard, and pattern '
        'insights back to you; to send reminders you set up; and, only if '
        'you opt in, for research (see Terms §5). Health data read from '
        'Apple Health / Health Connect is used solely to find patterns '
        'with your own symptoms — it is never sold, and never used for '
        'advertising or shared with data brokers.',
    '3. Where it\'s stored. Your diary, dashboard, and health data are '
        'stored in Google Firebase/Firestore, keyed by a random '
        'pseudonymous identifier rather than your account directly, and '
        'protected by access rules that only let your own account read or '
        'write it.',
    '4. Who else sees it. Google/Firebase (our hosting and backend '
        'provider) processes data on our behalf as required to run the '
        'app. Purchases are handled entirely by Apple\'s or Google\'s '
        'in-app purchase systems — we never see or store your payment '
        'details. We do not integrate any advertising network or '
        'third-party AI service, so no data is shared with one. We '
        'don\'t sell your data to anyone.',
    '5. Data retention. We keep your data as long as your account exists. '
        'You can permanently delete your account and everything tied to '
        'it — diary entries, dashboard history, reminders, and any '
        'connected health data — at any time from Settings → Delete '
        'account. This cannot be undone.',
    '6. Your rights. You can view all of your own data in the app at any '
        'time. In-app export isn\'t built yet — until it is, email '
        'picklelabs.support@gmail.com and we\'ll send you a copy of your '
        'data manually. Account deletion (above) is available in-app '
        'today.',
    '7. Children\'s privacy. Somatica is not directed at children and '
        'requires users to be 18+ (see Terms §3). If we learn a user is '
        'under 18, we\'ll delete that account and its data.',
    '8. International users. Somatica is hosted on Google Firebase\'s '
        'infrastructure, which may process data outside your own country. '
        'By using the app you consent to that transfer.',
    '9. Changes to this policy. If we make a material change, we\'ll ask '
        'you to review and accept the updated policy the next time you '
        'open the app before you can continue using it.',
    '10. Contact. Privacy questions or data requests: '
        'picklelabs.support@gmail.com.',
  ];
}
