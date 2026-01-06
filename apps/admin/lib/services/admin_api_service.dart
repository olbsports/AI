import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_models.dart';

class AdminApiService {
  static const String _baseUrl = 'https://api.horsevision.ai/admin';
  static const String _tokenKey = 'admin_auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _token;

  Future<String?> getStoredToken() async {
    _token = await _storage.read(key: _tokenKey);
    return _token;
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> _clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      return {
        'user': AdminUser.fromJson(data['user']),
        'token': data['token'],
      };
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _headers,
      );
    } catch (e) {
      // Ignore logout errors
    }
    await _clearToken();
  }

  Future<AdminUser?> getCurrentAdmin() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return AdminUser.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed: ${response.statusCode}');
  }

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed: ${response.statusCode}');
  }

  Future<dynamic> put(String path, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Request failed: ${response.statusCode}');
  }

  Future<void> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }
}

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService();
});
