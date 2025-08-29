import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/core/utils/app_snackbar.dart';
import 'package:frontend/app/core/utils/standard_form_validation.dart';
import 'package:frontend/app/core/utils/standard_error_handler.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart'; // For Karyawan model

class UsersController extends BaseController {
  // Observable states
  var users = <User>[].obs;
  var karyawanMap = <int, Karyawan>{}.obs; // Map user ID to Karyawan data
  var isLoadingKaryawan = false.obs;
  var hasMoreData = true.obs;
  var currentPage = 1.obs;
  var totalUsers = 0.obs;
  var searchQuery = ''.obs;
  var selectedRole = 0.obs; // 0 = All roles
  var isActiveFilter = true.obs;

  // Form controllers untuk add/edit user
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var selectedRoleId = 5.obs; // Default ke User/Klien
  var isActiveStatus = true.obs;
  var editingUserId = 0.obs;
  
  // Karyawan form controllers
  final TextEditingController nikController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController jenisKelaminController = TextEditingController();
  final TextEditingController nomorTeleponController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  var selectedUnitId = 0.obs;
  var editingKaryawanId = 0.obs;
  var isKaryawanRole = false.obs;

  // Permission observables
  var canManageUsersObs = false.obs;
  var canDeleteUsersObs = false.obs;

