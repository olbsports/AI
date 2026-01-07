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
      final response = await _dio.post('/auth/profile/photo', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      }
      throw Exception('Erreur lors de l\'upload de la photo: ${e.message}');
    } catch (e) {
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
      final response = await _dio.post('/riders/$riderId/photo', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      }
      throw Exception('Erreur lors de l\'upload de la photo: ${e.message}');
    } catch (e) {
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
      final response = await _dio.post('/horses/$horseId/photo', data: formData);
      return response.data['url'] as String;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      }
      throw Exception('Erreur lors de l\'upload de la photo: ${e.message}');
    } catch (e) {
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
    final response = await _dio.get('/billing/tokens');
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getTokenHistory() async {
    final response = await _dio.get('/billing/tokens/history');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ==================== SUBSCRIPTIONS ====================

  Future<List<Map<String, dynamic>>> getPlans() async {
    final response = await _dio.get('/subscriptions/plans');
    final data = response.data;
    // API returns a map of plans keyed by plan ID, convert to list
    if (data is Map<String, dynamic>) {
      return data.entries.map((e) => {
        'id': e.key,
        ...Map<String, dynamic>.from(e.value as Map),
      }).toList();
    }
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await _dio.get('/subscriptions/current');
    return response.data;
  }

  Future<Map<String, dynamic>> upgradePlan(String planId) async {
    final response = await _dio.post('/subscriptions/upgrade', data: {
      'planId': planId,
    });
    return response.data;
  }

  Future<void> cancelSubscription() async {
    await _dio.post('/subscriptions/cancel');
  }

  Future<void> reactivateSubscription() async {
    await _dio.post('/subscriptions/reactivate');
  }

  // ==================== INVOICES ====================

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final response = await _dio.get('/invoices');
    final data = response.data;
    // API returns {invoices: [], total: 0, ...}, extract the invoices list
    if (data is Map<String, dynamic> && data.containsKey('invoices')) {
      return List<Map<String, dynamic>>.from(data['invoices']);
    }
    return List<Map<String, dynamic>>.from(data);
  }

  // ==================== DASHBOARD ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/dashboard/stats');
    return response.data;
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

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
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
      return response.data['url'] as String;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai d\'attente dépassé lors de l\'upload. Vérifiez votre connexion internet et réessayez.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('Le fichier est trop volumineux pour le serveur.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Format de fichier non accepté par le serveur.');
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Erreur serveur: ${e.response?.statusMessage ?? "Erreur inconnue"}');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
      }
      throw Exception('Erreur lors de l\'upload: ${e.message}');
    } catch (e) {
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
