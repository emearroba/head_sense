import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class WeatherrCall {
  static Future<ApiCallResponse> call({
    String? city = '',
  }) async {
    final ffApiRequestBody = '''
{
  "city": "${escapeStringForJson(city)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'weatherr',
      apiUrl: 'https://wv99km.buildship.run/weather-e2c9039c4d44',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? weathermain(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.weather[:].main''',
      ));
  static double? tempmain(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.main.temp''',
      ));
  static int? pressure(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.main.pressure''',
      ));
  static String? cityWeather(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.name''',
      ));
  static int? humidity(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.main.humidity''',
      ));
  static String? weatherDescription(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.weather[:].description''',
      ));
  static double? windSpeed(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.wind.speed''',
      ));
  static int? tempFeelsLike(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.main.feels_like''',
      ));
  static double? tempMin(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.main.temp_min''',
      ));
  static double? tempMax(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.main.temp_max''',
      ));
  static double? lon(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.coord.lon''',
      ));
  static double? lat(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.data.coord.lat''',
      ));
}

class GeoApifyCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GeoApify',
      apiUrl:
          'https://api.geoapify.com/v1/geocode/reverse/geoApify-281e62c52b12',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
