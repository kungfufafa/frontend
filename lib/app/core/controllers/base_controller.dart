import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';

/// Base controller yang menyediakan standarisasi untuk semua controller
/// dengan implementasi KISS (Keep It Simple, Stupid) principles
abstract class BaseController extends GetxController {
  // Dependency injection
  late final ApiService apiService;
  late final AuthService authService;
  
  // Standard loading states
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Initialize dependencies
    apiService = Get.find<ApiService>();
    authService = Get.find<AuthService>();
  }
  
  /// Menampilkan snackbar sukses dengan style yang konsisten
  void showSuccessSnackbar(String message) {
    AppSnackbar.success(message);
  }
  
  /// Menampilkan snackbar error dengan style yang konsisten
  void showErrorSnackbar(String message) {
    AppSnackbar.error(message);
  }
  
  /// Menampilkan snackbar loading dengan style yang konsisten
  void showLoadingSnackbar(String message) {
    AppSnackbar.loading(message);
  }
  
  /// Menampilkan snackbar warning dengan style yang konsisten
  void showWarningSnackbar(String message) {
    AppSnackbar.warning(message);
  }
  
  /// Menampilkan snackbar info dengan style yang konsisten
  void showInfoSnackbar(String message) {
    AppSnackbar.info(message);
  }
  
  /// Menampilkan dialog konfirmasi untuk operasi delete
  Future<bool> showConfirmationDialog(String title, String message) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  /// Standardized error handler untuk berbagai jenis error
  void handleError(dynamic error, {String? context}) {
    String message = 'Terjadi kesalahan';
    
    if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else if (error.toString().contains('DioError') || error.toString().contains('HTTP')) {
      message = 'Terjadi kesalahan koneksi';
    } else {
      message = error.toString();
    }
    
    // Log error untuk debugging
    debugPrint('❌ Error in ${context ?? runtimeType}: $error');
    showErrorSnackbar(message);
  }
  
  /// Validasi form yang wajib diimplementasi oleh child controller
  bool validateForm() {
    // Default implementation - override in child controllers
    return true;
  }
  
  /// Refresh data yang wajib diimplementasi oleh child controller untuk operasi CRUD
  Future<void> refreshData() async {
    // Default implementation - override in child controllers
  }
  
  /// Navigasi ke halaman list setelah operasi create/delete berhasil
  void navigateToListPage() {
    // Override in child controllers dengan route yang sesuai
    Get.back();
  }
  
  /// Navigasi ke halaman detail setelah operasi update berhasil
  void navigateToDetailPage(String id) {
    // Override in child controllers dengan route yang sesuai
    Get.back();
  }
  
  /// Standard create operation pattern
  Future<void> performCreateOperation({
    required Future<dynamic> Function() createFunction,
    required String successMessage,
    String? loadingMessage,
    bool navigateToList = true,
  }) async {
    if (!validateForm()) return;
    
    try {
      isSubmitting.value = true;
      
      if (loadingMessage != null) {
        showLoadingSnackbar(loadingMessage);
      }
      
      await createFunction();
      
      showSuccessSnackbar(successMessage);
      await refreshData();
      
      if (navigateToList) {
        navigateToListPage();
      }
    } catch (e) {
      handleError(e, context: 'Create Operation');
    } finally {
      isSubmitting.value = false;
    }
  }
  
  /// Standard update operation pattern
  Future<void> performUpdateOperation({
    required String id,
    required Future<dynamic> Function() updateFunction,
    required String successMessage,
    String? loadingMessage,
    bool navigateToDetail = true,
  }) async {
    if (!validateForm()) return;
    
    try {
      isSubmitting.value = true;
      
      if (loadingMessage != null) {
        showLoadingSnackbar(loadingMessage);
      }
      
      await updateFunction();
      
      showSuccessSnackbar(successMessage);
      await refreshData();
      
      if (navigateToDetail) {
        navigateToDetailPage(id);
      }
    } catch (e) {
      handleError(e, context: 'Update Operation');
    } finally {
      isSubmitting.value = false;
    }
  }
  
  /// Standard delete operation pattern
  Future<void> performDeleteOperation({
    required String id,
    required String itemName,
    required Future<dynamic> Function() deleteFunction,
    String? confirmTitle,
    String? confirmMessage,
  }) async {
    final title = confirmTitle ?? 'Hapus Data';
    final message = confirmMessage ?? 'Apakah Anda yakin ingin menghapus "$itemName"?';
    
    final confirmed = await showConfirmationDialog(title, message);
    if (!confirmed) return;
    
    try {
      isLoading.value = true;
      showLoadingSnackbar('Menghapus data...');
      
      await deleteFunction();
      
      showSuccessSnackbar('Data berhasil dihapus');
      await refreshData();
    } catch (e) {
      handleError(e, context: 'Delete Operation');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Standard list loading with pagination
  Future<void> performListOperation({
    required Future<dynamic> Function() loadFunction,
    bool refresh = false,
    bool loadMore = false,
  }) async {
    try {
      if (refresh) {
        isLoading.value = true;
      } else if (loadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }
      
      await loadFunction();
    } catch (e) {
      handleError(e, context: 'List Operation');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}