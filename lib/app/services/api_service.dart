import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart';

import 'package:flutter/foundation.dart';

class ApiService extends GetConnect {
  // Basic storage untuk MVP - simple token storage
  static final _storage = GetStorage();
  static bool _isRedirecting = false; // Guard untuk mencegah multiple redirects
  
  // Debug flag untuk logging - bisa dimatikan di production
  static const bool enableApiLogging = true;
  
  @override
  void onInit() {
    // Setup dasar untuk MVP
    httpClient.baseUrl = 'https://skripsipandu.rizqis.com/api/v1';
    httpClient.defaultContentType = "application/json";
    httpClient.timeout = const Duration(seconds: 10);
    
    // Add custom decoder to handle JSON parsing properly
    httpClient.defaultDecoder = (data) {
      // Handle different response types
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is List) {
        return data;
      } else if (data is String) {
        // Try to parse string as JSON
        try {
          return json.decode(data);
        } catch (e) {
          // If not JSON, return as is
          return data;
        }
      }
      return data;
    };

    // Tambahkan token ke setiap request + logging
    httpClient.addRequestModifier<void>((request) async {
      final token = getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Log request untuk debugging
      if (enableApiLogging) {
        _logRequest(request);
      }
      
      return request;
    });

    // Handle response 401 (unauthorized) + logging
    httpClient.addResponseModifier((request, response) {
      // Log response untuk debugging
      if (enableApiLogging) {
        _logResponse(request, response);
      }
      
      if (response.statusCode == 401 && !_isRedirecting) {
        _isRedirecting = true;
        
        // Logout otomatis jika token invalid
        Future.delayed(const Duration(milliseconds: 100), () async {
          _isRedirecting = false;
          clearToken();
          _storage.remove('user_data');
          
          // Redirect ke login jika belum di halaman login
          if (Get.currentRoute != '/login') {
            Get.offAllNamed('/login');
            Get.snackbar(
              'Session Expired',
              'Silakan login kembali',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        });
      }
      return response;
    });

    super.onInit();
  }

  // Auth endpoints
  Future<Response> login(String email, String password) async {
    final body = {'email': email, 'password': password};
    return post('/auth/login', body);
  }

  Future<Response> register(RegisterRequest registerData) async {
    return post('/auth/register', registerData.toJson());
  }

  Future<Response> getProfile() async {
    return get('/auth/me');
  }

  Future<Response> refreshToken() async {
    return post('/auth/refresh', {});
  }

  Future<Response> changePassword(ChangePasswordRequest changePasswordData) async {
    return post('/auth/change-password', changePasswordData.toJson());
  }

  Future<Response> updateProfile(UpdateProfileRequest profileData) async {
    logDebug('Sending update profile request: ${profileData.toJson()}', context: 'ApiService');
    final response = await put('/auth/profile', profileData.toJson());
    logDebug('Update profile response: ${response.body}', context: 'ApiService');
    return response;
  }

  Future<Response> logout() async {
    return post('/auth/logout', {});
  }
  
  // Custom PATCH method with a different name to avoid overriding GetConnect.patch<T>
  Future<Response> patchJson(String url, dynamic body,
      {String? contentType, Map<String, String>? headers, Map<String, dynamic>? query}) async {
    try {
      // Build the full URL
      final fullUrl = httpClient.baseUrl != null 
          ? '${httpClient.baseUrl}$url'
          : url;
      
      // Log the request for debugging
      logDebug('PATCH request to: $fullUrl with body: $body', context: 'ApiService');
      
      // Use httpClient.request with PATCH method
      final response = await httpClient.request(
        url,
        'PATCH',
        body: body,
        contentType: contentType ?? httpClient.defaultContentType,
        headers: headers,
        query: query,
      );
      
      // Ensure we have a valid response
      if (response.statusCode == null) {
        logError('PATCH response has null status code', context: 'ApiService');
        return Response(
          statusCode: 500,
          statusText: 'No response from server',
          body: {'message': 'No response from server'},
        );
      }
      
      return response;
    } catch (e) {
      logError('PATCH request failed: $e', context: 'ApiService', stackTrace: e);
      return Response(
        statusCode: 500,
        statusText: 'Request failed',
        body: {'message': 'Request failed: $e'},
      );
    }
  }

  // Users endpoints
  Future<Response> getUsers({Map<String, String>? query}) async {
    return get('/users', query: query);
  }

  Future<Response> createUser(Map<String, dynamic> userData) async {
    return post('/users', userData);
  }

  Future<Response> updateUser(int userId, Map<String, dynamic> userData) async {
    return put('/users/$userId', userData);
  }

  Future<Response> deleteUser(int userId) async {
    return delete('/users/$userId');
  }

  Future<Response> getUserById(int userId) async {
    return get('/users/$userId');
  }
  
  Future<Response> getUserStats() async {
    return get('/users/stats');
  }
  
  Future<Response> toggleUserStatus(int userId) async {
    return post('/users/$userId/toggle-status', {});
  }
  
  // Karyawan endpoints
  Future<Response> getKaryawans({Map<String, String>? query}) async {
    return get('/karyawans', query: query);
  }
  
  Future<Response> createKaryawan(Map<String, dynamic> karyawanData) async {
    return post('/karyawans', karyawanData);
  }
  
  Future<Response> updateKaryawan(int karyawanId, Map<String, dynamic> karyawanData) async {
    return put('/karyawans/$karyawanId', karyawanData);
  }
  
  Future<Response> deleteKaryawan(int karyawanId) async {
    return delete('/karyawans/$karyawanId');
  }
  
  Future<Response> getKaryawanById(int karyawanId) async {
    return get('/karyawans/$karyawanId');
  }
  
  // Roles endpoints
  Future<Response> getRoles({Map<String, String>? query}) async {
    return get('/roles', query: query);
  }
  
  Future<Response> getRoleOptions() async {
    return get('/roles/options');
  }
  
  Future<Response> getRoleStats() async {
    return get('/roles/stats');
  }
  
  Future<Response> createRole(Map<String, dynamic> roleData) async {
    return post('/roles', roleData);
  }
  
  Future<Response> updateRole(int roleId, Map<String, dynamic> roleData) async {
    return put('/roles/$roleId', roleData);
  }
  
  Future<Response> deleteRole(int roleId) async {
    return delete('/roles/$roleId');
  }
  
  Future<Response> getRoleById(int roleId) async {
    return get('/roles/$roleId');
  }
  
  // Units endpoints
  Future<Response> getUnits({Map<String, String>? query}) async {
    return get('/units', query: query);
  }
  
  Future<Response> createUnit(Map<String, dynamic> unitData) async {
    return post('/units', unitData);
  }
  
  Future<Response> updateUnit(int unitId, Map<String, dynamic> unitData) async {
    return put('/units/$unitId', unitData);
  }
  
  Future<Response> deleteUnit(int unitId) async {
    return delete('/units/$unitId');
  }
  
  Future<Response> getUnitById(int unitId) async {
    return get('/units/$unitId');
  }
  
  // Statuses endpoints
  Future<Response> getStatuses({Map<String, String>? query}) async {
    return get('/statuses', query: query);
  }
  
  Future<Response> getStatusOptions() async {
    return get('/statuses/options');
  }
  
  Future<Response> getStatusStats() async {
    return get('/statuses/stats');
  }
  
  Future<Response> reorderStatuses(List<Map<String, dynamic>> orderData) async {
    return post('/statuses/reorder', orderData);
  }
  
  Future<Response> createStatus(Map<String, dynamic> statusData) async {
    return post('/statuses', statusData);
  }
  
  Future<Response> updateStatus(int statusId, Map<String, dynamic> statusData) async {
    return put('/statuses/$statusId', statusData);
  }
  
  Future<Response> deleteStatus(int statusId) async {
    return delete('/statuses/$statusId');
  }
  
  Future<Response> getStatusById(int statusId) async {
    return get('/statuses/$statusId');
  }
  
  // Tiket endpoints
  Future<Response> getTikets({Map<String, String>? query}) async {
    return get('/tikets', query: query);
  }
  
  Future<Response> getTiketStats() async {
    return get('/tikets/stats');
  }
  
  Future<Response> createTiket(CreateTiketRequest tiketData) async {
    return post('/tikets', tiketData.toJson());
  }
  
  Future<Response> updateTiket(int tiketId, UpdateTiketRequest tiketData) async {
    return put('/tikets/$tiketId', tiketData.toJson());
  }
  
  Future<Response> deleteTiket(int tiketId) async {
    return delete('/tikets/$tiketId');
  }
  
  Future<Response> getTiketById(int tiketId) async {
    return get('/tikets/$tiketId');
  }
  
  Future<Response> assignTiketToUnit(int tiketId, int unitId, {int? karyawanId, String? komentar}) async {
    final body = <String, dynamic>{'id_unit': unitId};
    if (karyawanId != null) body['id_karyawan'] = karyawanId;
    if (komentar != null && komentar.isNotEmpty) body['komentar'] = komentar;
    return patchJson('/tikets/$tiketId/assign', body);
  }
  
  Future<Response> assignTiketToKaryawan(int tiketId, int karyawanId, {String? komentar}) async {
    final body = <String, dynamic>{'id_karyawan': karyawanId};
    if (komentar != null && komentar.isNotEmpty) body['komentar'] = komentar;
    return patchJson('/tikets/$tiketId/assign-karyawan', body);
  }
  
  Future<Response> updateTiketStatus(int tiketId, UpdateStatusRequest statusData) async {
    return patchJson('/tikets/$tiketId/status', statusData.toJson());
  }
  
  // Komentar endpoints
  Future<Response> getKomentars(int tiketId, {Map<String, String>? query}) async {
    return get('/tikets/$tiketId/komentars', query: query);
  }
  
  Future<Response> createKomentar(int tiketId, CreateKomentarRequest komentarData) async {
    return post('/tikets/$tiketId/komentars', komentarData.toJson());
  }
  
  Future<Response> updateKomentar(int komentarId, Map<String, dynamic> komentarData) async {
    return put('/komentars/$komentarId', komentarData);
  }
  
  Future<Response> deleteKomentar(int komentarId) async {
    return delete('/komentars/$komentarId');
  }
  
  Future<Response> getKomentarById(int komentarId) async {
    return get('/komentars/$komentarId');
  }
  
  Future<Response> getKomentarStats() async {
    return get('/komentars/stats');
  }
  
  // Dashboard endpoints (role-based)
  Future<Response> getAdminDashboardStats() async {
    return get('/dashboard/admin/stats');
  }
  
  Future<Response> getAdminReports({String? dateFrom, String? dateTo}) async {
    final query = <String, String>{};
    if (dateFrom != null && dateFrom.isNotEmpty) query['date_from'] = dateFrom;
    if (dateTo != null && dateTo.isNotEmpty) query['date_to'] = dateTo;
    return get('/dashboard/admin/reports', query: query.isEmpty ? null : query);
  }
  
  Future<Response> getManagerDashboardStats() async {
    return get('/dashboard/manager/stats');
  }
  
  Future<Response> getManagerUnitPerformance() async {
    return get('/dashboard/manager/unit-performance');
  }
  
  Future<Response> getKaryawanDashboardStats() async {
    return get('/dashboard/karyawan/stats');
  }
  
  Future<Response> getKaryawanMyTikets() async {
    return get('/dashboard/karyawan/my-tikets');
  }
  
  Future<Response> getDireksiDashboardStats() async {
    return get('/dashboard/direksi/stats');
  }
  
  Future<Response> getDireksiPerformanceReports() async {
    return get('/dashboard/direksi/performance-reports');
  }
  
  Future<Response> getUserDashboardStats() async {
    return get('/dashboard/user/stats');
  }
  
  Future<Response> getUserMyTikets() async {
    return get('/dashboard/user/my-tikets');
  }

  // Helper method untuk store token - basic implementation
  static void storeToken(String token) {
    _storage.write('auth_token', token);
  }

  // Helper method untuk clear token
  static void clearToken() {
    _storage.remove('auth_token');
  }

  // Helper method untuk get token
  static String? getToken() {
    return _storage.read('auth_token');
  }
  
  // === LOGGING METHODS UNTUK DEBUGGING ===
  
  /// Log API request untuk debugging - versi sederhana
  static void _logRequest(dynamic request) {
    try {
      final method = request.method;
      final url = request.url.toString().replaceAll('https://skripsipandu.rizqis.com/api/v1', '');
      
      debugPrint('🚀 $method $url');
      
      // Log body hanya jika bukan login (untuk keamanan)
      // Skip body logging untuk stream-based requests untuk menghindari error
      if (!url.contains('login')) {
        try {
          // Coba akses body jika tersedia sebagai string
          if (request.body != null && request.body.toString().isNotEmpty) {
            final bodyStr = request.body.toString();
            if (bodyStr.length > 100) {
              debugPrint('📦 ${bodyStr.substring(0, 100)}...');
            } else {
              debugPrint('📦 $bodyStr');
            }
          }
        } catch (bodyError) {
          // Jika gagal akses body, skip logging body
          debugPrint('📦 [Body logging skipped]');
        }
      }
    } catch (e) {
      debugPrint('❌ Log error: $e');
    }
  }
  
  /// Log API response untuk debugging - versi sederhana
  static void _logResponse(dynamic request, Response response) {
    try {
      final method = request.method;
      final url = request.url.toString().replaceAll('https://skripsipandu.rizqis.com/api/v1', '');
      final statusCode = response.statusCode;
      
      // Emoji berdasarkan status
      String emoji = '✅';
      if (statusCode != null) {
        if (statusCode >= 400 && statusCode < 500) {
          emoji = '⚠️';
        } else if (statusCode >= 500) {
          emoji = '❌';
        }
      }
      
      debugPrint('$emoji $method $url → $statusCode');
      
      // Hanya log error message jika ada error
      if (statusCode != null && statusCode >= 400 && response.body != null) {
        try {
          if (response.body is Map && (response.body as Map).containsKey('message')) {
            debugPrint('   Error: ${(response.body as Map)['message']}');
          } else if (response.body is String) {
            debugPrint('   Error: ${response.body}');
          }
        } catch (_) {
          // ignore logging errors
        }
      }
    } catch (e) {
      debugPrint('❌ Log error: $e');
    }
  }
  
  /// Helper method untuk log custom message - versi sederhana
  static void logDebug(String message, {String? context}) {
    if (enableApiLogging) {
      debugPrint('🔍 ${context ?? 'DEBUG'}: $message');
    }
  }
  
  /// Helper method untuk log error - versi sederhana
  static void logError(String error, {String? context, dynamic stackTrace}) {
    debugPrint('❌ ${context ?? 'ERROR'}: $error');
    // Stack trace hanya di debug mode dan jika perlu
    if (stackTrace != null && enableApiLogging) {
      debugPrint('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    }
  }
}