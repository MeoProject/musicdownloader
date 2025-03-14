import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final log = Logger();

class CustomTransformer extends BackgroundTransformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    if (options.data == null) return "";
    return json.encode(options.data);
  }

  @override
  Future transformResponse(
      RequestOptions options, ResponseBody response) async {
    final responseBody = await super.transformResponse(options, response);
    if (responseBody is String) {
      if (responseBody.trim().startsWith('http')) {
        return responseBody;
      }

      try {
        return json.decode(responseBody);
      } catch (e) {
        if (kDebugMode) {
          log.e('JSON解析错误', error: e);
        }
        return responseBody;
      }
    }
    return responseBody;
  }
}
