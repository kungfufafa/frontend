import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/core/utils/standard_form_validation.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/modules/tikets/controllers/tikets_controller.dart';
import 'package:frontend/app/routes/app_pages.dart';

class CreateTiketController extends BaseController {
  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController judulController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  // Observable states
  final RxString selectedPriority = 'sedang'.obs;
  
  @override
  void onClose() {
    judulController.dispose();
    deskripsiController.dispose();
    super.onClose();
  }
  
  @override
  bool validateForm() {
    return _validateForm();
  }

  @override
  Future<void> refreshData() async {
    // Refresh tikets list if controller exists
    if (Get.isRegistered<TiketsController>()) {
      final tiketsController = Get.find<TiketsController>();
      await tiketsController.loadTikets(refresh: true);
    }
  }

  @override
  void navigateToListPage() {
    Get.offNamed(Routes.TIKETS); // Navigate to tikets list
  }
  
  Future<void> createTiket() async {
    await performCreateOperation(
      createFunction: () => _createTiketData(),
      successMessage: 'Tiket berhasil dibuat',
      loadingMessage: 'Membuat tiket...',
    );
  }

  Future<void> _createTiketData() async {
    final request = CreateTiketRequest(
      judul: judulController.text.trim(),
      deskripsi: deskripsiController.text.trim(),
      prioritas: selectedPriority.value,
    );
    
    debugPrint('📝 Creating ticket with data: ${request.toJson()}');
    
    final response = await apiService.createTiket(request);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      _clearForm();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  String _extractErrorMessage(Response response) {
    String errorMessage = 'Gagal membuat tiket';
    
    if (response.body != null && response.body is Map) {
      final bodyMap = response.body as Map;
      
      if (bodyMap.containsKey('message') && bodyMap['message'] != null) {
        errorMessage = bodyMap['message'].toString();
      }
      
      // Check for validation errors (status 422)
      if (response.statusCode == 422 && bodyMap.containsKey('errors')) {
        final errors = bodyMap['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          } else if (firstError is String) {
            errorMessage = firstError;
          }
        }
      }
    }
    
    return errorMessage;
  }

  void _clearForm() {
    judulController.clear();
    deskripsiController.clear();
    selectedPriority.value = 'sedang';
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) return false;
    
    final judulError = StandardFormValidation.validateRequired(judulController.text, 'Judul');
    if (judulError != null) {
      AppSnackbar.error(judulError);
      return false;
    }

    final deskripsiError = StandardFormValidation.validateRequired(deskripsiController.text, 'Deskripsi');
    if (deskripsiError != null) {
      AppSnackbar.error(deskripsiError);
      return false;
    }

    return true;
  }
}
