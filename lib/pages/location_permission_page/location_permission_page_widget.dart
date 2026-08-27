import '/auth/firebase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'location_permission_page_model.dart';
export 'location_permission_page_model.dart';

// Shown once, right after onboarding_goals, so the user's location is on
// file for weather-linked diary entries and doesn't need to be re-fetched
// (and re-prompted for) on every visit to the Weather page.
class LocationPermissionPageWidget extends StatefulWidget {
  const LocationPermissionPageWidget({super.key});

  static String routeName = 'locationPermissionPage';
  static String routePath = '/locationPermissionPage';

  @override
  State<LocationPermissionPageWidget> createState() =>
      _LocationPermissionPageWidgetState();
}

class _LocationPermissionPageWidgetState
    extends State<LocationPermissionPageWidget> {
  late LocationPermissionPageModel _model;
  bool _saving = false;
  String? _error;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LocationPermissionPageModel());

    _model.cityTextController ??= TextEditingController();
    _model.cityFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _continueToDiary() {
    if (!mounted) return;
    context.goNamed(DailyDiaryPageWidget.routeName);
  }

  Future<void> _saveLocation() async {
    final city = _model.cityTextController.text.trim();
    if (city.isEmpty || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final response = await WeatherrCall.call(city: city);
    if (!mounted) return;

    if (!(response.succeeded)) {
      setState(() {
        _saving = false;
        _error = "Couldn't find that city. Check the spelling and try again.";
      });
      return;
    }

    final resolvedCity = WeatherrCall.cityWeather(response.jsonBody) ?? city;
    final lat = WeatherrCall.lat(response.jsonBody);
    final lon = WeatherrCall.lon(response.jsonBody);

    if (currentUserReference != null) {
      await currentUserReference!.update({
        'locationLabel': resolvedCity,
        if (lat != null && lon != null) 'userTimezone': LatLng(lat, lon),
      });
    }

    _continueToDiary();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'Location',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 60.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "What's your location? We'll use it to attach local "
                      'weather to your diary entries. You can change this '
                      'anytime in Settings.',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                  TextFormField(
                    controller: _model.cityTextController,
                    focusNode: _model.cityFocusNode,
                    autofocus: false,
                    obscureText: false,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'e.g. "London"',
                      filled: true,
                      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).alternate,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          letterSpacing: 0.0,
                        ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).error,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: FFButtonWidget(
                      onPressed: _saving ? () {} : _saveLocation,
                      text: _saving ? 'Saving...' : 'Save Location',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: _continueToDiary,
                      text: 'Later',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding:
                            EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: Color(0x2D668480),
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w600,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
