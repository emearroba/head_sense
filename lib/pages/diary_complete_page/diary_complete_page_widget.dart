import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'diary_complete_page_model.dart';
export 'diary_complete_page_model.dart';

class DiaryCompletePageWidget extends StatefulWidget {
  const DiaryCompletePageWidget({super.key});

  static String routeName = 'diaryCompletePage';
  static String routePath = '/diaryCompletePage';

  @override
  State<DiaryCompletePageWidget> createState() =>
      _DiaryCompletePageWidgetState();
}

class _DiaryCompletePageWidgetState extends State<DiaryCompletePageWidget> {
  late DiaryCompletePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DiaryCompletePageModel());

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
              context.goNamed(DashboardWidget.routeName);
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
