import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_models.dart';

class AdminApiService {
  static const String _baseUrl = 'https://api.horsetempo.app/api';
  static const String _tokenKey = 'admin_auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio;
  String? _token;

  AdminApiService() : _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    // Configure to accept Let's Encrypt certificates (Dio 5.x API)
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only accept certificates for our API domain
        return host == 'api.horsetempo.app';
      };
      return client;
    };

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

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

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['accessToken'] ?? data['token'];
        if (token != null) {
          await _saveToken(token);
        }
        return {
          'success': true,
          'user': AdminUser.fromJson(data['user']),
          'token': token,
        };
      }
      return {
        'success': false,
        'error': 'Réponse inattendue du serveur',
      };
    } on DioException catch (e) {
      print('Login DioException: $e');
      final error = _handleDioError(e);
      return {
        'success': false,
        'error': error.toString().replaceFirst('Exception: ', ''),
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'error': 'Une erreur inattendue s\'est produite',
      };
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    }
    await _clearToken();
  }

  Future<AdminUser?> getCurrentAdmin() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return AdminUser.fromJson(response.data);
      }
    } catch (e) {
      print('Get current admin error: $e');
    }
    return null;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Délai d\'attente dépassé. Veuillez réessayer.');
      case DioExceptionType.connectionError:
        return Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Erreur serveur';
        if (statusCode == 401) {
          return Exception('Session expirée. Veuillez vous reconnecter.');
        } else if (statusCode == 403) {
          return Exception('Accès refusé. Permissions insuffisantes.');
        } else if (statusCode == 404) {
          return Exception('Ressource non trouvée.');
        } else if (statusCode == 422) {
          return Exception('Données invalides: $message');
        } else if (statusCode! >= 500) {
          return Exception('Erreur serveur. Veuillez réessayer plus tard.');
        }
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Requête annulée.');
      default:
        return Exception('Une erreur inattendue s\'est produite.');
    }
  }
}

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService();
});
