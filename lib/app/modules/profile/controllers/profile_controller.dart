import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/core/utils/standard_form_validation.dart';
import 'package:frontend/app/core/utils/standard_error_handler.dart';
import 'package:frontend/app/data/models/user_model.dart';

class ProfileController extends BaseController {
  // User data
  var currentUser = Rxn<User>();
  var isLoadingProfile = false.obs;
  var isUpdatingProfile = false.obs;  // Added missing property

  // Update profile form
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Change password form
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();
  var isChangingPassword = false.obs;
  var obscureCurrentPassword = true.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmNewPassword = true.obs;

  // Tab controller
  var selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final authUser = authService.user;
    if (authUser != null) {
      currentUser.value = authUser;
      namaController.text = authUser.nama;
      emailController.text = authUser.email;
      debugPrint('Data user diambil dari AuthService - Nama: ${authUser.nama}, Email: ${authUser.email}');
    }
    
    loadUserProfile();
  }

  @override
  void onClose() {
    namaController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.onClose();
  }

  @override
  bool validateForm() {
    return _validateProfileForm();
  }

  @override
  Future<void> refreshData() async {
    await loadUserProfile();
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword.value = !obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmNewPasswordVisibility() {
    obscureConfirmNewPassword.value = !obscureConfirmNewPassword.value;
  }

  Future<void> loadUserProfile() async {
    if (authService.user == null || !authService.isLoggedIn) {
      debugPrint('User not logged in, skipping profile load');
      return;
    }
    
    try {
      isLoadingProfile.value = true;
      debugPrint('Loading user profile...');
      
      var response = await apiService.getProfile();

      if (response.statusCode == 200) {
        debugPrint('Profile loaded successfully');
        currentUser.value = User.fromJson(response.body['data'] ?? response.body);
        
        namaController.text = currentUser.value?.nama ?? '';
        emailController.text = currentUser.value?.email ?? '';
      } else if (response.statusCode == 401) {
        debugPrint('User not authenticated');
      } else {
        throw Exception(response.body?['message'] ?? 'Gagal memuat profil');
      }
    } catch (e) {
      if (authService.isLoggedIn) {
        StandardErrorHandler.handleLoadError('profil user', e, context: 'Load Profile');
      }
    } finally {
      isLoadingProfile.value = false;
    }
  }

  void updateProfile() async {
    if (!validateForm()) return;

    try {
      isUpdatingProfile.value = true;
      
      await _updateProfileData();
      
      showSuccessSnackbar('Profil berhasil diperbarui');
    } catch (e) {
      handleError(e, context: 'updateProfile');
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  Future<void> _updateProfileData() async {
    final currentUserData = currentUser.value;
    if (currentUserData == null) {
      throw Exception('Data user tidak ditemukan');
    }

    // Check if there are any changes
    if (namaController.text.trim() == currentUserData.nama && 
        emailController.text.trim() == currentUserData.email) {
      AppSnackbar.info('Tidak ada perubahan data');
      return;
    }

    final updateRequest = UpdateProfileRequest(
      nama: namaController.text.trim(),
      email: emailController.text.trim(),
    );

    debugPrint('Updating profile with data - Nama: ${updateRequest.nama}, Email: ${updateRequest.email}');

    var response = await apiService.updateProfile(updateRequest);

    if (response.statusCode == 200) {
      debugPrint('Profile update successful');
      
      final updatedUserData = response.body['data'] ?? response.body;
      final updatedUser = User.fromJson(updatedUserData);
      
      currentUser.value = updatedUser;
      namaController.text = updatedUser.nama;
      emailController.text = updatedUser.email;
      
      authService.updateUserData(updatedUser);
      
      debugPrint('Profile updated - Nama: ${currentUser.value?.nama}, Email: ${currentUser.value?.email}');
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  void changePassword() async {
    if (!_validatePasswordForm()) return;

    try {
      isChangingPassword.value = true;
      AppSnackbar.updateLoading('password');

      final changePasswordRequest = ChangePasswordRequest(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        newPasswordConfirmation: confirmNewPasswordController.text,
      );

      var response = await apiService.changePassword(changePasswordRequest);

      if (response.statusCode == 200) {
        _clearPasswordForm();
        AppSnackbar.updateSuccess('password');
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } catch (e) {
      StandardErrorHandler.handleUpdateError('password', e, context: 'Change Password');
    } finally {
      isChangingPassword.value = false;
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

  bool _validateProfileForm() {
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

    return true;
  }

  bool _validatePasswordForm() {
    final currentPasswordError = StandardFormValidation.validateRequired(currentPasswordController.text, 'Password saat ini');
    if (currentPasswordError != null) {
      AppSnackbar.error(currentPasswordError);
      return false;
    }

    final newPasswordError = StandardFormValidation.validateMinLength(newPasswordController.text, 8, 'Password baru');
    if (newPasswordError != null) {
      AppSnackbar.error(newPasswordError);
      return false;
    }

    final confirmPasswordError = StandardFormValidation.validatePasswordConfirmation(
      confirmNewPasswordController.text, 
      newPasswordController.text
    );
    if (confirmPasswordError != null) {
      AppSnackbar.error(confirmPasswordError);
      return false;
    }

    if (currentPasswordController.text == newPasswordController.text) {
      AppSnackbar.error('Password baru harus berbeda dari password saat ini');
      return false;
    }

    return true;
  }

  void _clearPasswordForm() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();
  }

  void refreshProfile() {
    loadUserProfile();
  }

  // Logout dengan konfirmasi sederhana
  void logout() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Tutup dialog
              await authService.logout(); // Logout langsung
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
