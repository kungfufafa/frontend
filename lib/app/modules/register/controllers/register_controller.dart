import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/core/utils/standard_form_validation.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/routes/app_pages.dart';

class RegisterController extends BaseController {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

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

  @override
  bool validateForm() {
    return _validateForm();
  }

  @override
  void navigateToListPage() {
    Get.offNamed(Routes.LOGIN); // Navigate to login after successful registration
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void register() async {
    await performCreateOperation(
      createFunction: () => _registerUserData(),
      successMessage: 'Registrasi berhasil! Silakan login dengan akun Anda.',
      loadingMessage: 'Mendaftarkan akun...',
    );
  }

  Future<void> _registerUserData() async {
    final registerRequest = RegisterRequest(
      nama: namaController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      passwordConfirmation: confirmPasswordController.text,
    );

    var response = await apiService.register(registerRequest);

    if (response.statusCode == 201 || response.statusCode == 200) {
      _clearForm();
    } else {
      throw Exception(_extractErrorMessage(response));
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
    final namaError = StandardFormValidation.validateMinLength(namaController.text, 2, 'Nama');
    if (namaError != null) {
      AppSnackbar.error(namaError);
      return false;
    }

    final emailError = StandardFormValidation.validateEmail(emailController.text);
    if (emailError != null) {
      AppSnackbar.error(emailError);
      return false;
    }

    final passwordError = StandardFormValidation.validateMinLength(passwordController.text, 8, 'Password');
    if (passwordError != null) {
      AppSnackbar.error(passwordError);
      return false;
    }

    final confirmPasswordError = StandardFormValidation.validatePasswordConfirmation(
      confirmPasswordController.text,
      passwordController.text,
    );
    if (confirmPasswordError != null) {
      AppSnackbar.error(confirmPasswordError);
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