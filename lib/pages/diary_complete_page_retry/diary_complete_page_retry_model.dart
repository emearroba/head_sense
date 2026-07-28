import '/components/somatika_button_blue_widget.dart';
import '/components/somatika_button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'diary_complete_page_retry_widget.dart'
    show DiaryCompletePageRetryWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DiaryCompletePageRetryModel
    extends FlutterFlowModel<DiaryCompletePageRetryWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for somatikaButton component.
  late SomatikaButtonModel somatikaButtonModel;
  // Model for somatikaButtonBlue component.
  late SomatikaButtonBlueModel somatikaButtonBlueModel;

  @override
  void initState(BuildContext context) {
    somatikaButtonModel = createModel(context, () => SomatikaButtonModel());
    somatikaButtonBlueModel =
        createModel(context, () => SomatikaButtonBlueModel());
  }

  @override
  void dispose() {
    somatikaButtonModel.dispose();
    somatikaButtonBlueModel.dispose();
  }
}
