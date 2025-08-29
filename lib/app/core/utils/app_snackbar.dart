import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utility class untuk menampilkan snackbar yang konsisten di seluruh aplikasi
/// Menggunakan prinsip KISS dengan API yang sederhana dan mudah digunakan
class AppSnackbar {
  // Private constructor untuk mencegah instantiation
  AppSnackbar._();
  
  /// Menampilkan snackbar sukses dengan tema hijau
  static void success(String message) {
    Get.snackbar(
      'Berhasil',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Menampilkan snackbar error dengan tema merah
  static void error(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Menampilkan snackbar warning dengan tema orange
  static void warning(String message) {
    Get.snackbar(
      'Peringatan',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
      icon: const Icon(Icons.warning, color: Colors.orange),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Menampilkan snackbar info dengan tema biru
  static void info(String message) {
    Get.snackbar(
      'Informasi',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue[100],
      colorText: Colors.blue[800],
      icon: const Icon(Icons.info, color: Colors.blue),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Menampilkan snackbar loading dengan progress indicator
  static void loading(String message) {
    Get.snackbar(
      'Loading',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey[100],
      colorText: Colors.grey[800],
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      showProgressIndicator: true,
      isDismissible: false, // Loading tidak bisa di-dismiss
    );
  }
  
  /// Menampilkan snackbar custom dengan konfigurasi lengkap
  static void custom({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Widget? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.BOTTOM,
    bool isDismissible = true,
    bool showProgressIndicator = false,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor ?? Colors.grey[100],
      colorText: textColor ?? Colors.grey[800],
      icon: icon,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: isDismissible,
      showProgressIndicator: showProgressIndicator,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Menampilkan snackbar untuk operasi CRUD yang berhasil
  static void operationSuccess({
    required String operation,
    required String itemType,
    String? itemName,
  }) {
    final message = itemName != null 
        ? '$itemType "$itemName" berhasil $operation'
        : '$itemType berhasil $operation';
    success(message);
  }
  
  /// Menampilkan snackbar untuk operasi CRUD yang gagal
  static void operationError({
    required String operation,
    required String itemType,
    String? errorMessage,
  }) {
    final message = errorMessage ?? 'Gagal $operation $itemType';
    error(message);
  }
  
  /// Menampilkan snackbar loading untuk operasi CRUD
  static void operationLoading({
    required String operation,
    required String itemType,
  }) {
    final loadingMessages = {
      'create': 'Menyimpan',
      'update': 'Memperbarui', 
      'delete': 'Menghapus',
      'save': 'Menyimpan',
      'edit': 'Memperbarui',
      'remove': 'Menghapus',
    };
    
    final verb = loadingMessages[operation.toLowerCase()] ?? 'Memproses';
    loading('$verb $itemType...');
  }
  
  /// Helper methods untuk operasi CRUD umum
  static void createSuccess(String itemType, [String? itemName]) {
    operationSuccess(operation: 'dibuat', itemType: itemType, itemName: itemName);
  }
  
  static void updateSuccess(String itemType, [String? itemName]) {
    operationSuccess(operation: 'diperbarui', itemType: itemType, itemName: itemName);
  }
  
  static void deleteSuccess(String itemType, [String? itemName]) {
    operationSuccess(operation: 'dihapus', itemType: itemType, itemName: itemName);
  }
  
  static void createError(String itemType, [String? errorMessage]) {
    operationError(operation: 'membuat', itemType: itemType, errorMessage: errorMessage);
  }
  
  static void updateError(String itemType, [String? errorMessage]) {
    operationError(operation: 'memperbarui', itemType: itemType, errorMessage: errorMessage);
  }
  
  static void deleteError(String itemType, [String? errorMessage]) {
    operationError(operation: 'menghapus', itemType: itemType, errorMessage: errorMessage);
  }
  
  static void createLoading(String itemType) {
    operationLoading(operation: 'create', itemType: itemType);
  }
  
  static void updateLoading(String itemType) {
    operationLoading(operation: 'update', itemType: itemType);
  }
  
  static void deleteLoading(String itemType) {
    operationLoading(operation: 'delete', itemType: itemType);
  }
}