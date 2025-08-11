import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  static final _storage = GetStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var isLoading = false.obs;
  var obscurePassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    // AuthService akan handle auto-login di middleware
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }



  void login() async {
    if (!_validateForm()) return;

    try {
      isLoading(true);
      
      // Log attempt untuk debugging
      ApiService.logDebug('Login attempt started', context: 'LoginController');
      
      final result = await authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (result.isSuccess) {
        // Log success untuk debugging
        ApiService.logDebug('Login successful', context: 'LoginController');
        
        // Clear form
        emailController.clear();
        passwordController.clear();
        
        // Navigate to dashboard
        Get.offAllNamed(Routes.DASHBOARD);
        
        Get.snackbar(
          'Success',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        // Log error untuk debugging
        ApiService.logError('Login failed: ${result.message}', context: 'LoginController');
        
        Get.snackbar(
          'Error Login',
          result.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e, stackTrace) {
      // Log exception untuk debugging
      ApiService.logError('Login exception: $e', context: 'LoginController', stackTrace: stackTrace);
      
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading(false);
      ApiService.logDebug('Login attempt finished', context: 'LoginController');
    }
  }

  // Form validation - sederhana dan beginner friendly
  bool _validateForm() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Cek email kosong
    if (email.isEmpty) {
      _showErrorMessage('Email tidak boleh kosong');
      return false;
    }

    // Cek password kosong
    if (password.isEmpty) {
      _showErrorMessage('Password tidak boleh kosong');
      return false;
    }

    // Validasi email sederhana
    if (!email.contains('@') || !email.contains('.')) {
      _showErrorMessage('Format email tidak valid');
      return false;
    }

    // Password minimal 6 karakter (untuk MVP)
    if (password.length < 6) {
      _showErrorMessage('Password minimal 6 karakter');
      return false;
    }

    return true;
  }

  // Helper method untuk menampilkan error message
  void _showErrorMessage(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      duration: const Duration(seconds: 3),
    );
  }



  // Get stored user data
  static User? getStoredUserData() {
    try {
      final userData = _storage.read('user_data');
      if (userData != null) {
        return userFromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Token refresh method - basic implementation for MVP
  static Future<bool> refreshAuthToken() async {
    try {
      final apiService = Get.find<ApiService>();
      var response = await apiService.refreshToken();
      
      if (response.statusCode == 200) {
        final newToken = response.body['token'];
        if (newToken != null) {
          ApiService.storeToken(newToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if user is authenticated - basic token presence check for MVP
  static bool isAuthenticated() {
    try {
      final token = ApiService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Logout method sederhana - menggunakan AuthService
  static Future<void> performLogout() async {
    try {
      final authService = Get.find<AuthService>();
      await authService.logout();
    } catch (e) {
      // Fallback jika AuthService tidak tersedia
      ApiService.clearToken();
      _storage.remove('user_data');
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  // Method untuk navigate ke register
  void goToRegister() {
    Get.toNamed(Routes.REGISTER);
  }
}