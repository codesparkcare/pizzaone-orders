import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class ApiResponse {
  final bool success;
  final int statusCode;
  final dynamic data;
  final String message;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message = '',
  });
}

class ApiClient {
  String _baseUrl = ApiConstants.defaultBaseUrl;
  String? _authToken;

  ApiClient({String? initialBaseUrl, String? token}) {
    if (initialBaseUrl != null && initialBaseUrl.isNotEmpty) {
      _baseUrl = sanitizeUrl(initialBaseUrl);
    }
    _authToken = token;
  }

  String get baseUrl => effectiveBaseUrl;
  String? get authToken => _authToken;

  String get effectiveBaseUrl {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin.startsWith('http')) {
          final originHost = Uri.parse(origin).host.toLowerCase();
          final baseHost = Uri.parse(_baseUrl).host.toLowerCase();
          if (originHost.contains('pizzaonerestaurant.com') &&
              baseHost.contains('pizzaonerestaurant.com')) {
            return origin;
          }
        }
      } catch (_) {}
    }
    return _baseUrl;
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = sanitizeUrl(newUrl);
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  static String sanitizeUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    // In web browsers (WebKit/Safari/Chrome), User-Agent is a restricted header name.
    // Setting it causes browsers to fail CORS preflight or throw 'TypeError: Load failed'.
    // We only set it on native platforms.
    if (!kIsWeb) {
      headers['User-Agent'] = 'PizzaOneOrderApp/1.0.0 (Flutter; Mobile)';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$effectiveBaseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      if (kDebugMode) {
        debugPrint('[API GET] $uri');
      }

      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(ApiConstants.connectTimeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API SocketException] $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Unable to connect to server ($effectiveBaseUrl). Check internet connection.',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        statusCode: 408,
        message: 'Connection timed out. Server is not responding.',
      );
    } catch (e) {
      debugPrint('[API Error] $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse> post(String endpoint, {dynamic body}) async {
    try {
      final uri = Uri.parse('$effectiveBaseUrl$endpoint');
      final encodedBody = body != null ? jsonEncode(body) : null;

      if (kDebugMode) {
        debugPrint('[API POST] $uri | Body: $encodedBody');
      }

      final response = await http
          .post(uri, headers: _buildHeaders(), body: encodedBody)
          .timeout(ApiConstants.connectTimeout);

      return _processResponse(response);
    } on SocketException catch (e) {
      debugPrint('[API SocketException] $e');
      return ApiResponse(
        success: false,
        statusCode: 0,
        message: 'Unable to connect to server ($effectiveBaseUrl).',
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        statusCode: 408,
        message: 'Request timed out.',
      );
    } catch (e) {
      debugPrint('[API Error] $e');
      return ApiResponse(
        success: false,
        statusCode: 500,
        message: 'Network error: $e',
      );
    }
  }

  ApiResponse _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      jsonBody = response.body;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    String message = '';
    if (jsonBody is Map && jsonBody.containsKey('message')) {
      message = jsonBody['message'].toString();
    } else if (!isSuccess) {
      message = 'HTTP Error ${response.statusCode}';
    }

    return ApiResponse(
      success: isSuccess,
      statusCode: response.statusCode,
      data: jsonBody,
      message: message,
    );
  }
}
