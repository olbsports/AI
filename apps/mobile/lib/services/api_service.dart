import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../models/models.dart';

// API Base URL - Change this to your backend URL
const String apiBaseUrl = 'https://api.horsetempo.app/api';

// Shared secure storage instance for token access
const _secureStorage = FlutterSecureStorage();

// Token refresh state management
class _TokenRefreshManager {
  bool _isRefreshing = false;
  final List<Completer<String>> _refreshCompleters = [];

  Future<void> handleRefresh(
    Dio dio,
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isRefreshing) {
      return _waitForRefresh(dio, error, handler);
    }

    _isRefreshing = true;
    final refreshToken = await _secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      try {
        debugPrint('AUTH: Attempting token refresh');
        // Create a new Dio instance to avoid interceptor loop
        final refreshDio = Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

        final response = await refreshDio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
        });

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String?;

        // Save new tokens
        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
        }

        debugPrint('AUTH: Token refresh successful');

        // Notify all waiting requests
        for (final completer in _refreshCompleters) {
          if (!completer.isCompleted) {
            completer.complete(newAccessToken);
          }
        }
        _refreshCompleters.clear();

        // Retry the failed request with new token
        error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await dio.fetch(error.requestOptions);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (e) {
        debugPrint('AUTH: Token refresh failed - clearing tokens');
        _isRefreshing = false;
        for (final completer in _refreshCompleters) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
        _refreshCompleters.clear();
        // SECURITY: Clear only auth tokens on refresh failure, not all secure storage
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'refresh_token');
      }
    } else {
      debugPrint('AUTH: No refresh token available');
      _isRefreshing = false;
    }
    return handler.next(error);
  }

  Future<void> _waitForRefresh(
    Dio dio,
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final completer = Completer<String>();
    _refreshCompleters.add(completer);

    try {
      final newToken = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Token refresh timeout'),
      );

      // Retry request with new token
      error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final retryResponse = await dio.fetch(error.requestOptions);
      return handler.resolve(retryResponse);
    } catch (e) {
      return handler.next(error);
    }
  }
}

