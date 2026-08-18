import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:reg_page/reg_page.dart';

import '../utils/app_urls.dart';

class BaseService {
  final int _apiTimeOut = 25;

  Map<String, String> _setHeaders() {
    Map<String, String> headers = {
      'Accept': '*/*',
      'Content-Type': 'application/json'
    };
    final token = SplashScreen.session.user?.token;
    if (token == null) return headers;
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  @protected
  Future<dynamic> get(
    String api, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    String baseUrl = AppUrls.base,
  }) async {
    Uri? uri;
    headers = _setHeaders();
    try {
      uri = Uri.parse('$baseUrl/$api');
      uri = uri.replace(queryParameters: queryParams);
      requestLog(uri, 'GET');
      var response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: _apiTimeOut));
      responseLog(api, response, 'GET');
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException(
          message: 'No Internet Connection', url: uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
          message: 'Api Not Responded in Time', url: uri.toString());
    }
    // catch (e) {
    //   exceptionLog(e.toString(),name: 'GET on BASE');
    // }
  }

  @protected
  Future<dynamic> post(
    String api,
    payLoadObj, {
    Map<String, String>? header,
    Map<String, dynamic>? queryParams,
    String baseUrl = AppUrls.base,
  }) async {
    Uri uri = Uri.parse('$baseUrl/$api');
    uri = uri.replace(queryParameters: queryParams);
    header = _setHeaders();

    requestLog(uri, 'POST', body: payLoadObj);
    try {
      var response = await http
          .post(
            uri,
            body: json.encode(payLoadObj),
            headers: header,
          )
          .timeout(Duration(seconds: _apiTimeOut));
      responseLog(api, response, "POST");
      return _processResponse(response);
    } on SocketException {
      throw FetchDataException(
          message: 'No Internet Connection', url: uri.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
          message: 'Api Not Responded in Time', url: uri.toString());
    }
    // catch (e) {
    //   exceptionLog(e.toString(), name: 'POST on BASE');
    // }
  }

  dynamic _processResponse(response) async {
    switch (response.statusCode) {
      case 200:
        try {
          if (response.body.toString().isEmpty) return true;
          var responseJson = json.decode(response.body);
          return responseJson;
        } catch (e) {
          return 'success 200';
        }
      case 201:
        try {
          if (response.body.toString().isEmpty) return true;
          var responseJson = json.decode(response.body);
          return responseJson;
        } catch (e) {
          return 'success 201';
        }
      case 400:
        throw BadRequestException(
            message: response.body, url: response.request?.url.toString());
      case 401:
      case 403:
        throw UnAutthorizedException(
            message: response.body, url: response.request?.url.toString());
      case 404:
        throw BadRequestException(
            errorCode: json.decode(response.body),
            message: json.decode(response.body),
            url: response.request?.url.toString());

      case 409:
      case 422:
        throw UnProcessableException(
            message: json.decode(response.body),
            url: response.request?.url.toString());
      case 500:
      default:
        throw FetchDataException(
            message: 'Error Occured with code: ${response.statusCode} ',
            url: response.request!.url.toString());
    }
  }

  @protected
  Future<List<int>> downloadFileWithProgress(
    String url,
    Function(double) onProgress, {
    String baseUrl = AppUrls.base,
    Map<String, String>? headers,
  }) async {
    Uri? uri;
    headers ??= _setHeaders();

    try {
      uri = Uri.parse(url);
      requestLog(uri, 'GET');
      final http.Client client = http.Client();
      final http.Request request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final http.StreamedResponse response =
          await client.send(request).timeout(Duration(seconds: _apiTimeOut));
      debugLog(response.statusCode,
          name: 'GET Response downloadFileWithProgress');
      if (response.statusCode == 200) {
        final int totalBytes = response.contentLength ?? 0;
        int receivedBytes = 0;

        List<int> fileBytes = [];

        final Stream<List<int>> stream = response.stream;

        await for (var chunk in stream) {
          receivedBytes += chunk.length;
          fileBytes.addAll(chunk);
          onProgress(receivedBytes / totalBytes);
        }

        // responseLog(url, response, 'GET');
        return fileBytes;
      } else {
        throw FetchDataException(
            message: 'Failed to download file: ${response.statusCode}',
            url: uri.toString());
      }
    } on SocketException {
      throw FetchDataException(
          message: 'No Internet Connection', url: uri?.toString());
    } on TimeoutException {
      throw ApiNotRespondingException(
          message: 'Api Not Responded in Time', url: uri?.toString());
    }
    // catch (e) {
    //   // debugPrint('Error downloading file: $e');
    //   // throw FetchDataException(message: e.toString(), url: uri?.toString());
    // }
  }
}
