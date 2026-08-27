import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'diary_complete_page_retry_model.dart';
export 'diary_complete_page_retry_model.dart';

class DiaryCompletePageRetryWidget extends StatefulWidget {
  const DiaryCompletePageRetryWidget({super.key});

  static String routeName = 'diaryCompletePageRetry';
  static String routePath = '/diaryCompletePageRetry';

  @override
  State<DiaryCompletePageRetryWidget> createState() =>
      _DiaryCompletePageRetryWidgetState();
}

class _DiaryCompletePageRetryWidgetState
    extends State<DiaryCompletePageRetryWidget> {
  late DiaryCompletePageRetryModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DiaryCompletePageRetryModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
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
        body: SafeArea(
          top: true,
          child: custom_widgets.DiaryCompletedCard(
            onGoToDashboard: () {
              context.pushNamed(DashboardWidget.routeName);
            },
            onEditDiary: () {
              context.pushNamed(
                DailyDiaryPageWidget.routeName,
                queryParameters: {
                  'editMode': serializeParam(
                    true,
                    ParamType.bool,
                  ),
                }.withoutNulls,
              );
            },
          ),
        ),
      ),
    );
  }
}
