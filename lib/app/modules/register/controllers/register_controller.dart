import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/routes/app_pages.dart';

class RegisterController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;

  @override
  void onClose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void register() async {
    if (!_validateForm()) return;

    try {
      isLoading(true);

      final registerRequest = RegisterRequest(
        nama: namaController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );

      var response = await apiService.register(registerRequest);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Registration successful
        Get.snackbar(
          'Success',
          'Registrasi berhasil! Silakan login dengan akun Anda.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          duration: const Duration(seconds: 3),
        );

        // Clear form
        _clearForm();

        // Navigate to login
        Get.offNamed(Routes.LOGIN);
      } else {
        // Handle validation errors or other errors
        final errorMessage = _extractErrorMessage(response);
        Get.snackbar(
          'Error',
          'Registrasi Gagal: $errorMessage',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading(false);
    }
  }

  String _extractErrorMessage(Response response) {
    if (response.body != null) {
      // Handle validation errors
      if (response.body['errors'] != null) {
        final errors = response.body['errors'] as Map<String, dynamic>;
        String errorText = '';
        errors.forEach((field, messages) {
          if (messages is List) {
            errorText += '${messages.join(', ')}\n';
          }
        });
        return errorText.trim();
      }
      
      // Handle single message
      if (response.body['message'] != null) {
        return response.body['message'];
      }
    }
    
    return 'Terjadi kesalahan tidak diketahui';
  }

  bool _validateForm() {
    // Validate nama
    if (namaController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Nama tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (namaController.text.trim().length < 2) {
      Get.snackbar(
        'Error',
        'Nama minimal 2 karakter',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Validate email
    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Email tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Format email tidak valid',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Validate password
    if (passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Password tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Error',
        'Password minimal 8 karakter',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // Validate password confirmation
    if (confirmPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Konfirmasi password tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Password dan konfirmasi password tidak sama',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  void _clearForm() {
    namaController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
  }

  void goToLogin() {
    Get.offNamed(Routes.LOGIN);
  }
}