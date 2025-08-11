import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart'; // For Karyawan model
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';

class UsersController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  final AuthService authService = Get.find<AuthService>();

  // Observable states
  var users = <User>[].obs;
  var karyawanMap = <int, Karyawan>{}.obs; // Map user ID to Karyawan data
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
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
  var isSubmitting = false.obs;
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

  // Load users dengan pagination
  Future<void> loadUsers({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMoreData.value = true;
        users.clear();
      }

      if (!hasMoreData.value && !refresh) return;

      if (currentPage.value == 1) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      // Build query parameters - convert all values to String to avoid TypeError
      Map<String, String> queryParams = {
        'page': currentPage.value.toString(),
        'per_page': '15',
      };

      // Search - backend expects 'search'
      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }

      // Filter by role - backend expects 'role_id'
      if (selectedRole.value > 0) {
        queryParams['role_id'] = selectedRole.value.toString();
      }

      // Filter by status - backend expects 'is_active' and checks 'isActive' column
      // Always send is_active parameter
      queryParams['is_active'] = isActiveFilter.value ? '1' : '0';

      // Debug: Log token dan query params
      final token = ApiService.getToken();
      debugPrint('🔑 Current token: ${token?.substring(0, 20)}...');
      debugPrint('📋 Query params: $queryParams');
      debugPrint('🔍 Filter - Role: ${selectedRole.value}, Active: ${isActiveFilter.value}, Search: "${searchQuery.value}"');
      
      final response = await apiService.getUsers(query: queryParams);
      
      // Debug: Log response
      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.isOk && response.body['success'] == true) {
        try {
          // Cek struktur respons
          debugPrint('📊 Raw response body: ${response.body}');
          debugPrint('📊 Response body type: ${response.body.runtimeType}');
          
          dynamic data;
          
          // Handle different response structures
          if (response.body is List) {
            // Direct array response
            data = response.body;
            debugPrint('📊 Direct array response detected');
          } else if (response.body is Map<String, dynamic>) {
            // Paginated response
            final responseMap = response.body as Map<String, dynamic>;
            debugPrint('📊 Paginated response detected: ${responseMap.keys}');
            
            if (responseMap.containsKey('data')) {
              final dataField = responseMap['data'];
              debugPrint('📊 Data field found: ${dataField.runtimeType}');
              debugPrint('📊 Data content: $dataField');
              
              // Check if data field is nested (contains another 'data' field)
              if (dataField is Map<String, dynamic> && dataField.containsKey('data')) {
                // Nested structure: response.data.data contains the actual array
                data = dataField['data'];
                debugPrint('📊 Nested data structure detected, using data.data');
                
                // Handle pagination info from nested structure
                if (dataField.containsKey('total')) {
                  totalUsers.value = dataField['total'] ?? 0;
                  debugPrint('📊 Total users: ${totalUsers.value}');
                }
                
                if (dataField.containsKey('current_page')) {
                  currentPage.value = dataField['current_page'] ?? 1;
                  debugPrint('📊 Current page: ${currentPage.value}');
                }
                
                if (dataField.containsKey('last_page')) {
                  final lastPage = dataField['last_page'] ?? 1;
                  hasMoreData.value = currentPage.value < lastPage;
                  debugPrint('📊 Has more data: ${hasMoreData.value}');
                }
              } else {
                // Direct structure: response.data is the array
                data = dataField;
                debugPrint('📊 Direct data structure detected');
                
                // Handle pagination info from root level
                if (responseMap.containsKey('total')) {
                  totalUsers.value = responseMap['total'] ?? 0;
                  debugPrint('📊 Total users: ${totalUsers.value}');
                }
                
                if (responseMap.containsKey('current_page')) {
                  currentPage.value = responseMap['current_page'] ?? 1;
                  debugPrint('📊 Current page: ${currentPage.value}');
                }
                
                if (responseMap.containsKey('last_page')) {
                  final lastPage = responseMap['last_page'] ?? 1;
                  hasMoreData.value = currentPage.value < lastPage;
                  debugPrint('📊 Has more data: ${hasMoreData.value}');
                }
              }
            } else {
              debugPrint('❌ No data field in response');
              throw Exception('Invalid response structure: no data field');
            }
          } else {
            debugPrint('❌ Unexpected response type: ${response.body.runtimeType}');
            throw Exception('Unexpected response type: ${response.body.runtimeType}');
          }
          
          // Detailed validation of data type
          debugPrint('📊 About to validate data type...');
          debugPrint('📊 Data is List: ${data is List}');
          debugPrint('📊 Data is Iterable: ${data is Iterable}');
          debugPrint('📊 Data is int: ${data is int}');
          debugPrint('📊 Data is String: ${data is String}');
          debugPrint('📊 Data actual type: ${data.runtimeType}');
          debugPrint('📊 Data toString: ${data.toString()}');
          
          // Validate data is iterable
          if (data is! Iterable) {
            debugPrint('❌ CRITICAL: Data is not iterable!');
            debugPrint('❌ Data type: ${data.runtimeType}');
            debugPrint('❌ Data value: $data');
            debugPrint('❌ This will cause TypeError: type \'${data.runtimeType}\' is not a subtype of type \'Iterable<dynamic>\'');
            
            // Show detailed error in snackbar
            Get.snackbar(
              'TypeError Detected',
              'Data type: ${data.runtimeType}, Value: $data',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange[100],
              colorText: Colors.orange[800],
              duration: const Duration(seconds: 10),
            );
            
            throw TypeError();
          }
          
          debugPrint('📊 Data validation passed - proceeding with iteration');
          debugPrint('📊 Data to parse: ${data.runtimeType} with ${(data as Iterable).length} items');
          
          // Parse users from data
          final List<User> newUsers = [];
          int itemIndex = 0;
          for (var item in data) {
            debugPrint('📊 Parsing item $itemIndex: ${item.runtimeType} - $item');
            try {
              final user = User.fromJson(item as Map<String, dynamic>);
              newUsers.add(user);
              debugPrint('✅ User $itemIndex parsed: ${user.nama}');
            } catch (parseError, parseStack) {
              debugPrint('❌ Error parsing user item $itemIndex: $parseError');
              debugPrint('❌ Parse stack: $parseStack');
              debugPrint('❌ Item data: $item');
              continue; // Skip invalid items
            }
            itemIndex++;
          }
          
          // Update users list
          if (currentPage.value == 1) {
            users.value = newUsers;
            debugPrint('📊 Users list replaced with ${newUsers.length} items');
          } else {
            users.addAll(newUsers);
            debugPrint('📊 Added ${newUsers.length} users to existing list');
          }
          
          debugPrint('📊 Total users in list: ${users.length}');
          
          // Load karyawan data for users with Karyawan role
          loadKaryawanDataForUsers(newUsers);
          
        } catch (e, stackTrace) {
          debugPrint('❌ Error in loadUsers: $e');
          debugPrint('❌ Error type: ${e.runtimeType}');
          debugPrint('❌ Stack trace: $stackTrace');
          
          // Show detailed error information
          String errorMessage = 'Terjadi kesalahan: $e';
          if (e is TypeError) {
            errorMessage = 'TypeError: ${e.toString()}';
          }
          
          Get.snackbar(
            'Error Detail',
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
            duration: const Duration(seconds: 10),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired atau tidak valid
        debugPrint('🚫 Token expired/invalid, redirecting to login');
        Get.find<AuthService>().logout();
        Get.snackbar(
          'Error',
          'Sesi telah berakhir, silakan login kembali',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Gagal memuat data users',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
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
        nikController.text = karyawan.nik ?? '';
        tanggalLahirController.text = karyawan.tanggalLahir?.toIso8601String().split('T')[0] ?? '';
        jenisKelaminController.text = karyawan.jenisKelamin ?? '';
        nomorTeleponController.text = karyawan.nomorTelepon ?? '';
        alamatController.text = karyawan.alamat;
        selectedUnitId.value = karyawan.idUnit ?? 0;
      } else {
        // Load karyawan data if not in cache
        await loadKaryawanForUser(user.id);
      }
    }
  }

  // Create new user
  Future<void> createUser() async {
    if (!_validateForm()) return;

    try {
      isSubmitting.value = true;

      // Use isActive (camelCase) as boolean - this is what backend expects
      final body = {
        'nama': namaController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'password_confirmation': passwordController.text,
        'id_role': selectedRoleId.value,
        'isActive': isActiveStatus.value, // Backend expects camelCase with boolean
      };
      
      // Debug logging
      debugPrint('📤 Creating user with body: $body');
      debugPrint('✅ Using correct field name: isActive (camelCase) with boolean value: ${isActiveStatus.value}');

      final response = await apiService.createUser(body);

      if (response.isOk && response.body['success'] == true) {
        // Get created user ID
        final userId = response.body['data']?['id'] ?? 0;
        
        // If role is Karyawan, create karyawan data
        if (selectedRoleId.value == 3 && userId > 0) {
          await saveKaryawanData(userId);
        }
        
        Get.snackbar(
          'Sukses',
          'User berhasil dibuat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        clearForm();
        loadUsers(refresh: true);
        Get.back(); // Close dialog/form
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Gagal membuat user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update user
  Future<void> updateUser() async {
    if (!_validateForm(isEdit: true)) return;

    try {
      isSubmitting.value = true;

      // Use isActive (camelCase) as boolean - this is what backend expects
      final body = {
        'nama': namaController.text.trim(),
        'email': emailController.text.trim(),
        'id_role': selectedRoleId.value,
        'isActive': isActiveStatus.value, // Backend expects camelCase with boolean
      };

      // Debug logging
      debugPrint('📤 Updating user ${editingUserId.value} with body: $body');
      debugPrint('📤 isActiveStatus.value: ${isActiveStatus.value} (sending as isActive: ${body['isActive']})');
      debugPrint('✅ Using correct field name: isActive (camelCase) with boolean value');

      // Tambahkan password jika diisi
      if (passwordController.text.isNotEmpty) {
        body['password'] = passwordController.text;
        body['password_confirmation'] = passwordController.text;
      }

      final response = await apiService.updateUser(editingUserId.value, body);

      if (response.isOk && response.body['success'] == true) {
        // Debug logging
        debugPrint('📥 Update response: ${response.body}');
        
        // Update karyawan data if role is Karyawan
        if (selectedRoleId.value == 3) {
          await saveKaryawanData(editingUserId.value);
        }
        
        Get.snackbar(
          'Sukses',
          'User berhasil diupdate',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        clearForm();
        loadUsers(refresh: true);
        Get.back(); // Close dialog/form
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Gagal mengupdate user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // Delete user
  Future<void> deleteUser(int userId, String userName) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus user "$userName"?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final response = await apiService.deleteUser(userId);

      if (response.isOk && response.body['success'] == true) {
        Get.snackbar(
          'Sukses',
          'User berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        loadUsers(refresh: true);
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Gagal menghapus user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Toggle user active status
  Future<void> toggleUserStatus(User user) async {
    try {
      final newStatus = !user.isActive;
      
      // Debug logging
      debugPrint('🔄 Toggling user ${user.id} status from ${user.isActive} to $newStatus');
      
      // Use isActive (camelCase) as boolean - this is what backend expects
      final body = {
        'nama': user.nama,
        'email': user.email,
        'id_role': user.idRole,
        'isActive': newStatus, // Backend expects camelCase with boolean
      };
      
      debugPrint('📤 Toggle status body: $body');
      debugPrint('✅ Using correct field name: isActive (camelCase) with boolean value: $newStatus');
      
      final response = await apiService.updateUser(user.id, body);

      if (response.isOk && response.body['success'] == true) {
        // Debug logging
        debugPrint('📥 Toggle status response: ${response.body}');
        
        Get.snackbar(
          'Sukses',
          'Status user berhasil diubah',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        loadUsers(refresh: true);
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Gagal mengubah status user',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Form validation
  bool _validateForm({bool isEdit = false}) {
    if (namaController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Nama tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Email tidak boleh kosong',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Format email tidak valid',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    // Password validation untuk create user atau edit dengan password baru
    if (!isEdit || passwordController.text.isNotEmpty) {
      if (passwordController.text.length < 6) {
        Get.snackbar(
          'Error',
          'Password minimal 6 karakter',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
      
      // Get all karyawan data
      final response = await apiService.getKaryawans();
      
      if (response.isOk) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
        // Parse and map karyawan to users
        for (var item in items) {
          try {
            final karyawan = Karyawan.fromJson(item);
            if (karyawan.idUser != null) {
              karyawanMap[karyawan.idUser!] = karyawan;
            }
          } catch (e) {
            debugPrint('Error parsing karyawan: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading karyawan data: $e');
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
            nikController.text = karyawan.nik ?? '';
            tanggalLahirController.text = karyawan.tanggalLahir?.toIso8601String().split('T')[0] ?? '';
            jenisKelaminController.text = karyawan.jenisKelamin ?? '';
            nomorTeleponController.text = karyawan.nomorTelepon ?? '';
            alamatController.text = karyawan.alamat;
            selectedUnitId.value = karyawan.idUnit ?? 0;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading karyawan for user $userId: $e');
    }
  }
  
  // Create or update karyawan data (profil karyawan untuk user terkait)
  Future<void> saveKaryawanData(int userId) async {
    // Tidak dibatasi hanya role Karyawan, mengikuti konsep relasi user-karyawan
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
        // Update existing karyawan
        response = await apiService.updateKaryawan(
          editingKaryawanId.value,
          karyawanData,
        );
      } else {
        // Create new karyawan
        response = await apiService.createKaryawan(karyawanData);
      }
      
      if (response.isOk) {
        // Reload karyawan data
        await loadKaryawanForUser(userId);
      }
    } catch (e) {
      debugPrint('Error saving karyawan data: $e');
      Get.snackbar(
        'Error',
        'Gagal menyimpan data karyawan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
