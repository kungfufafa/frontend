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
  
  // Employee management - NEW CHECKLIST SYSTEM
  var availableEmployees = <User>[].obs;
  var unitEmployees = <String>[].obs;
  
  // Enhanced employee checklist system
  var allEmployeesForChecklist = <Karyawan>[].obs;
  var employeeChecklistStatus = <int, bool>{}.obs; // employeeId -> isAssignedToCurrentUnit
  var showOnlyUnassigned = false.obs;
  var currentManagingUnitId = 0.obs;

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
    canDeleteUnitsObs.value = currentUser?.isAdmin() == true || currentUser?.isManager() == true;
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
  
  // Get filtered employees for checklist display
  List<Karyawan> get filteredEmployeesForChecklist {
    if (showOnlyUnassigned.value) {
      return allEmployeesForChecklist.where((emp) => emp.idUnit == 0).toList();
    }
    return allEmployeesForChecklist;
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
    return currentUser?.isAdmin() == true || currentUser?.isManager() == true;
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
  
  // Load all karyawans with unit assignment status for checklist
  Future<void> loadAllKaryawansWithUnitStatus(int currentUnitId) async {
    try {
      isLoadingEmployees.value = true;
      currentManagingUnitId.value = currentUnitId;
      debugPrint('🔄 Loading all karyawans for unit assignment checklist...');
      
      // Load all employees
      final allEmployeesResponse = await apiService.getKaryawans();
      
      if (allEmployeesResponse.isOk && allEmployeesResponse.body['success'] == true) {
        final data = allEmployeesResponse.body['data'] ?? allEmployeesResponse.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
        final allKaryawans = items.map((item) => Karyawan.fromJson(item)).toList();
        
        // Create checklist status map
        final statusMap = <int, bool>{};
        for (final karyawan in allKaryawans) {
          statusMap[karyawan.id] = karyawan.idUnit == currentUnitId;
        }
        employeeChecklistStatus.value = statusMap;
        
        // Store all employees for display
        allEmployeesForChecklist.value = allKaryawans;
        
        debugPrint('✅ Loaded ${allKaryawans.length} karyawans for checklist');
        debugPrint('📋 Checklist status: ${employeeChecklistStatus.length} entries');
      } else {
        debugPrint('❌ Failed to load karyawans: ${allEmployeesResponse.body}');
        throw Exception(allEmployeesResponse.body['message'] ?? 'Gagal memuat data karyawan');
      }
    } catch (e) {
      handleError(e, context: 'loadAllKaryawansWithUnitStatus');
    } finally {
      isLoadingEmployees.value = false;
    }
  }
  
  // Toggle employee unit assignment (checklist functionality)
  Future<void> toggleEmployeeUnitAssignment(int karyawanId, int unitId, bool shouldAssign) async {
    try {
      debugPrint('🔄 Toggling employee $karyawanId assignment to unit $unitId: $shouldAssign');
      
      // Optimistic update for immediate UI feedback
      employeeChecklistStatus[karyawanId] = shouldAssign;
      
      final transferData = {
        'id_unit': shouldAssign ? unitId : 0 // 0 means unassigned
      };
      
      final response = await apiService.updateKaryawan(karyawanId, transferData);
      
      if (response.isOk && response.body['success'] == true) {
        // Update employee data in local list
        final employeeIndex = allEmployeesForChecklist.indexWhere(
          (emp) => emp.id == karyawanId
        );
        
        if (employeeIndex != -1) {
          final updatedEmployee = Karyawan(
            id: allEmployeesForChecklist[employeeIndex].id,
            idUser: allEmployeesForChecklist[employeeIndex].idUser,
            idUnit: shouldAssign ? unitId : 0,
            nama: allEmployeesForChecklist[employeeIndex].nama,
            nik: allEmployeesForChecklist[employeeIndex].nik,
            tanggalLahir: allEmployeesForChecklist[employeeIndex].tanggalLahir,
            jenisKelamin: allEmployeesForChecklist[employeeIndex].jenisKelamin,
            nomorTelepon: allEmployeesForChecklist[employeeIndex].nomorTelepon,
            alamat: allEmployeesForChecklist[employeeIndex].alamat,
            createdAt: allEmployeesForChecklist[employeeIndex].createdAt,
            updatedAt: DateTime.now(),
            user: allEmployeesForChecklist[employeeIndex].user,
            unit: shouldAssign ? units.where((u) => u.id == unitId).isNotEmpty ? units.where((u) => u.id == unitId).first : null : null,
          );
          allEmployeesForChecklist[employeeIndex] = updatedEmployee;
        }
        
        showSuccessSnackbar(shouldAssign 
          ? 'Karyawan berhasil ditugaskan ke unit'
          : 'Karyawan berhasil dikeluarkan dari unit');
          
        // Refresh global karyawan list
        await loadKaryawans();
        
        debugPrint('✅ Employee assignment updated successfully');
      } else {
        // Revert optimistic update on failure
        employeeChecklistStatus[karyawanId] = !shouldAssign;
        debugPrint('❌ API error: ${response.body}');
        throw Exception(response.body['message'] ?? 'Gagal mengubah penugasan');
      }
    } catch (e) {
      // Revert optimistic update on error
      employeeChecklistStatus[karyawanId] = !shouldAssign;
      StandardErrorHandler.handleUpdateError('penugasan karyawan', e);
    }
  }
  
  // Transfer employee to specific unit (enhanced method)
  Future<void> transferEmployeeToUnit(int karyawanId, int targetUnitId) async {
    try {
      isLoading.value = true;
      showLoadingSnackbar('transfer karyawan');
      
      debugPrint('🔄 Transferring employee $karyawanId to unit $targetUnitId...');
      
      final transferData = {'id_unit': targetUnitId};
      
      final response = await apiService.updateKaryawan(karyawanId, transferData);
      
      if (response.isOk && response.body['success'] == true) {
        showSuccessSnackbar('Karyawan berhasil dipindahkan ke unit');
        
        // Refresh both source and target unit data
        await refreshUnitsData();
        
        // Auto-refresh current dialog if open
        if (currentManagingUnitId.value > 0) {
          await loadAllKaryawansWithUnitStatus(currentManagingUnitId.value);
        }
        
        debugPrint('✅ Employee transfer completed successfully');
      } else {
        debugPrint('❌ Transfer failed: ${response.body}');
        throw Exception(response.body['message'] ?? 'Transfer gagal');
      }
    } catch (e) {
      StandardErrorHandler.handleUpdateError('transfer karyawan', e);
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh units data
  Future<void> refreshUnits() async {
    await loadUnits();
    await loadKaryawans();
  }
  
  // Refresh units data (enhanced method)
  Future<void> refreshUnitsData() async {
    await loadUnits();
    await loadKaryawans();
  }
}