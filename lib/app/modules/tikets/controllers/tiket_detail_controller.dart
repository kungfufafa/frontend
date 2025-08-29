// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/modules/tikets/controllers/tikets_controller.dart';

class TiketDetailController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final AuthService _authService = Get.find<AuthService>();
  
  // Status IDs based on backend (from API testing)
  static const int STATUS_BARU = 1;
  static const int STATUS_DIPROSES = 2;
  static const int STATUS_PENDING = 3;
  static const int STATUS_SELESAI = 4;
  static const int STATUS_DITUTUP = 5;
  static const int STATUS_DIBATALKAN = 6;
  
  // Observable states
  final Rx<Tiket?> tiket = Rx<Tiket?>(null);
  final RxList<Komentar> komentars = <Komentar>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingKomentar = false.obs;
  final RxBool isSendingKomentar = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Form controllers
  final TextEditingController komentarController = TextEditingController();
  final TextEditingController judulController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  final RxString selectedPriority = 'sedang'.obs;
  
  // Status options (will be loaded from API)
  final RxList<Status> statusOptions = <Status>[].obs;
  final RxList<Unit> unitOptions = <Unit>[].obs;
  final RxList<Karyawan> karyawanOptions = <Karyawan>[].obs;
  
  User? get currentUser => _authService.user;
  int? tiketId;
  
  @override
  void onInit() {
    super.onInit();
    
    // Get tiket ID from route parameters
    final args = Get.arguments;
    if (args is Tiket) {
      tiket.value = args;
      tiketId = args.id;
      _fillFormData(args);
    } else if (args is int) {
      tiketId = args;
    } else if (args is Map && args['id'] != null) {
      tiketId = args['id'];
    }
    
    if (tiketId != null) {
      loadTiketDetail();
      loadKomentars();
      loadOptions();
    }
  }
  
  @override
  void onClose() {
    komentarController.dispose();
    judulController.dispose();
    deskripsiController.dispose();
    super.onClose();
  }
  
  void _fillFormData(Tiket tiket) {
    judulController.text = tiket.judul;
    deskripsiController.text = tiket.deskripsi;
    // Convert English priority to Indonesian for the form
    selectedPriority.value = _convertPriorityToIndonesian(tiket.prioritas);
  }
  
  String _convertPriorityToIndonesian(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'rendah';
      case 'medium':
        return 'sedang';
      case 'high':
        return 'tinggi';
      case 'urgent':
        return 'urgent';
      default:
        return 'sedang';
    }
  }
  
  Future<void> loadTiketDetail() async {
    if (tiketId == null) return;
    
    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      final response = await _apiService.getTiketById(tiketId!);
      
      if (response.statusCode == 200) {
        final data = response.body['data'] ?? response.body;
        tiket.value = Tiket.fromJson(data);
        _fillFormData(tiket.value!);
      } else {
        errorMessage.value = response.body != null && response.body is Map 
            ? response.body['message'] ?? 'Gagal memuat detail tiket'
            : 'Gagal memuat detail tiket (${response.statusCode})';
      }
    } catch (e) {
      errorMessage.value = 'Error: $e';
      ApiService.logError('Failed to load tiket detail', context: 'TiketDetailController', stackTrace: e);
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadKomentars() async {
    if (tiketId == null) return;
    
    isLoadingKomentar.value = true;
    
    try {
      final response = await _apiService.getKomentars(tiketId!);
      
      if (response.statusCode == 200) {
        final data = response.body['data'] ?? response.body;
        final List<dynamic> items = data is List ? data : (data['data'] ?? []);
        
        komentars.value = items.map((json) => Komentar.fromJson(json)).toList();
      }
    } catch (e) {
      ApiService.logError('Failed to load komentars', context: 'TiketDetailController', stackTrace: e);
    } finally {
      isLoadingKomentar.value = false;
    }
  }
  
  Future<void> loadOptions() async {
    try {
      // Load status options - fallback ke /statuses jika /statuses/options tidak tersedia
      try {
        final statusResponse = await _apiService.getStatusOptions();
        if (statusResponse.statusCode == 200) {
          final data = statusResponse.body['data'] ?? statusResponse.body;
          final List<dynamic> items = data is List ? data : (data['data'] ?? []);
          statusOptions.value = items.map((json) => Status.fromJson(json)).toList();
                } else {
          // Fallback ke /statuses
          final statusesResponse = await _apiService.getStatuses();
          if (statusesResponse.statusCode == 200) {
            final data = statusesResponse.body['data'] ?? statusesResponse.body;
            final List<dynamic> items = data is List ? data : (data['data'] ?? []);
            statusOptions.value = items.map((json) => Status.fromJson(json)).toList();
                    }
        }
      } catch (_) {
        // Fallback jika call /statuses/options menyebabkan exception
        final statusesResponse = await _apiService.getStatuses();
        if (statusesResponse.statusCode == 200) {
          final data = statusesResponse.body['data'] ?? statusesResponse.body;
          final List<dynamic> items = data is List ? data : (data['data'] ?? []);
          statusOptions.value = items.map((json) => Status.fromJson(json)).toList();
                }
      }
      
      // Load unit options (for admin/manager)
      if (canAssignTiket()) {
        final unitResponse = await _apiService.getUnits();
        if (unitResponse.statusCode == 200) {
          final data = unitResponse.body['data'] ?? unitResponse.body;
          final List<dynamic> items = data is List ? data : (data['data'] ?? []);
          unitOptions.value = items.map((json) => Unit.fromJson(json)).toList();
        }
        
        // Load karyawan options
        final karyawanResponse = await _apiService.getKaryawans();
        if (karyawanResponse.statusCode == 200) {
          final data = karyawanResponse.body['data'] ?? karyawanResponse.body;
          final List<dynamic> items = data is List ? data : (data['data'] ?? []);
          karyawanOptions.value = items.map((json) => Karyawan.fromJson(json)).toList();
        }
      }
    } catch (e) {
      ApiService.logError('Failed to load options', context: 'TiketDetailController', stackTrace: e);
    }
  }
  
  Future<void> sendKomentar() async {
    if (tiketId == null) return;
    
    final komentarText = komentarController.text.trim();
    if (komentarText.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Komentar tidak boleh kosong',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }
    
    isSendingKomentar.value = true;
    
    try {
      final request = CreateKomentarRequest(body: komentarText);
      final response = await _apiService.createKomentar(tiketId!, request);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        komentarController.clear();
        await loadKomentars();
        
        Get.snackbar(
          'Berhasil',
          'Komentar berhasil ditambahkan',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        final errorMessage = response.body != null && response.body is Map 
            ? response.body['message'] ?? 'Gagal menambahkan komentar'
            : 'Gagal menambahkan komentar (${response.statusCode})';
        
        Get.snackbar(
          'Error',
          errorMessage,
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
    } finally {
      isSendingKomentar.value = false;
    }
  }
  
  Future<void> updateTiket() async {
    if (tiketId == null) return;
    
    isLoading.value = true;
    
    try {
      final request = UpdateTiketRequest(
        judul: judulController.text.trim(),
        deskripsi: deskripsiController.text.trim(),
        prioritas: selectedPriority.value,
      );
      
      final response = await _apiService.updateTiket(tiketId!, request);
      
      if (response.statusCode == 200) {
        await loadTiketDetail();
        
        Get.snackbar(
          'Berhasil',
          'Tiket berhasil diperbarui',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        final errorMessage = response.body != null && response.body is Map 
            ? response.body['message'] ?? 'Gagal memperbarui tiket'
            : 'Gagal memperbarui tiket (${response.statusCode})';
        
        Get.snackbar(
          'Error',
          errorMessage,
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
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateStatus(int statusId) async {
    if (tiketId == null) return;
    
    isLoading.value = true;
    
    try {
      final request = UpdateStatusRequest(statusId: statusId);
      final response = await _apiService.updateTiketStatus(tiketId!, request);
      
      if (response.statusCode == 200) {
        await loadTiketDetail();
        
        // Also refresh the tikets list if controller exists
        if (Get.isRegistered<TiketsController>()) {
          final tiketsController = Get.find<TiketsController>();
          // Update the specific tiket in the list
          final updatedTiketIndex = tiketsController.tikets.indexWhere((t) => t.id == tiketId);
          if (updatedTiketIndex != -1 && tiket.value != null) {
            tiketsController.tikets[updatedTiketIndex] = tiket.value!;
            tiketsController.applyFilters();
          }
        }
        
        Get.snackbar(
          'Berhasil',
          'Status tiket berhasil diperbarui',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        final errorMessage = response.body != null && response.body is Map 
            ? response.body['message'] ?? 'Gagal memperbarui status'
            : 'Gagal memperbarui status (${response.statusCode})';
        
        Get.snackbar(
          'Error',
          errorMessage,
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
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> assignToUnit(int unitId, {String? komentar}) async {
    if (tiketId == null) return;
    
    isLoading.value = true;
    
    try {
      final response = await _apiService.assignTiketToUnit(tiketId!, unitId, komentar: komentar);
      
      // Debug logging
      ApiService.logDebug('Assignment response status: ${response.statusCode}', context: 'TiketDetailController');
      ApiService.logDebug('Assignment response body: ${response.body}', context: 'TiketDetailController');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadTiketDetail();
        
        Get.snackbar(
          'Berhasil',
          'Tiket berhasil ditugaskan ke unit',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        String errorMessage;
        if (response.statusCode == null) {
          errorMessage = 'Tidak ada respon dari server';
        } else if (response.body != null && response.body is Map) {
          errorMessage = response.body['message'] ?? 'Gagal menugaskan tiket (${response.statusCode})';
        } else {
          errorMessage = 'Gagal menugaskan tiket (${response.statusCode ?? "Unknown"})';
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      ApiService.logError('Failed to assign to unit', context: 'TiketDetailController', stackTrace: e);
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> assignToKaryawan(int karyawanId, {String? komentar}) async {
    if (tiketId == null) return;
    
    isLoading.value = true;
    
    try {
      final response = await _apiService.assignTiketToKaryawan(tiketId!, karyawanId, komentar: komentar);
      
      // Debug logging
      ApiService.logDebug('Assignment response status: ${response.statusCode}', context: 'TiketDetailController');
      ApiService.logDebug('Assignment response body: ${response.body}', context: 'TiketDetailController');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadTiketDetail();
        
        // Also refresh the tikets list if controller exists
        if (Get.isRegistered<TiketsController>()) {
          final tiketsController = Get.find<TiketsController>();
          // Update the specific tiket in the list
          final updatedTiketIndex = tiketsController.tikets.indexWhere((t) => t.id == tiketId);
          if (updatedTiketIndex != -1 && tiket.value != null) {
            tiketsController.tikets[updatedTiketIndex] = tiket.value!;
            tiketsController.applyFilters();
          }
        }
        
        Get.snackbar(
          'Berhasil',
          'Tiket berhasil ditugaskan ke karyawan',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        String errorMessage;
        if (response.statusCode == null) {
          errorMessage = 'Tidak ada respon dari server';
        } else if (response.body != null && response.body is Map) {
          errorMessage = response.body['message'] ?? 'Gagal menugaskan tiket (${response.statusCode})';
        } else {
          errorMessage = 'Gagal menugaskan tiket (${response.statusCode ?? "Unknown"})';
        }
        
        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
        );
      }
    } catch (e) {
      ApiService.logError('Failed to assign to karyawan', context: 'TiketDetailController', stackTrace: e);
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteKomentar(int komentarId) async {
    try {
      final response = await _apiService.deleteKomentar(komentarId);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        komentars.removeWhere((k) => k.id == komentarId);
        
        Get.snackbar(
          'Berhasil',
          'Komentar berhasil dihapus',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      } else {
        final errorMessage = response.body != null && response.body is Map 
            ? response.body['message'] ?? 'Gagal menghapus komentar'
            : 'Gagal menghapus komentar (${response.statusCode})';
        
        Get.snackbar(
          'Error',
          errorMessage,
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
  
  bool canEditTiket() {
    if (currentUser == null || tiket.value == null) return false;
    
    // Admin can edit all
    if (currentUser!.isAdmin()) return true;
    
    // Manager can edit tikets
    if (currentUser!.isManager()) return true;
    
    // User/Klien cannot edit tikets at all
    if (currentUser!.isUser()) return false;
    
    // Karyawan cannot edit tickets - they can only update status
    if (currentUser!.isKaryawan()) return false;
    
    return false;
  }
  
  bool canUpdateStatus() {
    if (currentUser == null || tiket.value == null) return false;
    
    // Admin dan Manager selalu bisa mengubah status
    if (currentUser!.isAdmin() || currentUser!.isManager()) return true;
    
    // Karyawan hanya bisa mengubah status tiket yang ditugaskan padanya
    if (currentUser!.isKaryawan()) {
      // Check if ticket is assigned to this karyawan
      if (tiket.value!.karyawan != null) {
        return tiket.value!.karyawan!.idUser == currentUser!.id;
      }
      return false;
    }
    
    return false;
  }
  
  bool canAssignTiket() {
    if (currentUser == null) return false;
    
    // Admin and Manager can assign
    return currentUser!.isAdmin() || currentUser!.isManager();
  }
  
  bool canDeleteKomentar(Komentar komentar) {
    if (currentUser == null) return false;
    
    // Admin can delete all
    if (currentUser!.isAdmin()) return true;
    
    // User can delete their own komentar
    if (komentar.idUser == currentUser!.id) return true;
    
    return false;
  }
  
  // Get available next status transitions based on current status
  List<int> getAvailableStatusTransitions() {
    if (tiket.value == null) return [];
    
    final currentStatus = tiket.value!.idStatus ?? STATUS_BARU;
    
    // Hanya Karyawan yang bisa mengubah status, dan hanya untuk tiket yang ditugaskan padanya
    if (currentUser?.isKaryawan() ?? false) {
      // Check if ticket is assigned to this karyawan by comparing karyawan.id_user with current user id
      bool isMyTicket = false;
      if (tiket.value!.karyawan != null) {
        isMyTicket = tiket.value!.karyawan!.idUser == currentUser!.id;
      }
      
      if (!isMyTicket) {
        debugPrint('❌ Not my ticket - karyawan.idUser: ${tiket.value!.karyawan?.idUser}, currentUser.id: ${currentUser!.id}');
        return [];
      }
      
      debugPrint('✅ My ticket - allowing status transitions from status: $currentStatus');
      
      switch (currentStatus) {
        case STATUS_BARU:
          return [STATUS_DIPROSES];
        case STATUS_DIPROSES:
          return [STATUS_PENDING, STATUS_SELESAI];
        case STATUS_PENDING:
          return [STATUS_DIPROSES];
        case STATUS_SELESAI:
          return [];
        default:
          return [];
      }
    }
    
    // Admin dan Manager juga bisa mengubah status
    if ((currentUser?.isAdmin() ?? false) || (currentUser?.isManager() ?? false)) {
      // Admin dan Manager bisa melakukan semua transisi status kecuali dari Selesai
      if (currentStatus == STATUS_SELESAI) return [];
      
      // Return all possible statuses except current one
      return [STATUS_BARU, STATUS_DIPROSES, STATUS_PENDING, STATUS_SELESAI]
        .where((s) => s != currentStatus)
        .toList();
    }
    
    // Selain itu, tidak bisa mengubah status
    return [];
  }
  
  String getStatusLabel(int statusId) {
    // Check from actual status options if available
    if (statusOptions.isNotEmpty) {
      final status = statusOptions.firstWhere(
        (s) => s.id == statusId,
        orElse: () => Status(
          id: statusId,
          nama: 'Status $statusId',
          keterangan: null,
          colorCode: '#6c757d',
          orderSequence: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return status.nama;
    }
    
    // Fallback to hardcoded values
    switch (statusId) {
      case STATUS_BARU:
        return 'Baru';
      case STATUS_DIPROSES:
        return 'Diproses';
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_SELESAI:
        return 'Selesai';
      case STATUS_DITUTUP:
        return 'Ditutup';
      case STATUS_DIBATALKAN:
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }
  
  Color getStatusColor(int statusId) {
    switch (statusId) {
      case STATUS_BARU:
        return Colors.blue;
      case STATUS_DIPROSES:
        return Colors.orange;
      case STATUS_PENDING:
        return Colors.yellow[700]!;
      case STATUS_SELESAI:
        return Colors.green;
      case STATUS_DITUTUP:
        return Colors.grey;
      case STATUS_DIBATALKAN:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
