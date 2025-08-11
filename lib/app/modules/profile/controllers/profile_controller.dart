import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/services/auth_service.dart';

class ProfileController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  final AuthService authService = Get.find<AuthService>();

  // User data
  var currentUser = Rxn<User>();
  var isLoadingProfile = false.obs;

  // Update profile form
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  var isUpdatingProfile = false.obs;

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
    // Ambil data user dari AuthService terlebih dahulu
    final authUser = authService.user;
    if (authUser != null) {
      currentUser.value = authUser;
      namaController.text = authUser.nama;
      emailController.text = authUser.email;
      ApiService.logDebug('Data user diambil dari AuthService - Nama: ${authUser.nama}, Email: ${authUser.email}', context: 'ProfileController');
    }
    
    // Kemudian load dari API untuk data terbaru
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

  void loadUserProfile() async {
    // Check if user is still logged in
    if (authService.user == null || !authService.isLoggedIn) {
      ApiService.logDebug('User not logged in, skipping profile load', context: 'ProfileController');
      return;
    }
    
    try {
      isLoadingProfile(true);
      ApiService.logDebug('Memuat profil user', context: 'ProfileController');
      
      var response = await apiService.getProfile();

      if (response.statusCode == 200) {
        ApiService.logDebug('Berhasil memuat profil user', context: 'ProfileController');
        currentUser.value = User.fromJson(response.body['data'] ?? response.body);
        
        // Populate form fields with current user data
        namaController.text = currentUser.value?.nama ?? '';
        emailController.text = currentUser.value?.email ?? '';
      } else if (response.statusCode == 401) {
        // User is not authenticated, don't show error
        ApiService.logDebug('User not authenticated', context: 'ProfileController');
      } else {
        ApiService.logError('Gagal memuat profil: ${response.statusCode}', context: 'ProfileController');
        Get.snackbar(
          'Error',
          'Gagal memuat profil user: ${response.body?['message'] ?? 'Unknown error'}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      ApiService.logError('Exception saat memuat profil: $e', context: 'ProfileController');
      // Only show error if user is still logged in
      if (authService.isLoggedIn) {
        Get.snackbar(
          'Error',
          'Terjadi kesalahan: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } finally {
      isLoadingProfile(false);
    }
  }

  void updateProfile() async {
    if (!_validateProfileForm()) return;
  
    try {
      isUpdatingProfile(true);
      
      // Log untuk debugging
      ApiService.logDebug('Memulai update profile', context: 'ProfileController');
  
      // Ambil data user saat ini untuk perbandingan
      final currentUserData = currentUser.value;
      if (currentUserData == null) {
        Get.snackbar('Error', 'Data user tidak ditemukan');
        return;
      }
  
      // Buat request dengan semua field yang diperlukan
      final updateRequest = UpdateProfileRequest(
        nama: namaController.text.trim(),
        email: emailController.text.trim(),
      );

      // Validasi apakah ada perubahan
      if (namaController.text.trim() == currentUserData.nama && 
          emailController.text.trim() == currentUserData.email) {
        Get.snackbar(
          'Info',
          'Tidak ada perubahan data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
        return;
      }
  
      ApiService.logDebug('Mengirim request update dengan semua field - Nama: ${updateRequest.nama}, Email: ${updateRequest.email}', context: 'ProfileController');
  
      var response = await apiService.updateProfile(updateRequest);
  
      if (response.statusCode == 200) {
        ApiService.logDebug('Update profile berhasil', context: 'ProfileController');
        
        // Debug: Log response data
        ApiService.logDebug('Response data: ${response.body}', context: 'ProfileController');
        
        // Update user data di AuthService juga
        final updatedUserData = response.body['data'] ?? response.body;
        ApiService.logDebug('Raw updated user data: $updatedUserData', context: 'ProfileController');
        
        final updatedUser = User.fromJson(updatedUserData);
        
        // Debug: Log updated user data
        ApiService.logDebug('Parsed updated user - Nama: ${updatedUser.nama}, Email: ${updatedUser.email}', context: 'ProfileController');
        ApiService.logDebug('Current user before update - Nama: ${currentUser.value?.nama}, Email: ${currentUser.value?.email}', context: 'ProfileController');
        
        // Update currentUser untuk reactive UI
        currentUser.value = updatedUser;
        
        // Update form controllers dengan data terbaru
        namaController.text = updatedUser.nama;
        emailController.text = updatedUser.email;
        
        // Update user data di AuthService agar sinkron
        authService.updateUserData(updatedUser);
        
        // Debug: Log current user after update
        ApiService.logDebug('Current user after update - Nama: ${currentUser.value?.nama}, Email: ${currentUser.value?.email}', context: 'ProfileController');
        ApiService.logDebug('Form controllers updated - Nama: ${namaController.text}, Email: ${emailController.text}', context: 'ProfileController');
        
        Get.snackbar(
          'Success',
          'Profil berhasil diupdate',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        ApiService.logError('Update profile gagal: ${response.statusCode}', context: 'ProfileController');
        final errorMessage = _extractErrorMessage(response);
        Get.snackbar(
          'Error',
          'Gagal update profil: $errorMessage',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      ApiService.logError('Exception saat update profile: $e', context: 'ProfileController');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isUpdatingProfile(false);
    }
  }

  void changePassword() async {
    if (!_validatePasswordForm()) return;

    try {
      isChangingPassword(true);

      final changePasswordRequest = ChangePasswordRequest(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        newPasswordConfirmation: confirmNewPasswordController.text,
      );

      var response = await apiService.changePassword(changePasswordRequest);

      if (response.statusCode == 200) {
        // Clear password form
        _clearPasswordForm();
        
        Get.snackbar(
          'Success',
          'Password berhasil diubah',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        final errorMessage = _extractErrorMessage(response);
        Get.snackbar(
          'Error',
          'Gagal ubah password: $errorMessage',
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
      isChangingPassword(false);
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

    return true;
  }

  bool _validatePasswordForm() {
    if (currentPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Password saat ini tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (newPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Password baru tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (newPasswordController.text.length < 8) {
      Get.snackbar(
        'Error',
        'Password baru minimal 8 karakter',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (confirmNewPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Konfirmasi password baru tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (newPasswordController.text != confirmNewPasswordController.text) {
      Get.snackbar(
        'Error',
        'Password baru dan konfirmasi tidak sama',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (currentPasswordController.text == newPasswordController.text) {
      Get.snackbar(
        'Error',
        'Password baru harus berbeda dari password saat ini',
        snackPosition: SnackPosition.BOTTOM,
      );
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
