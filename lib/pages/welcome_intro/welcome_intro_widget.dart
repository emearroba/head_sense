import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _IntroSlide {
  final String title;
  final String description;
  const _IntroSlide(this.title, this.description);
}

const List<_IntroSlide> _kSlides = [
  _IntroSlide(
    'Welcome to Somatica',
    'A simple way to track your symptoms and understand your body\'s '
        'patterns over time.',
  ),
  _IntroSlide(
    'Log a few symptoms each day',
    'A quick daily check-in — severity, triggers, sleep, medication. '
        'Takes under a minute.',
  ),
  _IntroSlide(
    'See your dashboard',
    'Watch trends, streaks, and severity over the last 30, 90, or 365 '
        'days, all in one place.',
  ),
  _IntroSlide(
    'Discover patterns',
    'Somatica looks for connections between your symptoms and things '
        'like sleep, stress, or the weather — general information, not a '
        'diagnosis. Always talk to your doctor about what you find.',
  ),
  _IntroSlide(
    'Stay consistent',
    'Set a daily reminder so logging becomes a habit — the more you '
        'track, the clearer the picture.',
  ),
];

// First-run "what does this app do" walkthrough, shown once per device
// before Authentication (see FFAppState.hasSeenWelcomeIntro and its use in
// nav.dart's root route) - distinct from OnboardingGoalsWidget, which runs
// right after signup and asks what to personalize, not what the app does.
class WelcomeIntroWidget extends StatefulWidget {
  const WelcomeIntroWidget({super.key});

  static String routeName = 'WelcomeIntro';
  static String routePath = '/welcomeIntro';

  @override
  State<WelcomeIntroWidget> createState() => _WelcomeIntroWidgetState();
}

class _WelcomeIntroWidgetState extends State<WelcomeIntroWidget> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    FFAppState().hasSeenWelcomeIntro = true;
    // Reachable two ways: as the very first screen (no back stack - a
    // logged-out user finishing it should land on Authentication) or pushed
    // from Settings → "How Somatica works" by an already-logged-in user
    // (who should just return to Settings, not get bounced to sign-in).
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.goNamed(AuthenticationWidget.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isLast = _page == _kSlides.length - 1;
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0, top: 4.0),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: theme.bodyMedium.override(
                      color: theme.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: custom_widgets.IntroOrbitConnector(
                activeIndex: _page,
                count: _kSlides.length,
                size: 176.0,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _kSlides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final slide = _kSlides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          // Caps line length on wide/web viewports - full-width
                          // text at desktop widths was hard to read.
                          constraints: const BoxConstraints(maxWidth: 440.0),
                          child: Column(
                            children: [
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: theme.headlineMedium.override(
                                  font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700),
                                  color: theme.primaryText,
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: theme.bodyMedium.override(
                                  color: theme.secondaryText,
                                  lineHeight: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_kSlides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: active ? 20.0 : 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    color: active ? theme.primary : theme.alternate,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.0),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get started' : 'Next',
                    style: const TextStyle(
                        fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
