import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'authentication_model.dart';
export 'authentication_model.dart';

class AuthenticationWidget extends StatefulWidget {
  const AuthenticationWidget({super.key});

  static String routeName = 'Authentication';
  static String routePath = '/authentication';

  @override
  State<AuthenticationWidget> createState() => _AuthenticationWidgetState();
}

class _AuthenticationWidgetState extends State<AuthenticationWidget>
    with TickerProviderStateMixin {
  late AuthenticationModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AuthenticationModel());

    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 1,
    )..addListener(() => safeSetState(() {}));

    _model.emailAddressCreateTextController ??= TextEditingController();
    _model.emailAddressCreateFocusNode ??= FocusNode();

    _model.passwordCreateTextController ??= TextEditingController();
    _model.passwordCreateFocusNode ??= FocusNode();

    _model.emailAddressTextController ??= TextEditingController();
    _model.emailAddressFocusNode ??= FocusNode();

    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: Offset(0.0, 24.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'columnOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
      'columnOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 300.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final emailController = TextEditingController(
      text: _model.emailAddressTextController?.text ?? '',
    );
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.secondaryBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Text(
            'Reset password',
            style: theme.titleSmall.override(
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          content: TextField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: TextStyle(color: theme.primaryText),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: theme.secondaryText),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.alternate),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.primary),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: theme.secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await authManager.resetPassword(
                  email: emailController.text,
                  context: context,
                );
              },
              child: Text(
                'Send reset link',
                style: TextStyle(color: theme.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- Shared field styling so Login and Create Account stay visually identical ----

  Widget _fieldLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 6.0),
      child: Text(
        text,
        style: FlutterFlowTheme.of(context).labelMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
              color: FlutterFlowTheme.of(context).secondaryText,
              fontSize: 13.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _passwordLabelRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Password',
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 13.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                ),
          ),
          InkWell(
            onTap: () async => _showForgotPasswordDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Forgot password?',
                style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: FlutterFlowTheme.of(context).primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {Widget? suffixIcon}) {
    final theme = FlutterFlowTheme.of(context);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
          borderRadius: BorderRadius.circular(12.0),
        );
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      enabledBorder: border(theme.alternate, 1.0),
      focusedBorder: border(theme.primary, 1.5),
      errorBorder: border(theme.error, 1.0),
      focusedErrorBorder: border(theme.error, 1.5),
      filled: true,
      fillColor: theme.primaryBackground,
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 48.0, minHeight: 44.0),
    );
  }

  TextStyle _fieldTextStyle(BuildContext context) {
    return FlutterFlowTheme.of(context).bodyLarge.override(
          font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
          color: FlutterFlowTheme.of(context).primaryText,
          fontSize: 16.0,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w500,
        );
  }

  Widget _passwordVisibilityToggle(
      BuildContext context, bool visible, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      focusNode: FocusNode(skipTraversal: true),
      constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
      tooltip: visible ? 'Hide password' : 'Show password',
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: FlutterFlowTheme.of(context).secondaryText,
        size: 22.0,
      ),
    );
  }

  FFButtonOptions _primaryButtonOptions(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FFButtonOptions(
      width: double.infinity,
      height: 52.0,
      padding: EdgeInsetsDirectional.zero,
      iconPadding: EdgeInsetsDirectional.zero,
      color: theme.primary,
      hoverColor: Color.lerp(theme.primary, Colors.black, 0.08),
      textStyle: theme.titleSmall.override(
        font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        color: Colors.white,
        fontSize: 16.0,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0.0,
      borderSide: const BorderSide(color: Colors.transparent, width: 1.0),
      borderRadius: BorderRadius.circular(12.0),
    );
  }

  Widget _logo(BuildContext context) {
    return const custom_widgets.OrbitLogo(
      width: 180.0,
      height: 180.0,
    );
  }

  Widget _footerLink(BuildContext context, String lead, String action, int targetIndex) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
      child: Align(
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lead,
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            InkWell(
              onTap: () => _model.tabBarController?.animateTo(targetIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  action,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        color: FlutterFlowTheme.of(context).primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _logo(context),
                          const SizedBox(height: 16.0),
                          Text(
                            'Somatica',
                            textAlign: TextAlign.center,
                            style: theme.headlineMedium.override(
                              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                              color: Colors.white,
                              fontSize: 32.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Listen to your body',
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium.override(
                              font: GoogleFonts.plusJakartaSans(),
                              color: theme.secondaryText,
                              letterSpacing: 0.0,
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: theme.alternate, width: 1.0),
                            ),
                            child: IndexedStack(
                              index: _model.tabBarCurrentIndex,
                              children: [
                                _buildCreateAccountPane(context),
                                _buildLoginPane(context),
                              ],
                            ),
                          ).animateOnPageLoad(
                              animationsMap['containerOnPageLoadAnimation']!),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountPane(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create account',
          textAlign: TextAlign.start,
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
            color: theme.primaryText,
            fontSize: 24.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 24.0),
          child: Text(
            'Let\'s get started by filling out the form below.',
            textAlign: TextAlign.start,
            style: theme.labelMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
              color: theme.secondaryText,
              fontSize: 14.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _fieldLabel(context, 'Email'),
        TextFormField(
          controller: _model.emailAddressCreateTextController,
          focusNode: _model.emailAddressCreateFocusNode,
          autofocus: false,
          autofillHints: const [AutofillHints.email],
          obscureText: false,
          decoration: _fieldDecoration(context),
          style: _fieldTextStyle(context),
          keyboardType: TextInputType.emailAddress,
          validator: _model.emailAddressCreateTextControllerValidator
              ?.asValidator(context),
        ),
        const SizedBox(height: 16.0),
        _fieldLabel(context, 'Password'),
        TextFormField(
          controller: _model.passwordCreateTextController,
          focusNode: _model.passwordCreateFocusNode,
          autofocus: false,
          autofillHints: const [AutofillHints.newPassword],
          obscureText: !_model.passwordCreateVisibility,
          decoration: _fieldDecoration(
            context,
            suffixIcon: _passwordVisibilityToggle(
              context,
              _model.passwordCreateVisibility,
              () => safeSetState(() => _model.passwordCreateVisibility =
                  !_model.passwordCreateVisibility),
            ),
          ),
          style: _fieldTextStyle(context),
          validator: _model.passwordCreateTextControllerValidator
              ?.asValidator(context),
        ),
        const SizedBox(height: 24.0),
        FFButtonWidget(
          onPressed: () async {
            GoRouter.of(context).prepareAuthEvent();

            final user = await authManager.createAccountWithEmail(
              context,
              _model.emailAddressCreateTextController.text,
              _model.passwordCreateTextController.text,
            );
            if (user == null) {
              return;
            }

            await RemindersRecord.createDoc(
              currentUserReference!,
              id: 'diary',
            ).set({
              ...createRemindersRecordData(
                title: 'Diary',
                message: 'How are you feeling today?',
                isActive: true,
                frequencyType: 'daily',
                hourOfDay: 21,
                minuteOfHour: 00,
                userRef: currentUserReference,
                type: 'diary',
              ),
              ...mapToFirestore(
                {
                  'scheduled_time': FieldValue.serverTimestamp(),
                  'created_time': FieldValue.serverTimestamp(),
                },
              ),
            });

            context.goNamedAuth(
                OnboardingGoalsWidget.routeName, context.mounted);
          },
          text: 'Get Started',
          options: _primaryButtonOptions(context),
        ),
        _footerLink(context, 'Already have an account? ', 'Log in', 1),
      ],
    ).animateOnPageLoad(animationsMap['columnOnPageLoadAnimation1']!);
  }

  Widget _buildLoginPane(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          textAlign: TextAlign.start,
          style: theme.headlineMedium.override(
            font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
            color: theme.primaryText,
            fontSize: 24.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 24.0),
          child: Text(
            'Sign in to continue logging your symptoms',
            textAlign: TextAlign.start,
            style: theme.labelMedium.override(
              font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
              color: theme.secondaryText,
              fontSize: 14.0,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _fieldLabel(context, 'Email'),
        TextFormField(
          controller: _model.emailAddressTextController,
          focusNode: _model.emailAddressFocusNode,
          autofocus: false,
          autofillHints: const [AutofillHints.email],
          obscureText: false,
          decoration: _fieldDecoration(context),
          style: _fieldTextStyle(context),
          keyboardType: TextInputType.emailAddress,
          validator:
              _model.emailAddressTextControllerValidator?.asValidator(context),
        ),
        const SizedBox(height: 16.0),
        _passwordLabelRow(context),
        TextFormField(
          controller: _model.passwordTextController,
          focusNode: _model.passwordFocusNode,
          autofocus: false,
          autofillHints: const [AutofillHints.password],
          obscureText: !_model.passwordVisibility,
          decoration: _fieldDecoration(
            context,
            suffixIcon: _passwordVisibilityToggle(
              context,
              _model.passwordVisibility,
              () => safeSetState(
                  () => _model.passwordVisibility = !_model.passwordVisibility),
            ),
          ),
          style: _fieldTextStyle(context),
          validator:
              _model.passwordTextControllerValidator?.asValidator(context),
        ),
        const SizedBox(height: 24.0),
        FFButtonWidget(
          onPressed: () async {
            GoRouter.of(context).prepareAuthEvent();

            final user = await authManager.signInWithEmail(
              context,
              _model.emailAddressTextController.text,
              _model.passwordTextController.text,
            );
            if (user == null) {
              return;
            }

            context.goNamedAuth(
                DailyDiaryPageWidget.routeName, context.mounted);
          },
          text: 'Sign in',
          options: _primaryButtonOptions(context),
        ),
        _footerLink(context, 'Don\'t have an account? ', 'Create account', 0),
      ],
    ).animateOnPageLoad(animationsMap['columnOnPageLoadAnimation2']!);
  }
}
