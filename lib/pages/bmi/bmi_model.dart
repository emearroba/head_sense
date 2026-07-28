import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'bmi_widget.dart' show BmiWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BmiModel extends FlutterFlowModel<BmiWidget> {
  ///  Local state fields for this page.

  double? bmi;

  ///  State fields for stateful widgets in this page.

  // State field(s) for WeightWidget widget.
  FocusNode? weightWidgetFocusNode;
  TextEditingController? weightWidgetTextController;
  String? Function(BuildContext, String?)? weightWidgetTextControllerValidator;
  // State field(s) for HeightWidget widget.
  FocusNode? heightWidgetFocusNode;
  TextEditingController? heightWidgetTextController;
  String? Function(BuildContext, String?)? heightWidgetTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    weightWidgetFocusNode?.dispose();
    weightWidgetTextController?.dispose();

    heightWidgetFocusNode?.dispose();
    heightWidgetTextController?.dispose();
  }
}
