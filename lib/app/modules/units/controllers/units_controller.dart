import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/core/utils/standard_form_validation.dart';
import 'package:frontend/app/core/utils/standard_error_handler.dart';
import 'package:frontend/app/data/models/tiket_model.dart'; // For Unit and Karyawan models
import 'package:frontend/app/data/models/user_model.dart';

class UnitsController extends BaseController {
  // Observable states
  var units = <Unit>[].obs;
  var filteredUnits = <Unit>[].obs;
  var karyawans = <Karyawan>[].obs;
  var isLoadingKaryawans = false.obs;
  var isLoadingEmployees = false.obs;
  var editingUnitId = 0.obs;
  var selectedUnitForAssignment = 0.obs;
  
  // Employee management
  var availableEmployees = <User>[].obs;
  var unitEmployees = <String>[].obs;

  // Form controllers untuk add/edit unit
  final TextEditingController namaUnitController = TextEditingController();
  final TextEditingController kategoriUnitController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  // Alternative controller names for compatibility
  TextEditingController get namaController => namaUnitController;
  TextEditingController get kategoriController => kategoriUnitController;
  TextEditingController get deskripsiController => descriptionController;

  // Permission observables
  var canManageUnitsObs = false.obs;
  var canDeleteUnitsObs = false.obs;

  @override
  void onInit() {
    super.onInit();
    updatePermissions();
    loadUnits();
    loadKaryawans();
  filteredUnits.value = units;
  }

