import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/intensity_card_widget.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'dashboard_widget.dart' show DashboardWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashboardModel extends FlutterFlowModel<DashboardWidget> {
  ///  Local state fields for this page.

  String selectedMetricKey = 'headache_intensity';

  String selectedPeriod = 'last30';

  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for IntensityCard.
  late IntensityCardModel intensityCardModel1;
  // Model for IntensityCard.
  late IntensityCardModel intensityCardModel2;
  // Model for IntensityCard.
  late IntensityCardModel intensityCardModel3;

  @override
  void initState(BuildContext context) {
    intensityCardModel1 = createModel(context, () => IntensityCardModel());
    intensityCardModel2 = createModel(context, () => IntensityCardModel());
    intensityCardModel3 = createModel(context, () => IntensityCardModel());
  }

  @override
  void dispose() {
    intensityCardModel1.dispose();
    intensityCardModel2.dispose();
    intensityCardModel3.dispose();
  }
}
