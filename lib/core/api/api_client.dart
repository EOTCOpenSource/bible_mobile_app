import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://eotcbiblebe.onrender.com/api/v1';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isAccountLocked => statusCode == 423 || statusCode == 429;

  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient();

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token: token),
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token: token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token: token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers(token: token),
    );
    return _parse(res);
  }

  Map<String, dynamic> _parse(http.Response res) {
    late Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final message = body['message'] as String? ??
        body['error'] as String? ??
        'Something went wrong';

    throw ApiException(message, statusCode: res.statusCode);
  }
}
