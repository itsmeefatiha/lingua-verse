import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.sessionStore,
    http.Client? client,
  })
      : _client = client ?? http.Client();

  final String baseUrl;
  final SessionStore sessionStore;
  final http.Client _client;

  Uri _buildUri(String path) {
    return Uri.parse('$baseUrl$path');
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = sessionStore.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  Never _throwApiError(http.Response response) {
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
      throw ApiException(decoded['detail'].toString(), statusCode: response.statusCode);
    }
    throw ApiException(
      'Request failed with status ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _client.get(_buildUri(path), headers: _headers(json: false));
    if (response.statusCode >= 400) {
      _throwApiError(response);
    }
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Invalid JSON object response from $path');
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await _client.get(_buildUri(path), headers: _headers(json: false));
    if (response.statusCode >= 400) {
      _throwApiError(response);
    }
    final decoded = _decodeBody(response);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw ApiException('Invalid JSON list response from $path');
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    if (response.statusCode >= 400) {
      _throwApiError(response);
    }
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Invalid JSON object response from $path');
  }

  Future<List<dynamic>> postList(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    if (response.statusCode >= 400) {
      _throwApiError(response);
    }
    final decoded = _decodeBody(response);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw ApiException('Invalid JSON list response from $path');
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode >= 400) {
      _throwApiError(response);
    }
    final decoded = _decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('Invalid JSON object response from $path');
  }

  Future<List<int>> getBytes(String path) async {
    final response = await _client.get(_buildUri(path), headers: _headers(json: false));
    if (response.statusCode >= 400) {
      _throwApiError(response);
    }
    return response.bodyBytes;
  }
}
