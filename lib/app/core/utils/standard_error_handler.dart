import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/services/auth_service.dart';

/// Utility class untuk menangani error dengan konsisten di seluruh aplikasi
/// Menggunakan prinsip KISS dengan penanganan error yang sederhana dan informatif
class StandardErrorHandler {
  // Private constructor untuk mencegah instantiation
  StandardErrorHandler._();
  
  /// Menangani error dari API response
  static void handleApiError(
    dynamic error, {
    String? context,
    bool showSnackbar = true,
    String? customMessage,
  }) {
    String message = customMessage ?? 'Terjadi kesalahan';
    bool shouldRedirectToLogin = false;
    
    // Analisis jenis error
    if (error is Response) {
      final statusCode = error.statusCode;
      final responseBody = error.body;
      
      switch (statusCode) {
        case 400:
          message = _extractErrorMessage(responseBody) ?? 'Permintaan tidak valid';
          break;
        case 401:
          message = 'Sesi Anda telah berakhir. Silakan login kembali';
          shouldRedirectToLogin = true;
          break;
        case 403:
          message = 'Anda tidak memiliki akses untuk melakukan operasi ini';
          break;
        case 404:
          message = 'Data tidak ditemukan';
          break;
        case 422:
          message = _extractValidationErrors(responseBody) ?? 'Data tidak valid';
          break;
        case 429:
          message = 'Terlalu banyak permintaan. Silakan coba lagi nanti';
          break;
        case 500:
          message = 'Terjadi kesalahan server. Silakan coba lagi';
          break;
        case 502:
          message = 'Server sedang maintenance. Silakan coba lagi nanti';
          break;
        case 503:
          message = 'Service tidak tersedia. Silakan coba lagi nanti';
          break;
        default:
          message = _extractErrorMessage(responseBody) ?? 'Terjadi kesalahan: HTTP $statusCode';
      }
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('TimeoutException')) {
      message = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda';
    } else if (error.toString().contains('FormatException')) {
      message = 'Format data tidak valid';
    } else if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else {
      message = error.toString();
    }
    
    // Log error untuk debugging
    _logError(error, context);
    
    // Tampilkan snackbar jika diminta
    if (showSnackbar) {
      AppSnackbar.error(message);
    }
    
    // Handle session expired
    if (shouldRedirectToLogin) {
      _handleSessionExpired();
    }
  }
  
  /// Menangani error validasi dengan detail field yang error
  static void handleValidationError(
    Map<String, dynamic>? errors, {
    String? context,
    bool showSnackbar = true,
  }) {
    if (errors == null || errors.isEmpty) {
      if (showSnackbar) {
        AppSnackbar.error('Validasi gagal');
      }
      return;
    }
    
    // Ambil error pertama yang ditemukan
    final firstField = errors.keys.first;
    final firstError = errors[firstField];
    
    String message = 'Validasi gagal';
    if (firstError is List && firstError.isNotEmpty) {
      message = firstError.first.toString();
    } else if (firstError is String) {
      message = firstError;
    }
    
    _logError('Validation error: $errors', context);
    
    if (showSnackbar) {
      AppSnackbar.error(message);
    }
  }
  
  /// Menangani error jaringan
  static void handleNetworkError({
    String? context,
    bool showSnackbar = true,
    String? customMessage,
  }) {
    final message = customMessage ?? 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda';
    
    _logError('Network error', context);
    
    if (showSnackbar) {
      AppSnackbar.error(message);
    }
  }
  
  /// Menangani error umum dengan retry option
  static void handleErrorWithRetry(
    dynamic error, {
    String? context,
    VoidCallback? onRetry,
    String? retryButtonText,
  }) {
    String message = _getErrorMessage(error);
    
    _logError(error, context);
    
    if (onRetry != null) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        mainButton: TextButton(
          onPressed: onRetry,
          child: Text(retryButtonText ?? 'Coba Lagi'),
        ),
      );
    } else {
      AppSnackbar.error(message);
    }
  }
  
  /// Ekstrak pesan error dari response body
  static String? _extractErrorMessage(dynamic responseBody) {
    if (responseBody == null) return null;
    
    if (responseBody is Map<String, dynamic>) {
      // Coba berbagai field yang mungkin berisi pesan error
      final possibleFields = ['message', 'error', 'detail', 'msg'];
      
      for (final field in possibleFields) {
        if (responseBody.containsKey(field) && responseBody[field] != null) {
          return responseBody[field].toString();
        }
      }
    } else if (responseBody is String) {
      return responseBody;
    }
    
    return null;
  }
  
  /// Ekstrak pesan error dari validation errors
  static String? _extractValidationErrors(dynamic responseBody) {
    if (responseBody is Map<String, dynamic> && responseBody.containsKey('errors')) {
      final errors = responseBody['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        } else if (firstError is String) {
          return firstError;
        }
      }
    }
    
    return _extractErrorMessage(responseBody);
  }
  
  /// Mendapatkan pesan error yang sesuai
  static String _getErrorMessage(dynamic error) {
    if (error is Response) {
      return _extractErrorMessage(error.body) ?? 'Terjadi kesalahan';
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return error.toString();
    }
  }
  
  /// Log error untuk debugging
  static void _logError(dynamic error, String? context) {
    if (kDebugMode) {
      final contextInfo = context != null ? '[$context] ' : '';
      debugPrint('❌ ${contextInfo}Error: $error');
      
      if (error is Response) {
        debugPrint('❌ ${contextInfo}Status Code: ${error.statusCode}');
        debugPrint('❌ ${contextInfo}Response Body: ${error.body}');
      }
    }
  }
  
  /// Handle session expired
  static void _handleSessionExpired() {
    try {
      final authService = Get.find<AuthService>();
      authService.logout();
    } catch (e) {
      // Jika AuthService tidak tersedia, redirect manual
      Get.offAllNamed('/login');
    }
  }
  
  /// Helper methods untuk error spesifik
  static void handleCreateError(String itemType, dynamic error, {String? context}) {
    handleApiError(
      error,
      context: context ?? 'Create $itemType',
      customMessage: 'Gagal membuat $itemType',
    );
  }
  
  static void handleUpdateError(String itemType, dynamic error, {String? context}) {
    handleApiError(
      error,
      context: context ?? 'Update $itemType',
      customMessage: 'Gagal memperbarui $itemType',
    );
  }
  
  static void handleDeleteError(String itemType, dynamic error, {String? context}) {
    handleApiError(
      error,
      context: context ?? 'Delete $itemType',
      customMessage: 'Gagal menghapus $itemType',
    );
  }
  
  static void handleLoadError(String itemType, dynamic error, {String? context}) {
    handleApiError(
      error,
      context: context ?? 'Load $itemType',
      customMessage: 'Gagal memuat $itemType',
    );
  }
  
  /// Helper untuk error handling dengan callback
  static Future<T?> handleAsyncOperation<T>({
    required Future<T> Function() operation,
    String? context,
    String? errorMessage,
    bool showSnackbar = true,
  }) async {
    try {
      return await operation();
    } catch (error) {
      handleApiError(
        error,
        context: context,
        showSnackbar: showSnackbar,
        customMessage: errorMessage,
      );
      return null;
    }
  }
}