// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Shared header for the Results and Patterns tabs: orbit mark + title +
// subtitle on the left, a static "Your progress" badge on the right. Both
// pages used to have their own bespoke header (one had no subtitle/badge at
// all, the other showed the live selected period in the badge); this is the
// single version both now use so the two tabs read as one system.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      children: [
        const OrbitLogo(width: 32.0, height: 32.0),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: theme.headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: theme.headlineMedium.fontWeight,
                  ),
                  color: theme.primaryText,
                  fontSize: 19.0,
                ),
              ),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.0, color: theme.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        // Placeholder location badge - not wired to real data yet. Will
        // later show the user's set location and drive weather-linked
        // tracking (see dashboard/weather correlation work).
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A33),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14.0, color: theme.secondaryText),
              const SizedBox(width: 6.0),
              Text(
                'Set location',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
