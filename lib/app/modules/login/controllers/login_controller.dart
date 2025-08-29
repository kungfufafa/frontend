import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/core/utils/standard_form_validation.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/routes/app_pages.dart';

class LoginController extends BaseController {
  // Remove duplicate AuthService declaration since it's in BaseController
  // final AuthService authService = Get.find<AuthService>();
  static final _storage = GetStorage();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // var isLoading = false.obs; // Use isSubmitting from BaseController instead
  var obscurePassword = true.obs;


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
    if (!validateForm()) return;

    try {
      isSubmitting(true);
      
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
        
        showSuccessSnackbar(result.message);
      } else {
        // Log error untuk debugging
        ApiService.logError('Login failed: ${result.message}', context: 'LoginController');
        
        showErrorSnackbar(result.message);
      }
    } catch (e) {
      // Use standardized error handling from BaseController
      handleError(e, context: 'login');
    } finally {
      isSubmitting(false);
      ApiService.logDebug('Login attempt finished', context: 'LoginController');
    }
  }

  // Override BaseController form validation
  @override
  bool validateForm() {
    // Validate email using StandardFormValidation
    final emailError = StandardFormValidation.validateEmail(emailController.text);
    if (emailError != null) {
      showErrorSnackbar(emailError);
      return false;
    }

    // Validate password using StandardFormValidation
    final passwordError = StandardFormValidation.validatePassword(passwordController.text);
    if (passwordError != null) {
      showErrorSnackbar(passwordError);
      return false;
    }

    return true;
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