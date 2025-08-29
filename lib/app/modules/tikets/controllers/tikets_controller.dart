import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/services/api_service.dart';

class TiketsController extends BaseController {
  // Remove duplicate dependencies - using BaseController's apiService and authService
  
  // Observable states
  final RxList<Tiket> tikets = <Tiket>[].obs;
  final RxList<Tiket> filteredTikets = <Tiket>[].obs;
  // Use BaseController's isLoading, isLoadingMore, and errorMessage
  
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
  
  // Role-based data
  final RxList<User> teamMembers = <User>[].obs;
  final RxList<Unit> availableUnits = <Unit>[].obs;
  
  final List<Map<String, String>> priorityOptions = [
    {'value': '', 'label': 'Semua Prioritas'},
    {'value': 'rendah', 'label': 'Rendah'},
    {'value': 'sedang', 'label': 'Sedang'},
    {'value': 'tinggi', 'label': 'Tinggi'},
    {'value': 'urgent', 'label': 'Urgent'},
  ];
  
  User? get currentUser => authService.user;
  
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
    // User/Klien cannot edit tickets - only create, read, and search
    if (isUser) return false;
    return false;
  }
  
  bool canDeleteTiket(Tiket tiket) {
    if (isAdmin) return true;
    // Manager can delete any ticket
    if (isManager) return true;
    // Karyawan can only delete their own tickets
    if (isKaryawan) {
      return tiket.idUser == currentUser?.id;
    }
    return false;
  }
  
  bool canDeleteCompletedTiket(Tiket tiket) {
    // Only Manager and Admin can delete completed tickets
    return (isAdmin || isManager) && _isCompletedTicket(tiket);
  }
  
  bool canAssignTiket(Tiket tiket) {
    return isAdmin || isManager;
  }
  
  bool canEditUnit(Tiket tiket) {
    // Only Manager and Admin can edit unit assignments
    return isAdmin || isManager;
  }
  
  bool canAssignEmployee(Tiket tiket) {
    // Only Manager and Admin can assign employees
    return isAdmin || isManager;
  }
  
  bool canReassignTicket(Tiket tiket) {
    // Only Manager and Admin can reassign tickets to team members
    return isAdmin || isManager;
  }
  
  bool canChangeStatus(Tiket tiket) {
    if (isAdmin) return true;
    if (isManager) return true;
    // Karyawan can change status of assigned tikets
    if (isKaryawan && tiket.idKaryawan != null) return true;
    return false;
  }
  
  // UI Permission checks
  bool get canCreateTicket {
    // Manager and Karyawan can create tickets
    return isManager || isKaryawan || isUser;
  }
  
  bool get showCreateButton {
    // Show create button for Manager and Karyawan
    return isManager || isKaryawan;
  }
  
  @override
  Future<void> refreshData() async {
    await loadTikets(refresh: true);
  }

  @override
  void navigateToListPage() {
    // Stay on tikets list - no navigation needed
  }

  @override
  void navigateToDetailPage(String id) {
    Get.toNamed('/tikets/$id');
  }

  // Helper methods
  bool _isCompletedTicket(Tiket tiket) {
    // Assuming status ID 4 is "Selesai" based on typical ticket systems
    return tiket.idStatus == 4 || tiket.status?.nama.toLowerCase() == 'selesai';
  }

  // Public helper for views to check completed status without accessing private method
  bool isCompletedTicket(Tiket tiket) => _isCompletedTicket(tiket);
  
  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();
    loadTikets();
    
    // Load role-specific data
    if (isManager || isAdmin) {
      loadTeamMembers();
      loadAvailableUnits();
    }
    
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
      final statusResponse = await apiService.getStatuses();
      if (statusResponse.isOk) {
        final data = statusResponse.body['data'] ?? statusResponse.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        statusOptions.value = items.map((json) => Status.fromJson(json)).toList();
      }
      
      // Load unit options (for admin/manager)
      if (isAdmin || isManager) {
        final unitResponse = await apiService.getUnits();
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
    await performListOperation(
      loadFunction: () => _loadTiketsData(refresh: refresh),
      refresh: refresh,
    );
  }

  Future<void> _loadTiketsData({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      tikets.clear();
    }
    
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
    
    final response = await apiService.getTikets(query: queryParams);
    
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
      throw Exception(response.body['message'] ?? 'Gagal memuat tiket');
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
    final tiket = tikets.firstWhere((t) => t.id == tiketId);
    await performDeleteOperation(
      id: tiketId.toString(),
      itemName: tiket.judul,
      deleteFunction: () => _deleteTiketData(tiketId),
    );
  }

  Future<void> _deleteTiketData(int tiketId) async {
    final response = await apiService.deleteTiket(tiketId);
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      tikets.removeWhere((t) => t.id == tiketId);
      applyFilters();
    } else {
      throw Exception(response.body['message'] ?? 'Gagal menghapus tiket');
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
  
  // Enhanced methods for role-based functionality
  Future<void> loadTeamMembers() async {
    if (!isManager && !isAdmin) return;
    
    try {
      final response = await apiService.getUsers();
      
      if (response.statusCode == 200) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        teamMembers.value = items.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {
      ApiService.logError('Failed to load team members', context: 'TiketsController', stackTrace: e);
    }
  }
  
  Future<void> loadAvailableUnits() async {
    if (!isManager && !isAdmin) return;
    
    try {
      final response = await apiService.getUnits();
      
      if (response.statusCode == 200) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        availableUnits.value = items.map((json) => Unit.fromJson(json)).toList();
      }
    } catch (e) {
      ApiService.logError('Failed to load available units', context: 'TiketsController', stackTrace: e);
    }
  }
  
  Future<void> reassignTicketToTeamMember(Tiket tiket, User teamMember, {String? reason}) async {
    if (!canReassignTicket(tiket)) return;
    
    try {
      final response = await apiService.assignTiketToKaryawan(
        tiket.id, 
        teamMember.id, 
        komentar: reason
      );
      
      if (response.statusCode == 200) {
        // Update the ticket in the list
        final index = tikets.indexWhere((t) => t.id == tiket.id);
        if (index != -1) {
          tikets[index] = tiket.copyWith(
            idKaryawan: teamMember.id,
            // Note: We might need to update the karyawan object as well
          );
          applyFilters();
        }
        
        showSuccessSnackbar('Tiket berhasil ditugaskan ulang ke ${teamMember.nama}');
      } else {
        showErrorSnackbar(response.body['message'] ?? 'Gagal menugaskan ulang tiket');
      }
    } catch (e) {
      handleError(e, context: 'reassignTicketToTeamMember');
    }
  }
  
  Future<void> updateTicketUnit(Tiket tiket, Unit newUnit, {String? reason}) async {
    if (!canEditUnit(tiket)) return;
    
    try {
      final response = await apiService.assignTiketToUnit(
        tiket.id, 
        newUnit.id, 
        komentar: reason
      );
      
      if (response.statusCode == 200) {
        // Update the ticket in the list
        final index = tikets.indexWhere((t) => t.id == tiket.id);
        if (index != -1) {
          tikets[index] = tiket.copyWith(
            idUnit: newUnit.id,
            // Note: We might need to update the unit object as well
          );
          applyFilters();
        }
        
        showSuccessSnackbar('Unit tiket berhasil diperbarui ke ${newUnit.nama}');
      } else {
        showErrorSnackbar(response.body['message'] ?? 'Gagal memperbarui unit tiket');
      }
    } catch (e) {
      handleError(e, context: 'updateTicketUnit');
    }
  }
}