  // Available roles
  var roles = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Administrator'},
    {'id': 2, 'name': 'Manager'},
    {'id': 3, 'name': 'Karyawan'},
    {'id': 4, 'name': 'Direksi'},
    {'id': 5, 'name': 'User/Klien'},
  ].obs;

  @override
  void onInit() {
    super.onInit();
    updatePermissions();
    loadUsers();
    loadUnits(); // Load units for karyawan form
  }

  @override
  void onClose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nikController.dispose();
    tanggalLahirController.dispose();
    jenisKelaminController.dispose();
    nomorTeleponController.dispose();
    alamatController.dispose();
    super.onClose();
  }

  @override
  bool validateForm() {
    return _validateForm();
  }

  @override
  Future<void> refreshData() async {
    await loadUsers(refresh: true);
  }

  @override
  void navigateToListPage() {
    Get.back(); // Close dialog/form and stay on users list
  }

  @override
  void navigateToDetailPage(String id) {
    Get.back(); // Close dialog/form and stay on users list
  }

  // Load users dengan pagination
  Future<void> loadUsers({bool refresh = false}) async {
    await performListOperation(
      loadFunction: () => _loadUsersData(refresh: refresh),
      refresh: refresh,
    );
  }

  Future<void> _loadUsersData({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      hasMoreData.value = true;
      users.clear();
    }

    if (!hasMoreData.value && !refresh) return;

    // Build query parameters
    Map<String, String> queryParams = {
      'page': currentPage.value.toString(),
      'per_page': '15',
    };

    if (searchQuery.value.isNotEmpty) {
      queryParams['search'] = searchQuery.value;
    }

    if (selectedRole.value > 0) {
      queryParams['role_id'] = selectedRole.value.toString();
    }

    queryParams['is_active'] = isActiveFilter.value ? '1' : '0';

    debugPrint('🔍 Loading users with params: $queryParams');
    
    final response = await apiService.getUsers(query: queryParams);
    
    if (response.isOk && response.body['success'] == true) {
      _processUsersResponse(response.body, refresh);
    } else {
      throw Exception(response.body['message'] ?? 'Gagal memuat data users');
    }
  }

  void _processUsersResponse(dynamic responseBody, bool refresh) {
    dynamic data;
    
    if (responseBody is List) {
      data = responseBody;
    } else if (responseBody is Map<String, dynamic>) {
      final responseMap = responseBody;
      
      if (responseMap.containsKey('data')) {
        final dataField = responseMap['data'];
        
        if (dataField is Map<String, dynamic> && dataField.containsKey('data')) {
          // Nested structure
          data = dataField['data'];
          _updatePaginationInfo(dataField);
        } else {
          // Direct structure
          data = dataField;
          _updatePaginationInfo(responseMap);
        }
      }
    }
    
    if (data is! Iterable) {
      throw Exception('Invalid data format received from server');
    }
    
    final List<User> newUsers = [];
    for (var item in data) {
      try {
        final user = User.fromJson(item as Map<String, dynamic>);
        newUsers.add(user);
      } catch (e) {
        debugPrint('Error parsing user: $e');
        continue;
      }
    }
    
    if (refresh || currentPage.value == 1) {
      users.value = newUsers;
    } else {
      users.addAll(newUsers);
    }
    
    loadKaryawanDataForUsers(newUsers);
  }

  void _updatePaginationInfo(Map<String, dynamic> paginationData) {
    if (paginationData.containsKey('total')) {
      totalUsers.value = paginationData['total'] ?? 0;
    }
    
    if (paginationData.containsKey('current_page')) {
      currentPage.value = paginationData['current_page'] ?? 1;
    }
    
    if (paginationData.containsKey('last_page')) {
      final lastPage = paginationData['last_page'] ?? 1;
      hasMoreData.value = currentPage.value < lastPage;
    }
  }

  // Search users
  void searchUsers(String query) {
    searchQuery.value = query;
    loadUsers(refresh: true);
  }

  // Filter by role
  void filterByRole(int roleId) {
    debugPrint('🎯 Filtering by role: $roleId');
    selectedRole.value = roleId;
    loadUsers(refresh: true);
  }

  // Filter by active status
  void filterByActiveStatus(bool isActive) {
    debugPrint('🎯 Filtering by active status: $isActive');
    isActiveFilter.value = isActive;
    loadUsers(refresh: true);
  }

  // Clear form
  void clearForm() {
    namaController.clear();
    emailController.clear();
    passwordController.clear();
    selectedRoleId.value = 5;
    isActiveStatus.value = true;
    editingUserId.value = 0;
    
    // Clear karyawan form
    nikController.clear();
    tanggalLahirController.clear();
    jenisKelaminController.clear();
    nomorTeleponController.clear();
    alamatController.clear();
    selectedUnitId.value = 0;
    editingKaryawanId.value = 0;
    isKaryawanRole.value = false;
  }

  // Prepare form for editing
  void prepareEditForm(User user) async {
    editingUserId.value = user.id;
    namaController.text = user.nama;
    emailController.text = user.email;
    passwordController.clear(); // Password tidak diisi saat edit
    selectedRoleId.value = user.idRole ?? 5;
    isActiveStatus.value = user.isActive;
    isKaryawanRole.value = user.isKaryawan();
    
    // If user is karyawan, load karyawan data
    if (user.isKaryawan()) {
      final karyawan = karyawanMap[user.id];
      if (karyawan != null) {
        editingKaryawanId.value = karyawan.id;
  nikController.text = karyawan.nik;
  // Format tanggal lahir safely
  tanggalLahirController.text = karyawan.tanggalLahir.toIso8601String().split('T')[0];
  jenisKelaminController.text = karyawan.jenisKelamin;
  nomorTeleponController.text = karyawan.nomorTelepon;
        alamatController.text = karyawan.alamat;
  selectedUnitId.value = karyawan.idUnit;
      } else {
        // Load karyawan data if not in cache
        await loadKaryawanForUser(user.id);
      }
    }
  }

  // Create new user
  Future<void> createUser() async {
    await performCreateOperation(
      createFunction: () => _createUserData(),
      successMessage: 'User berhasil dibuat',
      loadingMessage: 'Menyimpan user...',
    );
  }

  Future<void> _createUserData() async {
    final body = {
      'nama': namaController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
      'password_confirmation': passwordController.text,
      'id_role': selectedRoleId.value,
      'isActive': isActiveStatus.value,
    };
    
    final response = await apiService.createUser(body);
    
    if (response.isOk && response.body['success'] == true) {
      final userId = response.body['data']?['id'] ?? 0;
      
      if (selectedRoleId.value == 3 && userId > 0) {
        await saveKaryawanData(userId);
      }
      
      clearForm();
    } else {
      throw Exception(response.body['message'] ?? 'Gagal membuat user');
    }
  }

  // Update user
  Future<void> updateUser() async {
    await performUpdateOperation(
      id: editingUserId.value.toString(),
      updateFunction: () => _updateUserData(),
      successMessage: 'User berhasil diperbarui',
      loadingMessage: 'Memperbarui user...',
      navigateToDetail: false, // Stay on users list
    );
  }

  Future<void> _updateUserData() async {
    final body = {
      'nama': namaController.text.trim(),
      'email': emailController.text.trim(),
      'id_role': selectedRoleId.value,
      'isActive': isActiveStatus.value,
    };

    if (passwordController.text.isNotEmpty) {
      body['password'] = passwordController.text;
      body['password_confirmation'] = passwordController.text;
    }

    final response = await apiService.updateUser(editingUserId.value, body);

    if (response.isOk && response.body['success'] == true) {
      if (selectedRoleId.value == 3) {
        await saveKaryawanData(editingUserId.value);
      }
      
      clearForm();
    } else {
      throw Exception(response.body['message'] ?? 'Gagal memperbarui user');
    }
  }

  // Delete user
  Future<void> deleteUser(int userId, String userName) async {
    await performDeleteOperation(
      id: userId.toString(),
      itemName: userName,
      deleteFunction: () => _deleteUserData(userId),
    );
  }

  Future<void> _deleteUserData(int userId) async {
    final response = await apiService.deleteUser(userId);
    
    if (response.isOk && response.body['success'] == true) {
      // Success handled by base controller
    } else {
      throw Exception(response.body['message'] ?? 'Gagal menghapus user');
    }
  }

  // Toggle user active status
  Future<void> toggleUserStatus(User user) async {
    try {
      isLoading.value = true;
      AppSnackbar.updateLoading('user');
      
      final newStatus = !user.isActive;
      
      final body = {
        'nama': user.nama,
        'email': user.email,
        'id_role': user.idRole,
        'isActive': newStatus,
      };
      
      final response = await apiService.updateUser(user.id, body);

      if (response.isOk && response.body['success'] == true) {
        AppSnackbar.updateSuccess('status user');
        await refreshData();
      } else {
        throw Exception(response.body['message'] ?? 'Gagal mengubah status user');
      }
    } catch (e) {
      StandardErrorHandler.handleUpdateError('status user', e, context: 'Toggle User Status');
    } finally {
      isLoading.value = false;
    }
  }

  // Form validation using StandardFormValidation
  bool _validateForm({bool isEdit = false}) {
    // Validate name
    final nameError = StandardFormValidation.validateRequired(namaController.text, 'Nama');
    if (nameError != null) {
      AppSnackbar.error(nameError);
      return false;
    }

    // Validate email
    final emailError = StandardFormValidation.validateEmail(emailController.text);
    if (emailError != null) {
      AppSnackbar.error(emailError);
      return false;
    }

    // Password validation for create user or edit with new password
    if (!isEdit || passwordController.text.isNotEmpty) {
      final passwordError = StandardFormValidation.validatePassword(passwordController.text);
      if (passwordError != null) {
        AppSnackbar.error(passwordError);
        return false;
      }
    }

    return true;
  }

  // Get role name by ID
  String getRoleName(int roleId) {
    final role = roles.firstWhere(
      (r) => r['id'] == roleId,
      orElse: () => {'name': 'Unknown'},
    );
    return role['name'];
  }

  // Check if current user can manage users
  bool get canManageUsers {
    final currentUser = authService.user;
    return currentUser?.isAdmin() == true || currentUser?.isManager() == true;
  }

  // Check if current user can delete users
  bool get canDeleteUsers {
    final currentUser = authService.user;
    return currentUser?.isAdmin() == true;
  }

  // Update permission observables
  void updatePermissions() {
    final currentUser = authService.user;
    canManageUsersObs.value = currentUser?.isAdmin() == true || currentUser?.isManager() == true;
    canDeleteUsersObs.value = currentUser?.isAdmin() == true;
  }

  // Check if user can be edited/deleted (prevent self-modification for critical actions)
  bool canModifyUser(User user) {
    final currentUser = authService.user;
    if (currentUser == null) return false;
    
    // Admin can modify anyone except themselves for critical actions
    if (currentUser.isAdmin()) {
      return user.id != currentUser.id;
    }
    
    // Manager can only modify users with lower roles
    if (currentUser.isManager()) {
      return user.idRole != null && user.idRole! > 2 && user.id != currentUser.id;
    }
    
    return false;
  }
  

  // Load karyawan data for users
  Future<void> loadKaryawanDataForUsers(List<User> userList) async {
    final karyawanUsers = userList.where((u) => u.isKaryawan()).toList();
    if (karyawanUsers.isEmpty) return;
    
    try {
      isLoadingKaryawan.value = true;
      
      final response = await apiService.getKaryawans();
      
      if (response.isOk) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
        for (var item in items) {
          try {
            final karyawan = Karyawan.fromJson(item);
            karyawanMap[karyawan.idUser] = karyawan;
                    } catch (e) {
            debugPrint('Error parsing karyawan: $e');
          }
        }
      }
    } catch (e) {
      StandardErrorHandler.handleLoadError('data karyawan', e, context: 'Load Karyawan Data');
    } finally {
      isLoadingKaryawan.value = false;
    }
  }
  
  // Load karyawan for specific user
  Future<void> loadKaryawanForUser(int userId) async {
    try {
      final response = await apiService.getKaryawans(
        query: {'user_id': userId.toString()},
      );
      
      if (response.isOk) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
        if (items.isNotEmpty) {
          final karyawan = Karyawan.fromJson(items.first);
          karyawanMap[userId] = karyawan;
          
          // Update form if in edit mode
          if (editingUserId.value == userId) {
            editingKaryawanId.value = karyawan.id;
            nikController.text = karyawan.nik;
            // Format tanggal lahir safely
            tanggalLahirController.text = karyawan.tanggalLahir.toIso8601String().split('T')[0];
            jenisKelaminController.text = karyawan.jenisKelamin;
            nomorTeleponController.text = karyawan.nomorTelepon;
            alamatController.text = karyawan.alamat;
            selectedUnitId.value = karyawan.idUnit;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading karyawan for user $userId: $e');
    }
  }
  
  // Create or update karyawan data (profil karyawan untuk user terkait)
  Future<void> saveKaryawanData(int userId) async {
    try {
      final karyawanData = {
        'id_user': userId,
        'nama': namaController.text.trim(),
        'nik': nikController.text.trim(),
        'tanggal_lahir': tanggalLahirController.text.trim(),
        'jenis_kelamin': jenisKelaminController.text.trim(),
        'nomor_telepon': nomorTeleponController.text.trim(),
        'alamat': alamatController.text.trim(),
        'id_unit': selectedUnitId.value > 0 ? selectedUnitId.value : null,
        'is_active': isActiveStatus.value,
      };
      
      Response response;
      if (editingKaryawanId.value > 0) {
        response = await apiService.updateKaryawan(
          editingKaryawanId.value,
          karyawanData,
        );
      } else {
        response = await apiService.createKaryawan(karyawanData);
      }
      
      if (response.isOk) {
        await loadKaryawanForUser(userId);
      } else {
        throw Exception('Gagal menyimpan data karyawan');
      }
    } catch (e) {
      StandardErrorHandler.handleCreateError('data karyawan', e, context: 'Save Karyawan Data');
      rethrow; // Re-throw to be handled by parent operation
    }
  }

  // Watch role change to show/hide karyawan fields
  void onRoleChanged(int? roleId) {
    if (roleId == null) return;
    selectedRoleId.value = roleId;
    isKaryawanRole.value = roleId == 3;
  }
  
  // Get units list
  final RxList<Unit> units = <Unit>[].obs;
  
  Future<void> loadUnits() async {
    try {
      final response = await apiService.getUnits();
      
      if (response.isOk) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
        units.value = items.map((item) => Unit.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading units: $e');
    }
  }
}
