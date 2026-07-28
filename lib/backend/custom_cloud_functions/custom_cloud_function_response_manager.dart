import '/backend/schema/structs/index.dart';

class ScheduledRemindersCloudFunctionCallResponse {
  ScheduledRemindersCloudFunctionCallResponse({
    this.errorCode,
    this.succeeded,
    this.jsonBody,
  });
  String? errorCode;
  bool? succeeded;
  dynamic jsonBody;
}

class UpdateDashboardMetricCloudFunctionCallResponse {
  UpdateDashboardMetricCloudFunctionCallResponse({
    this.errorCode,
    this.succeeded,
    this.jsonBody,
  });
  String? errorCode;
  bool? succeeded;
  dynamic jsonBody;
}
