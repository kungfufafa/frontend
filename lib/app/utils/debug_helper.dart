import 'package:flutter/foundation.dart';

/// Helper class untuk debugging dan logging
/// Berguna untuk development dan troubleshooting
class DebugHelper {
  static const bool _isDebugMode = true; // Set false untuk production
  
  /// Log informasi umum - versi sederhana
  static void info(String message, {String? context}) {
    if (_isDebugMode) {
      debugPrint('ℹ️ ${context ?? 'INFO'}: $message');
    }
  }
  
  /// Log error - versi sederhana
  static void error(String message, {String? context, dynamic error}) {
    if (_isDebugMode) {
      debugPrint('❌ ${context ?? 'ERROR'}: $message');
      if (error != null) {
        debugPrint('   Detail: $error');
      }
    }
  }
  
  /// Log aksi user
  static void userAction(String action) {
    if (_isDebugMode) {
      debugPrint('👤 USER: $action');
    }
  }
  
  /// Log navigasi
  static void navigation(String from, String to) {
    if (_isDebugMode) {
      debugPrint('🧭 NAV: $from → $to');
    }
  }
  
  /// Log validasi form
  static void validation(String field, bool isValid, {String? errorMessage}) {
    if (_isDebugMode) {
      final status = isValid ? '✅' : '❌';
      debugPrint('📝 VALID: $field $status');
      if (!isValid && errorMessage != null) {
        debugPrint('   $errorMessage');
      }
    }
  }
  
  /// Log API call
  static void apiCall(String method, String endpoint) {
    if (_isDebugMode) {
      debugPrint('🌐 API: $method $endpoint');
    }
  }
  
  /// Log perubahan state
  static void stateChange(String controller, String property, dynamic newValue) {
    if (_isDebugMode) {
      debugPrint('🔄 STATE: $controller.$property = $newValue');
    }
  }
}

/// Extension untuk memudahkan debugging di controller - versi sederhana
extension ControllerDebug on Object {
  void logInfo(String message) {
    DebugHelper.info(message, context: runtimeType.toString());
  }
  
  void logError(String error, {dynamic errorDetail}) {
    DebugHelper.error(error, context: runtimeType.toString(), error: errorDetail);
  }
  
  void logUserAction(String action) {
    DebugHelper.userAction('${runtimeType.toString()}: $action');
  }
  
  void logStateChange(String property, dynamic newValue) {
    DebugHelper.stateChange(runtimeType.toString(), property, newValue);
  }
}

/// Contoh penggunaan:
/// 
/// Di Controller:
/// ```dart
/// class LoginController extends GetxController {
///   void login() {
///     logInfo('Login process started'); // menggunakan extension
///     
///     try {
///       // login logic
///       logUserAction('login_attempt', data: {'email': email});
///     } catch (e, stackTrace) {
///       logError('Login failed: $e', stackTrace: stackTrace);
///     }
///   }
/// }
/// ```
/// 
/// Manual logging:
/// ```dart
/// DebugHelper.info('App started');
/// DebugHelper.navigation('/login', '/profile');
/// DebugHelper.validation('email', 'Invalid format');
/// DebugHelper.apiCall('/auth/login', method: 'POST');
/// ```