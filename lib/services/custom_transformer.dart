import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final log = Logger('Transformer');

class CustomTransformer extends BackgroundTransformer {
  @override
  Future<String> transformRequest(RequestOptions options) async {
    if (options.data == null) return "";
    return json.encode(options.data);
  }

  @override
  Future transformResponse(
      // ignore: avoid_renaming_method_parameters
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
          log.severe('JSON解析错误: $e');
        }
        return responseBody;
      }
    }
    return responseBody;
  }
}
