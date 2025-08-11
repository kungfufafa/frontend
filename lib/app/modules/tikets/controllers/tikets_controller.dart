import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/data/models/user_model.dart';

class TiketsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthService _authService = Get.find<AuthService>();
  
  // Observable states
  final RxList<Tiket> tikets = <Tiket>[].obs;
  final RxList<Tiket> filteredTikets = <Tiket>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Filters
  final RxInt selectedStatusId = 0.obs; // 0 = all
  final RxInt selectedUnitId = 0.obs; // 0 = all
  final RxString selectedPriority = ''.obs; // empty = all
  final RxString searchQuery = ''.obs;
  final Rx<DateTime?> dateFrom = Rx<DateTime?>(null);
  final Rx<DateTime?> dateTo = Rx<DateTime?>(null);
  final RxString sortBy = 'created_at'.obs;
  final RxString sortOrder = 'desc'.obs;
  
  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt lastPage = 1.obs;
  final RxInt totalItems = 0.obs;
  
  // Filter Options
  final RxList<Status> statusOptions = <Status>[].obs;
  final RxList<Unit> unitOptions = <Unit>[].obs;
  
  final List<Map<String, String>> priorityOptions = [
    {'value': '', 'label': 'Semua Prioritas'},
    {'value': 'rendah', 'label': 'Rendah'},
    {'value': 'sedang', 'label': 'Sedang'},
    {'value': 'tinggi', 'label': 'Tinggi'},
    {'value': 'urgent', 'label': 'Urgent'},
  ];
  
  User? get currentUser => _authService.user;
  
  // Role checks
  bool get isAdmin => currentUser?.isAdmin() ?? false;
  bool get isManager => currentUser?.isManager() ?? false;
  bool get isKaryawan => currentUser?.isKaryawan() ?? false;
  bool get isUser => currentUser?.isUser() ?? false;
  bool get isDireksi => currentUser?.isDireksi() ?? false;
  
  // Permission checks
  bool canEditTiket(Tiket tiket) {
    if (isAdmin) return true;
    if (isManager) return true;
    // Karyawan cannot edit tickets - they can only update status
    if (isKaryawan) return false;
    // User can edit their own tiket
    if (isUser && tiket.idUser == currentUser?.id) return true;
    return false;
  }
  
  bool canDeleteTiket(Tiket tiket) {
    if (isAdmin) return true;
    if (isManager) return true;
    return false;
  }
  
  bool canAssignTiket(Tiket tiket) {
    return isAdmin || isManager;
  }
  
  bool canChangeStatus(Tiket tiket) {
    if (isAdmin) return true;
    if (isManager) return true;
    // Karyawan can change status of assigned tikets
    if (isKaryawan && tiket.idKaryawan != null) return true;
    return false;
  }
  
  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();
    loadTikets();
    
    // Setup reactive filters - trigger reload when filters change
    ever(selectedStatusId, (_) => loadTikets(refresh: true));
    ever(selectedUnitId, (_) => loadTikets(refresh: true));
    ever(selectedPriority, (_) => loadTikets(refresh: true));
    ever(dateFrom, (_) => loadTikets(refresh: true));
    ever(dateTo, (_) => loadTikets(refresh: true));
    ever(sortBy, (_) => loadTikets(refresh: true));
    ever(sortOrder, (_) => loadTikets(refresh: true));
    debounce(searchQuery, (_) => loadTikets(refresh: true), time: const Duration(milliseconds: 500));
  }
  
  Future<void> loadFilterOptions() async {
    try {
      // Load status options
      final statusResponse = await _apiService.getStatuses();
      if (statusResponse.isOk) {
        final data = statusResponse.body['data'] ?? statusResponse.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        statusOptions.value = items.map((json) => Status.fromJson(json)).toList();
      }
      
      // Load unit options (for admin/manager)
      if (isAdmin || isManager) {
        final unitResponse = await _apiService.getUnits();
        if (unitResponse.isOk) {
          final data = unitResponse.body['data'] ?? unitResponse.body;
          final List<dynamic> items = data is List ? data : (data['data'] ?? []);
          unitOptions.value = items.map((json) => Unit.fromJson(json)).toList();
        }
      }
    } catch (e) {
      ApiService.logError('Failed to load filter options', context: 'TiketsController', stackTrace: e);
    }
  }
  
  Future<void> loadTikets({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      tikets.clear();
    }
    
    if (isLoading.value || isLoadingMore.value) return;
    
    if (currentPage.value == 1) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }
    
    try {
      final queryParams = <String, String>{
        'page': currentPage.value.toString(),
        'per_page': '20',
      };
      
      // Add filters to query params according to backend API
      if (searchQuery.value.isNotEmpty) {
        queryParams['search'] = searchQuery.value;
      }
      
      if (selectedStatusId.value > 0) {
        queryParams['status_id'] = selectedStatusId.value.toString();
      }
      
      if (selectedUnitId.value > 0) {
        queryParams['unit_id'] = selectedUnitId.value.toString();
      }
      
      if (selectedPriority.value.isNotEmpty) {
        queryParams['prioritas'] = selectedPriority.value;
      }
      
      if (dateFrom.value != null) {
        queryParams['date_from'] = dateFrom.value!.toIso8601String().split('T')[0];
      }
      
      if (dateTo.value != null) {
        queryParams['date_to'] = dateTo.value!.toIso8601String().split('T')[0];
      }
      
      queryParams['sort_by'] = sortBy.value;
      queryParams['sort_order'] = sortOrder.value;
      
      // Role-based filtering
      // Backend handles role-based filtering automatically based on auth token
      // No need to add extra filters here as the backend will filter based on user role
      
      final response = await _apiService.getTikets(query: queryParams);
      
      if (response.statusCode == 200) {
        final data = response.body['data'];
        final List<dynamic> items = data['data'] ?? data['items'] ?? data;
        
        final newTikets = items.map((json) => Tiket.fromJson(json)).toList();
        
        if (refresh || currentPage.value == 1) {
          tikets.value = newTikets;
        } else {
          tikets.addAll(newTikets);
        }
        
        // Update pagination info
        if (data is Map && data.containsKey('last_page')) {
          lastPage.value = data['last_page'] ?? 1;
          totalItems.value = data['total'] ?? tikets.length;
        }
        
        applyFilters();
        errorMessage.value = '';
      } else {
        errorMessage.value = response.body['message'] ?? 'Gagal memuat tiket';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      ApiService.logError('Failed to load tikets', context: 'TiketsController', stackTrace: e);
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  
  void applyFilters() {
    // All filtering is now done server-side
    // Just pass through the tikets
    filteredTikets.value = tikets.toList();
  }
  
  Future<void> loadMoreTikets() async {
    if (currentPage.value < lastPage.value) {
      currentPage.value++;
      await loadTikets();
    }
  }
  
  Future<void> deleteTiket(int tiketId) async {
    try {
      final response = await _apiService.deleteTiket(tiketId);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        tikets.removeWhere((t) => t.id == tiketId);
        applyFilters();
        
        Get.snackbar(
          'Berhasil',
          'Tiket berhasil dihapus',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        Get.snackbar(
          'Error',
          response.body['message'] ?? 'Gagal menghapus tiket',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }
  
  void setStatusFilter(int statusId) {
    selectedStatusId.value = statusId;
  }
  
  void setUnitFilter(int unitId) {
    selectedUnitId.value = unitId;
  }
  
  void setPriorityFilter(String priority) {
    selectedPriority.value = priority;
  }
  
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }
  
  void setDateFrom(DateTime? date) {
    dateFrom.value = date;
  }
  
  void setDateTo(DateTime? date) {
    dateTo.value = date;
  }
  
  void setSorting(String field, String order) {
    sortBy.value = field;
    sortOrder.value = order;
  }
  
  void clearFilters() {
    selectedStatusId.value = 0;
    selectedUnitId.value = 0;
    selectedPriority.value = '';
    searchQuery.value = '';
    dateFrom.value = null;
    dateTo.value = null;
    sortBy.value = 'created_at';
    sortOrder.value = 'desc';
  }
  
  void navigateToDetail(Tiket tiket) {
    // Pass only the ID, let the detail controller fetch fresh data
    Get.toNamed('/tikets/${tiket.id}', arguments: tiket.id);
  }
  
  void navigateToCreate() {
    Get.toNamed('/tikets/create');
  }
}
