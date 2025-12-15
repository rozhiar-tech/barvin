import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._internal({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  static final ApiClient instance = ApiClient._internal();

  final http.Client _http;

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) {
    return _send(
      () async {
        final uri = apiUrl(path, queryParameters);
        final resolvedHeaders = await _buildHeaders(headers, requiresAuth);
        return _http.get(uri, headers: resolvedHeaders);
      },
    );
  }

  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) {
    return _send(
      () async {
        final uri = apiUrl(path);
        final resolvedHeaders = await _buildHeaders(headers, requiresAuth);
        print('🌐 [API POST] URL: $uri');
        print('🌐 [API POST] Headers: $resolvedHeaders');
        print('🌐 [API POST] Body: $body');
        print('🌐 [API POST] RequiresAuth: $requiresAuth');
        return _http.post(uri, headers: resolvedHeaders, body: body);
      },
    );
  }

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) {
    return _send(
      () async {
        final uri = apiUrl(path);
        final resolvedHeaders = await _buildHeaders(headers, requiresAuth);
        return _http.put(uri, headers: resolvedHeaders, body: body);
      },
    );
  }

  Future<ApiResponse> delete(
    String path, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) {
    return _send(
      () async {
        final uri = apiUrl(path);
        final resolvedHeaders = await _buildHeaders(headers, requiresAuth);
        return _http.delete(uri, headers: resolvedHeaders);
      },
    );
  }

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) {
    return _send(
      () async {
        final uri = apiUrl(path);
        final resolvedHeaders = await _buildHeaders(headers, requiresAuth);
        return _http.patch(uri, headers: resolvedHeaders, body: body);
      },
    );
  }

  Future<ApiResponse> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      print('🌐 [API] Sending request...');
      final response = await request().timeout(const Duration(seconds: 30));
      print('🌐 [API] Response received:');
      print('🌐 [API]   Status: ${response.statusCode}');
      print('🌐 [API]   Body length: ${response.body.length} chars');
      print('🌐 [API]   Body: ${response.body}');
      print('🌐 [API]   Headers: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ [API] Success response (${response.statusCode})');
        return ApiResponse(
          statusCode: response.statusCode,
          body: response.body,
          headers: response.headers,
        );
      }
      print('❌ [API] Error response (${response.statusCode})');
      throw ApiException.fromResponse(response);
    } on SocketException catch (e) {
      print('💥 [API] Socket exception: $e');
      throw ApiException.network(e);
    } on TimeoutException {
      print('⏱️ [API] Request timeout');
      throw ApiException(
        statusCode: -1,
        message: 'Request timed out. Please try again.',
      );
    }
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? headers,
    bool requiresAuth,
  ) async {
    final resolved = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (requiresAuth) {
      final token = await TokenStorage.read();
      if (token != null && token.isNotEmpty) {
        resolved['Authorization'] = 'Bearer $token';
      }
    }
    return resolved;
  }
}

class ApiResponse {
  ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;

  dynamic json() => body.isEmpty ? null : jsonDecode(body);
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    this.message,
    this.body,
  });

  final int statusCode;
  final String? message;
  final String? body;

  static ApiException fromResponse(http.Response response) {
    String? extractedMessage;
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] is String) {
        extractedMessage = data['message'] as String;
      } else if (data is Map && data['error'] is String) {
        extractedMessage = data['error'] as String;
      }
    } catch (_) {
      extractedMessage = null;
    }
    return ApiException(
      statusCode: response.statusCode,
      message: extractedMessage ?? 'Server error (${response.statusCode})',
      body: response.body,
    );
  }

  factory ApiException.network(SocketException exception) => ApiException(
        statusCode: -1,
        message: 'Network error. Check your connection and try again.',
        body: exception.message,
      );

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