final _tokenRefreshManager = _TokenRefreshManager();

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 5),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // SECURITY: Certificate validation is handled by the system.
  // Do NOT bypass certificate validation as it makes the app vulnerable to MITM attacks.
  // If you have issues with Let's Encrypt certificates, ensure your device's root certificates are up to date.

  // Add logging interceptor (only in debug mode and without sensitive data)
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: false, // Don't log headers (contains auth tokens)
      requestBody: false, // Don't log body (may contain passwords)
      responseHeader: false,
      responseBody: false, // Don't log response body (may contain sensitive data)
      error: true,
      logPrint: (obj) {
        // Use debugPrint which is safe and can be disabled in release mode
        debugPrint('API: $obj');
      },
    ));
  }

  // Add interceptor for auth token
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        return _tokenRefreshManager.handleRefresh(dio, error, handler);
      }
      return handler.next(error);
    },
  ));

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // Validation des fichiers avant upload
  void _validateImageFile(File file) {
    // Vérifier la taille (max 5MB)
    final fileSize = file.lengthSync();
    const maxSize = 5 * 1024 * 1024; // 5MB en bytes
    if (fileSize > maxSize) {
      throw Exception('La taille du fichier ne doit pas dépasser 5MB (taille actuelle: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB)');
    }

    // Vérifier le type MIME
    final mimeType = lookupMimeType(file.path);
    const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

    if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
      throw Exception('Format de fichier non supporté. Formats acceptés: JPEG, PNG, WebP');
    }
  }

  // ==================== AUTH ====================

  Future<AuthResponse> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// Login with device tracking and optional remember device
  Future<AuthResponse> loginWithDevice(
    String email,
    String password, {
    bool rememberDevice = false,
    String? deviceFingerprint,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'rememberDevice': rememberDevice,
      if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// Verify 2FA code during login
  Future<AuthResponse> verify2FALogin(
    String tempToken,
    String code, {
    bool trustDevice = false,
  }) async {
    final response = await _dio.post('/auth/2fa/verify', data: {
      'tempToken': tempToken,
      'code': code,
      'trustDevice': trustDevice,
    });
    return AuthResponse.fromJson(response.data);
  }

  /// Enable 2FA for the current user
  Future<TwoFactorSetupResponse> enable2FA() async {
    final response = await _dio.post('/auth/2fa/enable');
    return TwoFactorSetupResponse.fromJson(response.data);
  }

  /// Confirm 2FA setup with verification code
  Future<void> confirm2FASetup(String code) async {
    await _dio.post('/auth/2fa/confirm', data: {'code': code});
  }

  /// Disable 2FA for the current user
  Future<void> disable2FA(String code) async {
    await _dio.post('/auth/2fa/disable', data: {'code': code});
  }

  /// Get backup codes for 2FA
  Future<List<Map<String, dynamic>>> getBackupCodes() async {
    final response = await _dio.get('/auth/2fa/backup-codes');
    final data = response.data;
    if (data is List) {
      return data.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
    }
    if (data is Map<String, dynamic> && data['codes'] != null) {
      final codes = data['codes'] as List;
      return codes.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
    }
    return [];
  }

  /// Regenerate backup codes for 2FA
  Future<List<String>> regenerateBackupCodes() async {
    final response = await _dio.post('/auth/2fa/backup-codes/regenerate');
    final data = response.data;
    if (data is Map<String, dynamic> && data['codes'] != null) {
      final codes = data['codes'] as List;
      return codes.map((e) => e.toString()).toList();
    }
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Get active sessions for the current user
  Future<List<UserSession>> getActiveSessions() async {
    final response = await _dio.get('/auth/sessions');
    final data = response.data;
    if (data is List) {
      return data.map((json) => UserSession.fromJson(json as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic> && data['sessions'] != null) {
      final sessions = data['sessions'] as List;
      return sessions.map((json) => UserSession.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Revoke a specific session
  Future<void> revokeSession(String sessionId) async {
    await _dio.delete('/auth/sessions/$sessionId');
  }

  /// Revoke all sessions except current
  Future<void> revokeAllSessions() async {
    await _dio.post('/auth/sessions/revoke-all');
  }

  /// Get trusted devices for the current user
  Future<List<TrustedDevice>> getTrustedDevices() async {
    final response = await _dio.get('/auth/devices');
    final data = response.data;
    if (data is List) {
      return data.map((json) => TrustedDevice.fromJson(json as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic> && data['devices'] != null) {
      final devices = data['devices'] as List;
      return devices.map((json) => TrustedDevice.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Remove a trusted device
  Future<void> removeTrustedDevice(String deviceId) async {
    await _dio.delete('/auth/devices/$deviceId');
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String organizationName,
    required bool acceptTerms,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'organizationName': organizationName,
      'acceptTerms': acceptTerms,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<User> getProfile() async {
    final response = await _dio.get('/auth/me');
    return User.fromJson(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.patch('/auth/profile', data: data);
    return User.fromJson(response.data);
  }

  Future<String> uploadProfilePhoto(File file) async {
    try {
      // Valider le fichier avant upload
      _validateImageFile(file);

      final mimeType = lookupMimeType(file.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      // Use longer timeout for photo uploads
      final options = Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      );

      final response = await _dio.post(
        '/auth/profile/photo',
        data: formData,
        options: options,
      );

      // Safe response handling
      final data = response.data;
      if (data is Map<String, dynamic> && data['url'] != null) {
        return data['url'] as String;
      }
      throw Exception('Réponse invalide du serveur');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Fonctionnalité d\'upload non disponible sur ce serveur.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      }
      throw Exception('Erreur lors de l\'upload de la photo: ${e.message ?? e.response?.statusMessage ?? "Erreur inconnue"}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ==================== RIDERS ====================

  Future<List<Rider>> getRiders({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final response = await _dio.get('/riders', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (search != null) 'search': search,
    });
    final items = response.data['items'] as List? ?? [];
    return items.map((json) => Rider.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Rider> getRider(String id) async {
    final response = await _dio.get('/riders/$id');
    return Rider.fromJson(response.data);
  }

  Future<Rider> createRider(Map<String, dynamic> data) async {
    final response = await _dio.post('/riders', data: data);
    return Rider.fromJson(response.data);
  }

  Future<Rider> updateRider(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/riders/$id', data: data);
    return Rider.fromJson(response.data);
  }

  Future<void> deleteRider(String id) async {
    await _dio.delete('/riders/$id');
  }

  Future<String> uploadRiderPhoto(String riderId, File file) async {
    try {
      // Valider le fichier avant upload
      _validateImageFile(file);

      final mimeType = lookupMimeType(file.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      // Use longer timeout for photo uploads
      final options = Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      );

      final response = await _dio.post(
        '/riders/$riderId/photo',
        data: formData,
        options: options,
      );

      // Safe response handling
      final data = response.data;
      if (data is Map<String, dynamic> && data['url'] != null) {
        return data['url'] as String;
      }
      throw Exception('Réponse invalide du serveur');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Fonctionnalité d\'upload non disponible sur ce serveur.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      }
      throw Exception('Erreur lors de l\'upload de la photo: ${e.message ?? e.response?.statusMessage ?? "Erreur inconnue"}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  // ==================== HORSES ====================

  Future<List<Horse>> getHorses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    final response = await _dio.get('/horses', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
    });
    final items = response.data['items'] as List? ?? [];
    return items.map((json) => Horse.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Horse> getHorse(String id) async {
    final response = await _dio.get('/horses/$id');
    return Horse.fromJson(response.data);
  }

  Future<Horse> createHorse(Map<String, dynamic> data) async {
    final response = await _dio.post('/horses', data: data);
    return Horse.fromJson(response.data);
  }

  Future<Horse> updateHorse(String id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/horses/$id', data: data);
    return Horse.fromJson(response.data);
  }

  Future<void> deleteHorse(String id) async {
    await _dio.delete('/horses/$id');
  }

  Future<String> uploadHorsePhoto(String horseId, File file) async {
    try {
      // Valider le fichier avant upload
      _validateImageFile(file);

      final mimeType = lookupMimeType(file.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      // Use longer timeout for photo uploads
      final options = Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      );

      final response = await _dio.post(
        '/horses/$horseId/photo',
        data: formData,
        options: options,
      );

      // Safe response handling
      final data = response.data;
      if (data is Map<String, dynamic> && data['url'] != null) {
        return data['url'] as String;
      }
      throw Exception('Réponse invalide du serveur');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Fonctionnalité d\'upload non disponible sur ce serveur.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      }
      throw Exception('Erreur lors de l\'upload de la photo: ${e.message ?? e.response?.statusMessage ?? "Erreur inconnue"}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de l\'upload de la photo: $e');
    }
  }

  // ==================== ANALYSES ====================

  Future<List<Analysis>> getAnalyses({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
    String? horseId,
  }) async {
    final response = await _dio.get('/analyses', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (horseId != null) 'horseId': horseId,
    });
    final items = response.data['items'] as List? ?? [];
    return items.map((json) => Analysis.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Analysis> getAnalysis(String id) async {
    final response = await _dio.get('/analyses/$id');
    return Analysis.fromJson(response.data);
  }

  Future<Analysis> createAnalysis({
    required String horseId,
    required String type,
    required File videoFile,
    String? title,
    String? riderId,
    String? notes,
  }) async {
    final formData = FormData.fromMap({
      'horseId': horseId,
      'type': type,
      'video': await MultipartFile.fromFile(videoFile.path),
      if (title != null) 'title': title,
      if (riderId != null) 'riderId': riderId,
      if (notes != null) 'notes': notes,
    });
    final response = await _dio.post('/analyses', data: formData);
    return Analysis.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getAnalysisStatus(String id) async {
    final response = await _dio.get('/analyses/$id/status');
    return response.data;
  }

  Future<void> cancelAnalysis(String id) async {
    await _dio.post('/analyses/$id/cancel');
  }

  Future<void> retryAnalysis(String id) async {
    await _dio.post('/analyses/$id/retry');
  }

  Future<void> deleteAnalysis(String id) async {
    await _dio.delete('/analyses/$id');
  }

  // ==================== REPORTS ====================

  Future<List<Report>> getReports({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
    String? horseId,
  }) async {
    final response = await _dio.get('/reports', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (horseId != null) 'horseId': horseId,
    });
    final items = response.data['items'] as List? ?? [];
    return items.map((json) => Report.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Report> getReport(String id) async {
    final response = await _dio.get('/reports/$id');
    return Report.fromJson(response.data);
  }

  Future<Report> createReport({
    required String horseId,
    required String type,
    String? title,
    List<String>? analysisIds,
  }) async {
    final response = await _dio.post('/reports', data: {
      'horseId': horseId,
      'type': type,
      if (title != null) 'title': title,
      if (analysisIds != null) 'analysisIds': analysisIds,
    });
    return Report.fromJson(response.data);
  }

  Future<void> deleteReport(String id) async {
    await _dio.delete('/reports/$id');
  }

  Future<String> shareReport(String id, {int? expirationDays}) async {
    final response = await _dio.post('/reports/$id/share', data: {
      if (expirationDays != null) 'expirationDays': expirationDays,
    });
    return response.data['shareUrl'];
  }

  Future<void> revokeReportShare(String id) async {
    await _dio.delete('/reports/$id/share');
  }

  Future<Report> getSharedReport(String shareToken) async {
    final response = await _dio.get('/reports/shared/$shareToken');
    return Report.fromJson(response.data);
  }

  // ==================== TOKENS/BILLING ====================

  Future<Map<String, dynamic>> getTokenBalance() async {
    try {
      final response = await _dio.get('/billing/tokens');
      final data = response.data;
      // Handle case where API returns a list or non-map response
      if (data is Map<String, dynamic>) {
        return data;
      }
    } on DioException catch (e) {
      debugPrint('getTokenBalance error: ${e.message}');
    }
    // Return defaults on error
    return <String, dynamic>{
      'horsesUsed': 0,
      'horsesLimit': 5,
      'analysesUsed': 0,
      'analysesLimit': 10,
    };
  }

  Future<List<Map<String, dynamic>>> getTokenHistory() async {
    try {
      final response = await _dio.get('/billing/tokens/history');
      final data = response.data;
      if (data is List) {
        return data.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
      }
    } on DioException catch (e) {
      debugPrint('getTokenHistory error: ${e.message}');
    }
    return <Map<String, dynamic>>[];
  }

  // ==================== SUBSCRIPTIONS ====================

  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final response = await _dio.get('/subscriptions/plans');
      final data = response.data;
      // API might return a map of plans keyed by plan ID, convert to list
      if (data is Map<String, dynamic>) {
        return data.entries.map((e) {
          final value = e.value;
          if (value is Map<String, dynamic>) {
            return {'id': e.key, ...value};
          } else if (value is Map) {
            return {'id': e.key, ...Map<String, dynamic>.from(value)};
          }
          return <String, dynamic>{'id': e.key};
        }).toList();
      }
      // If it's a list, safely convert each element
      if (data is List) {
        return data.map((e) {
          if (e is Map<String, dynamic>) return e;
          if (e is Map) return Map<String, dynamic>.from(e);
          return <String, dynamic>{};
        }).toList();
      }
      return <Map<String, dynamic>>[];
    } on DioException catch (e) {
      debugPrint('getPlans error: ${e.message}');
      // Return empty list on error - billing_screen will show default plans
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> getCurrentSubscription() async {
    try {
      final response = await _dio.get('/subscriptions/current');
      final data = response.data;
      // Handle case where API returns a list or non-map response
      if (data is Map<String, dynamic>) {
        return {
          'status': data['status'] ?? 'active',
          'planId': data['plan'] ?? data['planId'] ?? 'free',
          'planName': data['planName'] ?? _getPlanName(data['plan']),
          'plan': data['plan'] is Map ? data['plan'] : {'id': data['plan'] ?? 'free', 'name': _getPlanName(data['plan']), 'price': 0},
          ...data,
        };
      }
    } on DioException catch (e) {
      debugPrint('getCurrentSubscription error: ${e.message}');
    }
    // Return default subscription on error
    return <String, dynamic>{
      'status': 'active',
      'planId': 'free',
      'planName': 'Starter',
      'plan': {'id': 'free', 'name': 'Starter', 'price': 0},
    };
  }

  String _getPlanName(dynamic plan) {
    if (plan == null) return 'Starter';
    final planStr = plan.toString().toLowerCase();
    switch (planStr) {
      case 'free': return 'Gratuit';
      case 'starter': return 'Starter';
      case 'professional': return 'Professional';
      case 'enterprise': return 'Enterprise';
      default: return 'Starter';
    }
  }

  Future<Map<String, dynamic>> upgradePlan(String planId) async {
    final response = await _dio.post('/subscriptions/upgrade', data: {
      'planId': planId,
    });
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{'success': true, 'planId': planId};
  }

  Future<void> cancelSubscription() async {
    await _dio.post('/subscriptions/cancel');
  }

  Future<void> reactivateSubscription() async {
    await _dio.post('/subscriptions/reactivate');
  }

  // ==================== INVOICES ====================

  Future<List<Map<String, dynamic>>> getInvoices() async {
    try {
      final response = await _dio.get('/invoices');
      final data = response.data;
      // API returns {invoices: [], total: 0, ...}, extract the invoices list
      if (data is Map<String, dynamic> && data.containsKey('invoices')) {
        final invoices = data['invoices'];
        if (invoices is List) {
          return invoices.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
        }
      }
      if (data is List) {
        return data.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{}).toList();
      }
    } on DioException catch (e) {
      debugPrint('getInvoices error: ${e.message}');
    }
    return <Map<String, dynamic>>[];
  }

  // ==================== DASHBOARD ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/dashboard/stats');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  // ==================== GENERIC HTTP METHODS ====================

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Ressource introuvable.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? data]) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Données invalides. Vérifiez les informations saisies.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
      }
      rethrow;
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Ressource introuvable.');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Données invalides. Vérifiez les informations saisies.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
      }
      rethrow;
    }
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? data]) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Ressource introuvable.');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Données invalides. Vérifiez les informations saisies.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
      }
      rethrow;
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé. Vérifiez votre connexion internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Accès refusé.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Ressource introuvable.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
      }
      rethrow;
    }
  }

  // ==================== MEDIA UPLOAD ====================

  /// Upload media file (image or video) for social posts
  /// Returns the URL of the uploaded media
  Future<String> uploadMedia(File file, {String type = 'image'}) async {
    try {
      // Validate file size
      final fileSize = file.lengthSync();
      final maxSize = type == 'video' ? 100 * 1024 * 1024 : 10 * 1024 * 1024; // 100MB for video, 10MB for image

      if (fileSize > maxSize) {
        final maxMB = maxSize / 1024 / 1024;
        throw Exception('La taille du fichier ne doit pas dépasser ${maxMB.toInt()}MB');
      }

      // Validate mime type
      final mimeType = lookupMimeType(file.path);
      final allowedImageTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
      final allowedVideoTypes = ['video/mp4', 'video/quicktime', 'video/x-m4v'];

      if (type == 'image' && (mimeType == null || !allowedImageTypes.contains(mimeType))) {
        throw Exception('Format d\'image non supporté. Formats acceptés: JPEG, PNG, WebP, GIF');
      }

      if (type == 'video' && (mimeType == null || !allowedVideoTypes.contains(mimeType))) {
        throw Exception('Format vidéo non supporté. Formats acceptés: MP4, MOV, M4V');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
        'type': type,
      });

      // Use longer timeout for video uploads
      final options = Options(
        sendTimeout: type == 'video' ? const Duration(minutes: 5) : const Duration(minutes: 2),
        receiveTimeout: type == 'video' ? const Duration(minutes: 5) : const Duration(minutes: 2),
      );

      final response = await _dio.post(
        '/media/upload',
        data: formData,
        options: options,
      );

      // Safe response handling
      final data = response.data;
      if (data is Map<String, dynamic> && data['url'] != null) {
        return data['url'] as String;
      }
      throw Exception('Réponse invalide du serveur');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet et réessayez.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Fonctionnalité d\'upload non disponible sur ce serveur.');
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Erreur serveur: ${e.response?.statusMessage ?? "Erreur inconnue"}');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      }
      throw Exception('Erreur lors de l\'upload: ${e.message ?? e.response?.statusMessage ?? "Erreur inconnue"}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de l\'upload du fichier: $e');
    }
  }

  /// Upload multiple media files
  /// Returns list of URLs
  Future<List<String>> uploadMultipleMedia(List<File> files, {String type = 'image'}) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadMedia(file, type: type);
      urls.add(url);
    }
    return urls;
  }
}