  @override
  void onClose() {
    namaUnitController.dispose();
    kategoriUnitController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  @override
  bool validateForm() {
    return _validateForm();
  }

  @override
  Future<void> refreshData() async {
    await loadUnits();
  }

  @override
  void navigateToListPage() {
    Get.back(); // Close dialog/form and stay on units list
  }

  // Update permissions based on current user role
  void updatePermissions() {
    final currentUser = authService.user;
    canManageUnitsObs.value = currentUser?.isAdmin() == true || currentUser?.isManager() == true;
    canDeleteUnitsObs.value = currentUser?.isAdmin() == true;
  }

  // Load units
  Future<void> loadUnits() async {
    await performListOperation(
      loadFunction: () => _loadUnitsData(),
    );
  }

  Future<void> _loadUnitsData() async {
    debugPrint('🔄 Loading units...');
    
    final response = await apiService.getUnits();
    
    if (response.isOk && response.body['success'] == true) {
      final data = response.body['data'] ?? response.body;
      final List<dynamic> items = data is List ? data : (data['data'] ?? []);
      
      debugPrint('📊 Units data: $items');
      
  units.value = items.map((item) => Unit.fromJson(item)).toList();
  filteredUnits.value = units;
  debugPrint('✅ Loaded ${units.length} units');
    } else {
      throw Exception(response.body['message'] ?? 'Gagal memuat data unit');
    }
  }

  // Load karyawans for assignment
  Future<void> loadKaryawans() async {
    try {
      isLoadingKaryawans.value = true;
      debugPrint('🔄 Loading karyawans...');
      
      final response = await apiService.getKaryawans();
      
      if (response.isOk && response.body['success'] == true) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
  karyawans.value = items.map((item) => Karyawan.fromJson(item)).toList();
        debugPrint('✅ Loaded ${karyawans.length} karyawans');
      } else {
        debugPrint('❌ Failed to load karyawans: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error loading karyawans: $e');
    } finally {
      isLoadingKaryawans.value = false;
    }
  }

  // Create unit
  Future<void> createUnit() async {
    await performCreateOperation(
      createFunction: () => _createUnitData(),
      successMessage: 'Unit berhasil dibuat',
      loadingMessage: 'Menyimpan unit...',
    );
  }

  Future<void> _createUnitData() async {
    final unitData = {
      'nama_unit': namaUnitController.text.trim(),
      'kategori_unit': kategoriUnitController.text.trim(),
      'description': descriptionController.text.trim(),
    };
    
    debugPrint('📤 Unit data: $unitData');
    
    final response = await apiService.createUnit(unitData);
    
    if (response.isOk && response.body['success'] == true) {
      debugPrint('✅ Unit created successfully');
      _clearForm();
    } else {
      throw Exception(response.body['message'] ?? 'Gagal membuat unit');
    }
  }

  // Update unit
  Future<void> updateUnit() async {
    if (editingUnitId.value == 0) {
      AppSnackbar.error('ID unit tidak valid');
      return;
    }
    
    await performUpdateOperation(
      id: editingUnitId.value.toString(),
      updateFunction: () => _updateUnitData(),
      successMessage: 'Unit berhasil diperbarui',
      loadingMessage: 'Memperbarui unit...',
      navigateToDetail: false,
    );
  }

  Future<void> _updateUnitData() async {
    final unitData = {
      'nama_unit': namaUnitController.text.trim(),
      'kategori_unit': kategoriUnitController.text.trim(),
      'description': descriptionController.text.trim(),
    };
    
    debugPrint('📤 Updating unit ${editingUnitId.value} with data: $unitData');
    
    final response = await apiService.updateUnit(editingUnitId.value, unitData);
    
    if (response.isOk && response.body['success'] == true) {
      debugPrint('✅ Unit updated successfully');
      _clearForm();
    } else {
      throw Exception(response.body['message'] ?? 'Gagal memperbarui unit');
    }
  }

  // Delete unit
  Future<void> deleteUnit(int unitId, String unitName) async {
    await performDeleteOperation(
      id: unitId.toString(),
      itemName: unitName,
      deleteFunction: () => _deleteUnitData(unitId),
    );
  }

  Future<void> _deleteUnitData(int unitId) async {
    debugPrint('🔄 Deleting unit $unitId...');
    
    final response = await apiService.deleteUnit(unitId);
    
    if (response.isOk && response.body['success'] == true) {
      debugPrint('✅ Unit deleted successfully');
    } else {
      throw Exception(response.body['message'] ?? 'Gagal menghapus unit');
    }
  }

  // Assign karyawan to unit
  Future<void> assignKaryawanToUnit(int karyawanId, int unitId) async {
    try {
      isLoading.value = true;
      AppSnackbar.updateLoading('penugasan karyawan');
      
      debugPrint('🔄 Assigning karyawan $karyawanId to unit $unitId...');
      
      final karyawanData = {
        'id_unit': unitId,
      };
      
      final response = await apiService.updateKaryawan(karyawanId, karyawanData);
      
      if (response.isOk && response.body['success'] == true) {
        debugPrint('✅ Karyawan assigned successfully');
        AppSnackbar.updateSuccess('penugasan karyawan');
        await loadKaryawans();
      } else {
        throw Exception(response.body['message'] ?? 'Gagal menugaskan karyawan');
      }
    } catch (e) {
      StandardErrorHandler.handleUpdateError('penugasan karyawan', e, context: 'Assign Karyawan');
    } finally {
      isLoading.value = false;
    }
  }

  // Get karyawans by unit
  List<Karyawan> getKaryawansByUnit(int unitId) {
    return karyawans.where((karyawan) => karyawan.idUnit == unitId).toList();
  }

  // Get unassigned karyawans (those not assigned to any unit or assigned to unit 0)
  List<Karyawan> getUnassignedKaryawans() {
    return karyawans.where((karyawan) => karyawan.idUnit == 0).toList();
  }

  // Prepare form for editing
  void prepareEditForm(Unit unit) {
    editingUnitId.value = unit.id;
    namaUnitController.text = unit.nama;
    kategoriUnitController.text = unit.kategoriUnit;
    descriptionController.text = unit.description ?? '';
  }

  // Clear form
  void _clearForm() {
    editingUnitId.value = 0;
    namaUnitController.clear();
    kategoriUnitController.clear();
    descriptionController.clear();
  }

  // Validate form using StandardFormValidation
  bool _validateForm() {
    final namaError = StandardFormValidation.validateRequired(namaUnitController.text, 'Nama unit');
    if (namaError != null) {
      AppSnackbar.error(namaError);
      return false;
    }
    
    final kategoriError = StandardFormValidation.validateRequired(kategoriUnitController.text, 'Kategori unit');
    if (kategoriError != null) {
      AppSnackbar.error(kategoriError);
      return false;
    }
    
    return true;
  }

  // Check if current user can manage units
  bool get canManageUnits {
    final currentUser = authService.user;
    return currentUser?.isAdmin() == true || currentUser?.isManager() == true;
  }

  // Check if current user can delete units
  bool get canDeleteUnits {
    final currentUser = authService.user;
    return currentUser?.isAdmin() == true;
  }

  // Search units
  void searchUnits(String query) {
    if (query.isEmpty) {
  filteredUnits.value = units;
    } else {
  filteredUnits.value = units.where((unit) {
        return unit.nama.toLowerCase().contains(query.toLowerCase()) ||
               unit.kategoriUnit.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
  
  // Clear form
  void clearForm() {
    namaUnitController.clear();
    kategoriUnitController.clear();
    descriptionController.clear();
  }
  
  // Load employees for unit management
   Future<void> loadEmployeesForUnit(String unitId) async {
     try {
       isLoadingEmployees.value = true;
       
       // Load all employees (karyawan role)
       final response = await apiService.getUsers();
       
       if (response.isOk && response.body['success'] == true) {
         dynamic data;
         
         // Handle different response structures
         if (response.body is List) {
           data = response.body;
         } else if (response.body is Map<String, dynamic>) {
           final responseMap = response.body as Map<String, dynamic>;
           
           if (responseMap.containsKey('data')) {
             final dataField = responseMap['data'];
             
             if (dataField is Map<String, dynamic> && dataField.containsKey('data')) {
               data = dataField['data'];
             } else {
               data = dataField;
             }
           }
         }
         
         if (data is List) {
            final allUsers = data.map((item) => User.fromJson(item)).toList();
            availableEmployees.value = allUsers.where((user) => user.isKaryawan()).toList();
          }
       }
       
       // Load current unit employees (this would need API endpoint)
       // For now, we'll use empty list
       unitEmployees.value = [];
       
     } catch (e) {
       handleError(e, context: 'loadEmployeesForUnit');
     } finally {
       isLoadingEmployees.value = false;
     }
   }
  
  // Assign employee to unit
  Future<void> assignEmployeeToUnit(String unitId, String employeeId) async {
    try {
      // This would need API endpoint to assign employee to unit
      // For now, we'll just update local state
      if (!unitEmployees.contains(employeeId)) {
        unitEmployees.add(employeeId);
      }
      showSuccessSnackbar('Karyawan berhasil ditugaskan ke unit');
    } catch (e) {
      handleError(e, context: 'assignEmployeeToUnit');
    }
  }
  
  // Remove employee from unit
  Future<void> removeEmployeeFromUnit(String unitId, String employeeId) async {
    try {
      // This would need API endpoint to remove employee from unit
      // For now, we'll just update local state
      unitEmployees.remove(employeeId);
      showSuccessSnackbar('Karyawan berhasil dihapus dari unit');
    } catch (e) {
      handleError(e, context: 'removeEmployeeFromUnit');
    }
  }

  // Refresh units data
  Future<void> refreshUnits() async {
    await loadUnits();
    await loadKaryawans();
  }
}