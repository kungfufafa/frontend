import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/modules/tikets/controllers/tikets_controller.dart';

class CreateTiketController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController judulController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  // Observable states
  final RxString selectedPriority = 'sedang'.obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onClose() {
    judulController.dispose();
    deskripsiController.dispose();
    super.onClose();
  }
  
  Future<void> createTiket() async {
    if (!formKey.currentState!.validate()) return;
    
    try {
      isLoading.value = true;
      
      final request = CreateTiketRequest(
        judul: judulController.text.trim(),
        deskripsi: deskripsiController.text.trim(),
        prioritas: selectedPriority.value,
      );
      
      // Log the request data for debugging
      ApiService.logDebug('Creating ticket with data: ${request.toJson()}', context: 'CreateTiketController');
      
      final response = await apiService.createTiket(request);
      
      // Log the response for debugging
      ApiService.logDebug('Create ticket response status: ${response.statusCode}', context: 'CreateTiketController');
      ApiService.logDebug('Create ticket response body type: ${response.body.runtimeType}', context: 'CreateTiketController');
      ApiService.logDebug('Create ticket response body: ${response.body}', context: 'CreateTiketController');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Check if response body has the expected structure
        String successMessage = 'Tiket berhasil dibuat';
        
        if (response.body != null && response.body is Map) {
          final bodyMap = response.body as Map;
          
          // Get the success message from backend if available
          if (bodyMap.containsKey('message') && bodyMap['message'] != null) {
            // Safely convert message to string
            successMessage = bodyMap['message'].toString();
          }
          
          // Check if the response indicates success
          final isSuccess = bodyMap['success'] ?? true;
          
          if (!isSuccess) {
            // Handle case where status is 200/201 but success is false
            throw Exception(successMessage);
          }
        }
        
        Get.snackbar(
          'Berhasil',
          successMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
        
        // Clear form
        judulController.clear();
        deskripsiController.clear();
        selectedPriority.value = 'sedang';
        
        // Refresh tikets list if controller exists
        if (Get.isRegistered<TiketsController>()) {
          final tiketsController = Get.find<TiketsController>();
          await tiketsController.loadTikets(refresh: true);
        }
        
        // Navigate back to tikets list
        Get.back(); // Go back from create page
        // Let the TiketsView handle showing the updated list
      } else {
        // Safely extract error message from response
        String errorMessage = 'Gagal membuat tiket';
        Map<String, dynamic>? errors;
        
        if (response.body != null) {
          // Check if body is a Map and has message field
          if (response.body is Map) {
            final bodyMap = response.body as Map;
            
            // Handle message field regardless of its type
            if (bodyMap.containsKey('message')) {
              final messageField = bodyMap['message'];
              // Convert to string safely
              errorMessage = messageField?.toString() ?? errorMessage;
            } else if (bodyMap.containsKey('error')) {
              // Alternative error field
              errorMessage = bodyMap['error']?.toString() ?? errorMessage;
            }
            
            // Check for validation errors (status 422)
            if (response.statusCode == 422 && bodyMap.containsKey('errors')) {
              errors = bodyMap['errors'] as Map<String, dynamic>?;
              if (errors != null && errors.isNotEmpty) {
                // Get first error message
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  errorMessage = firstError.first.toString();
                } else if (firstError is String) {
                  errorMessage = firstError;
                }
              }
            }
          } else if (response.body is String) {
            // If body is directly a string
            errorMessage = response.body.toString();
          }
        }
        
        // Show specific error for common issues
        if (response.statusCode == 422) {
          errorMessage = 'Data tidak valid: $errorMessage';
        } else if (response.statusCode == 500) {
          errorMessage = 'Terjadi kesalahan server. Silakan coba lagi.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      // Better error handling for type errors
      String errorMessage = 'Terjadi kesalahan';
      
      if (e.toString().contains('type') && e.toString().contains('String') && e.toString().contains('int')) {
        // Handle type mismatch errors
        errorMessage = 'Format data tidak sesuai. Silakan coba lagi.';
        ApiService.logError('Type mismatch error: $e', context: 'CreateTiketController', stackTrace: e);
      } else {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        ApiService.logError('Failed to create tiket: $e', context: 'CreateTiketController', stackTrace: e);
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }
}
