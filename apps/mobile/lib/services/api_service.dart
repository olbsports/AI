import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';
import 'storage_service.dart';

// API Base URL - Change this to your backend URL
const String apiBaseUrl = 'https://api.horsetempo.app/api';

// Shared secure storage instance for token access
const _secureStorage = FlutterSecureStorage();

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add logging interceptor
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => print('DIO: $obj'),
  ));

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
        // Handle token refresh here
        final refreshToken = await _secureStorage.read(key: 'refresh_token');
        if (refreshToken != null) {
          try {
            final response = await dio.post('/auth/refresh', data: {
              'refreshToken': refreshToken,
            });
            final newToken = response.data['accessToken'];
            await _secureStorage.write(key: 'access_token', value: newToken);

            // Retry the failed request
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            await _secureStorage.deleteAll();
          }
        }
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
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'organizationName': organizationName,
      'acceptTerms': true,
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
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post('/auth/profile/photo', data: formData);
    return response.data['url'];
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
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post('/riders/$riderId/photo', data: formData);
    return response.data['url'];
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
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post('/horses/$horseId/photo', data: formData);
    return response.data['url'];
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
    return List<Map<String, dynamic>>.from(response.data);
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
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ==================== DASHBOARD ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _dio.get('/dashboard/stats');
    return response.data;
  }

  // ==================== GENERIC HTTP METHODS ====================

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final response = await _dio.get(path, queryParameters: queryParams);
    return response.data;
  }

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, Map<String, dynamic> data) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}
