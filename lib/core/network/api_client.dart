import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required AppConfig config, http.Client? httpClient})
      : _config = config,
        _httpClient = httpClient ?? http.Client();

  final AppConfig _config;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    bool requiresUser = false,
  }) async {
    final response = await _httpClient.get(
      _buildUri(path, queryParameters),
      headers: _headers(requiresUser: requiresUser),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresUser = false,
  }) async {
    final response = await _httpClient.post(
      _buildUri(path),
      headers: _headers(requiresUser: requiresUser),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool requiresUser = false,
  }) async {
    final response = await _httpClient.delete(
      _buildUri(path),
      headers: _headers(requiresUser: requiresUser),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool requiresUser = false,
  }) async {
    final response = await _httpClient.patch(
      _buildUri(path),
      headers: _headers(requiresUser: requiresUser),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(response);
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final trimmedBase = _config.apiBaseUrl.endsWith('/')
        ? _config.apiBaseUrl.substring(0, _config.apiBaseUrl.length - 1)
        : _config.apiBaseUrl;
    final normalizedBase = trimmedBase.endsWith('/api/v1')
        ? trimmedBase
        : '$trimmedBase/api/v1';
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$normalizedBase/$normalizedPath');
    return queryParameters == null ? uri : uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({required bool requiresUser}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (requiresUser || _config.userIdentifier.isNotEmpty)
        'X-User-Identifier': _config.userIdentifier,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      message: body['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
      statusCode: response.statusCode,
      errorCode: body['error_code'] as String?,
    );
  }
}
