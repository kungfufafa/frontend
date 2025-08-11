import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/routes/app_pages.dart';

class AuthService extends GetxController {
  static AuthService get instance => Get.find();
  
  final ApiService _apiService = Get.find<ApiService>();
  final GetStorage _storage = GetStorage();
  
  // Observable states
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoggedIn = false.obs;
  
  // Getters
  User? get user => _user.value;
  bool get isLoggedIn => _isLoggedIn.value;
  
  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }
  
  /// Initialize authentication state - sederhana untuk MVP
  Future<void> _initializeAuth() async {
    final token = ApiService.getToken();
    
    debugPrint('🔐 AuthService init - Token: ${token?.substring(0, 20)}...');
    debugPrint('🔐 AuthService init - Token length: ${token?.length}');
    
    if (token != null && token.isNotEmpty) {
      // Coba ambil data user dari storage
      final userData = _storage.read('user_data');
      
      debugPrint('👤 User data from storage: ${userData != null ? "Found" : "Not found"}');
      
      if (userData != null) {
        try {
          _user.value = User.fromJson(userData);
          _isLoggedIn.value = true;
          debugPrint('✅ Auth initialized successfully');
        } catch (e) {
          debugPrint('❌ Error parsing user data: $e');
          // Data user rusak, hapus semua
          await _clearUserData();
        }
      } else {
        debugPrint('⚠️ Token exists but no user data found');
      }
    } else {
      debugPrint('❌ No token found');
    }
  }
  

  
  /// Login user
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      
      if (response.statusCode == 200) {
        final data = response.body['data'];
        final token = data['token'];
        final userData = data['user'];
        
        // Save token
         ApiService.storeToken(token);
        
        // Save user data
        _user.value = User.fromJson(userData);
        _isLoggedIn.value = true;
        await _storage.write('user_data', userData);
        
        return AuthResult.success('Login berhasil');
      } else {
        final message = response.body['message'] ?? 'Login gagal';
        return AuthResult.error(message);
      }
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan: ${e.toString()}');
    }
  }
  
  /// Logout user - sederhana untuk MVP
  Future<void> logout() async {
    try {
      // Panggil API logout (opsional, lanjut meski gagal)
      await _apiService.logout();
    } catch (e) {
      // Lanjut meski API gagal
    }
    
    // Hapus semua data tersimpan
    await _clearUserData();
    
    // Kembali ke halaman login
    Get.offAllNamed(Routes.LOGIN);
    
    // Tampilkan pesan sukses
    Get.snackbar(
      'Logout Berhasil',
      'Anda telah keluar dari aplikasi',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
    );
  }
  

  
  /// Update user data setelah profile diubah
  void updateUserData(User updatedUser) {
    // Debug logging
    debugPrint('🔄 AuthService: Updating user data - Nama: ${updatedUser.nama}, Email: ${updatedUser.email}');
    
    _user.value = updatedUser;
    _storage.write('user_data', updatedUser.toJson());
    
    // Debug: Verify data was saved
    final savedData = _storage.read('user_data');
    debugPrint('💾 AuthService: Data saved to storage: $savedData');
    debugPrint('👤 AuthService: Current _user.value - Nama: ${_user.value?.nama}, Email: ${_user.value?.email}');
  }
  
  /// Clear all user data
  Future<void> _clearUserData() async {
    ApiService.clearToken();
    await _storage.remove('user_data');
    _setLoggedOut();
  }
  
  /// Set state as logged out
  void _setLoggedOut() {
    _isLoggedIn.value = false;
    _user.value = null;
  }
  
  /// Check if user is authenticated - sederhana untuk MVP
  Future<bool> isAuthenticated() async {
    final token = ApiService.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Cek apakah user data ada dan login status true
    return _user.value != null && _isLoggedIn.value;
  }
  
  /// Auto-login when app starts
  Future<void> tryAutoLogin() async {
    await _initializeAuth();
  }
  
  /// Handle session expired - sederhana untuk MVP
  void handleSessionExpired() {
    Get.snackbar(
      'Session Expired',
      'Sesi anda telah berakhir, silakan login kembali',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
    );
    
    // Langsung logout tanpa konfirmasi
    logout();
  }
}

/// Result class for login operation
class AuthResult {
  final bool isSuccess;
  final String message;
  
  AuthResult._(this.isSuccess, this.message);
  
  factory AuthResult.success(String message) {
    return AuthResult._(true, message);
  }
  
  factory AuthResult.error(String message) {
    return AuthResult._(false, message);
  }
}