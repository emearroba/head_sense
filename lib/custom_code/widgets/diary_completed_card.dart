// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

// Shared visual layout for the "diary completed" moment (used by both the
// fresh-completion screen and the already-completed-today screen) so they
// stay in sync with the login screen's design system.
class DiaryCompletedCard extends StatelessWidget {
  const DiaryCompletedCard({
    super.key,
    required this.onGoToDashboard,
    required this.onEditDiary,
  });

  final VoidCallback onGoToDashboard;
  final VoidCallback onEditDiary;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final formattedDate = dateTimeFormat('EEEE, d MMMM', getCurrentTimestamp);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: theme.alternate, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OrbitCelebrationAnimation(width: 140.0, height: 140.0),
                const SizedBox(height: 20.0),
                Text(
                  'Diary completed',
                  textAlign: TextAlign.center,
                  style: theme.headlineMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500),
                    color: theme.primaryText,
                    fontSize: 24.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Your symptoms have been recorded for today.',
                  textAlign: TextAlign.center,
                  style: theme.labelMedium.override(
                    font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500),
                    color: theme.secondaryText,
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: theme.primary.withOpacity(0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14.0,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        formattedDate,
                        style: theme.bodySmall.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w500),
                          color: theme.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28.0),
                FFButtonWidget(
                  onPressed: onGoToDashboard,
                  text: 'Go to dashboard',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 52.0,
                    padding: EdgeInsetsDirectional.zero,
                    iconPadding: EdgeInsetsDirectional.zero,
                    color: theme.primary,
                    hoverColor: Color.lerp(theme.primary, Colors.black, 0.08),
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600),
                      color: Colors.white,
                      fontSize: 16.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0.0,
                    borderSide:
                        const BorderSide(color: Colors.transparent, width: 1.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                InkWell(
                  onTap: onEditDiary,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 16.0, color: theme.primary),
                        const SizedBox(width: 6.0),
                        Text(
                          'Edit today\'s diary',
                          style: theme.bodyMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600),
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
