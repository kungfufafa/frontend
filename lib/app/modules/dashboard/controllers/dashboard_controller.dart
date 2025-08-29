import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/core/controllers/base_controller.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/services/pdf_export_service.dart';

class DashboardController extends BaseController {
  // Remove duplicate service declarations since they're in BaseController
  // final ApiService apiService = Get.find<ApiService>();
  // final AuthService authService = Get.find<AuthService>();

  // Observable states - keep isLoading from BaseController
  // var isLoading = false.obs;
  
  // Common stats observables (ringkasan umum untuk header)
  var totalUsers = 0.obs;
  var totalTickets = 0.obs;
  var openTickets = 0.obs;
  var closedTickets = 0.obs;
  
  // Lists
  final RxList<Tiket> recentTikets = <Tiket>[].obs;

  // ================= Role-specific Observables =================
  // Admin
  final RxMap<String, dynamic> adminOverview = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> adminByStatus = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> adminByPriority = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> adminByRole = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> adminRecentRegistrations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> adminUnitPerformance = <Map<String, dynamic>>[].obs;

  // Admin reports filter & result (optional)
  var adminDateFrom = RxnString();
  var adminDateTo = RxnString();
  final RxMap<String, dynamic> adminReportSummary = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> adminReportTopUnits = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> adminReportUserActivity = <Map<String, dynamic>>[].obs;

  // Manager
  final RxMap<String, dynamic> managerOverview = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> managerByUnit = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> managerByPriority = <Map<String, dynamic>>[].obs;
  final RxList<Tiket> managerRecentNewTikets = <Tiket>[].obs;
  final RxList<Map<String, dynamic>> managerRecentComments = <Map<String, dynamic>>[].obs;

  // Karyawan
  final RxMap<String, dynamic> karyawanOverview = <String, dynamic>{}.obs;
  final RxList<Tiket> karyawanMyTikets = <Tiket>[].obs;
  final RxList<Tiket> karyawanUnitTikets = <Tiket>[].obs;

  // Direksi
  final RxMap<String, dynamic> direksiExecutiveSummary = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> direksiPerformanceMetrics = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> direksiPriorityDistribution = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> direksiUnitPerformance = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> direksiCriticalMetrics = <String, dynamic>{}.obs;

  // User/Klien
  final RxMap<String, dynamic> userMyTiketsSummary = <String, dynamic>{}.obs;
  final RxList<Tiket> userRecentTikets = <Tiket>[].obs;
  final RxList<Map<String, dynamic>> userRecentComments = <Map<String, dynamic>>[].obs;
  
  // ================= New Dashboard Properties =================
  // Date Range for Reports
  final Rx<DateTime> reportStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> reportEndDate = DateTime.now().obs;
  
  // Report Type Selection
  final RxString selectedReportType = 'tickets'.obs;
  
  // Additional stats for improved dashboard
  final RxInt todayTickets = 0.obs;
  final RxInt managerTeamTickets = 0.obs;
  final RxInt managerPendingReview = 0.obs;
  final RxInt karyawanActiveTickets = 0.obs;
  final RxInt karyawanCompletedToday = 0.obs;
  final RxInt userOpenTickets = 0.obs;
  final RxInt userResolvedTickets = 0.obs;

  // PDF Export functionality
  final RxBool isGeneratingPdf = false.obs;


  /// Load basic dashboard data for all roles (fallback only)
  Future<void> loadBasicDashboard() async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Fallback: users count for admin
      if (user.isAdmin()) {
        try {
          final usersResponse = await apiService.get('/users');
          if (usersResponse.isOk && usersResponse.body['success'] == true) {
            final responseData = usersResponse.body['data'];
            final users = responseData is Map && responseData.containsKey('data')
                ? responseData['data'] as List
                : responseData as List;
            totalUsers.value = users.length;
          }
        } catch (e) {
          debugPrint('Error loading users (fallback): $e');
        }
      }

      // Fallback: recent tikets
      try {
        String endpoint = '/tikets';
        if (user.isUser()) {
          endpoint = '/tikets?created_by=${user.id}';
        } else if (user.isKaryawan()) {
          endpoint = '/tikets?assigned_to=${user.id}';
        }
        final tiketsResponse = await apiService.get(endpoint);
        if (tiketsResponse.isOk && tiketsResponse.body['success'] == true) {
          final responseData = tiketsResponse.body['data'];
          final tiketsData = responseData is Map && responseData.containsKey('data')
              ? responseData['data'] as List
              : responseData as List;
          final tikets = tiketsData.map((t) => Tiket.fromJson(t)).toList();
          tikets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (recentTikets.isEmpty) {
            recentTikets.value = tikets.take(5).toList();
          }
          if (totalTickets.value == 0) totalTickets.value = tikets.length;
        }
      } catch (e) {
        debugPrint('Error loading tikets (fallback): $e');
      }
    } catch (e) {
      ApiService.logError('Dashboard load error', context: 'loadBasicDashboard', stackTrace: e);
    }
  }

  /// Load dashboard data based on backend role-specific endpoints
  Future<void> loadRoleDashboard() async {
    final user = currentUser;
    if (user == null) return;

    try {
      Map<String, dynamic>? data;
      if (user.isAdmin()) {
        final res = await apiService.getAdminDashboardStats();
        if (res.isOk && res.body is Map && res.body['success'] == true) {
          data = res.body['data'] as Map<String, dynamic>;
        }
      } else if (user.isManager()) {
        final res = await apiService.getManagerDashboardStats();
        if (res.isOk && res.body is Map && res.body['success'] == true) {
          data = res.body['data'] as Map<String, dynamic>;
        }
      } else if (user.isKaryawan()) {
        final res = await apiService.getKaryawanDashboardStats();
        if (res.isOk && res.body is Map && res.body['success'] == true) {
          data = res.body['data'] as Map<String, dynamic>;
        }
      } else if (user.isDireksi()) {
        final res = await apiService.getDireksiDashboardStats();
        if (res.isOk && res.body is Map && res.body['success'] == true) {
          data = res.body['data'] as Map<String, dynamic>;
        }
      } else if (user.isUser()) {
        final res = await apiService.getUserDashboardStats();
        if (res.isOk && res.body is Map && res.body['success'] == true) {
          data = res.body['data'] as Map<String, dynamic>;
        }
      }

      if (data != null) {
        _mapBackendDashboardToState(data);
      }

      // Admin Reports (optional load when filter set)
      if (user.isAdmin() && (adminDateFrom.value != null || adminDateTo.value != null)) {
        await loadAdminReports();
      }
    } catch (e) {
      ApiService.logError('Role dashboard load error', context: 'loadRoleDashboard', stackTrace: e);
    }
  }

  void _mapBackendDashboardToState(Map<String, dynamic> data) {
    try {
      // Admin
      if (isAdmin) {
        final overview = data['overview'] as Map<String, dynamic>?;
        if (overview != null) {
          adminOverview.assignAll(overview);
          totalUsers.value = (overview['total_users'] ?? 0) as int;
          totalTickets.value = (overview['total_tikets'] ?? 0) as int;
          todayTickets.value = (overview['today_tikets'] ?? 0) as int;
        }
        // tiket_stats
        final tiketStats = data['tiket_stats'] as Map<String, dynamic>?;
        if (tiketStats != null) {
          if (tiketStats['by_status'] is List) {
            adminByStatus.assignAll(List<Map<String, dynamic>>.from(tiketStats['by_status']));
            int open = 0;
            int closed = 0;
            for (final item in adminByStatus) {
              final name = (item['nama_status'] ?? '').toString().toLowerCase();
              final count = (item['count'] ?? 0) as int;
              if (name.contains('baru') || name.contains('diproses') || name.contains('pending')) {
                open += count;
              } else if (name.contains('selesai') || name.contains('ditutup')) {
                closed += count;
              }
            }
            openTickets.value = open;
            closedTickets.value = closed;
          }
          if (tiketStats['by_priority'] is List) {
            adminByPriority.assignAll(List<Map<String, dynamic>>.from(tiketStats['by_priority']));
          }
        }
        // user_stats
        final userStats = data['user_stats'] as Map<String, dynamic>?;
        if (userStats != null) {
          if (userStats['by_role'] is List) {
            adminByRole.assignAll(List<Map<String, dynamic>>.from(userStats['by_role']));
          }
          if (userStats['recent_registrations'] is List) {
            adminRecentRegistrations.assignAll(List<Map<String, dynamic>>.from(userStats['recent_registrations']));
          }
        }
        // unit_performance
        if (data['unit_performance'] is List) {
          adminUnitPerformance.assignAll(List<Map<String, dynamic>>.from(data['unit_performance']));
        }
      }

      // Manager
      else if (isManager) {
        final overview = data['overview'] as Map<String, dynamic>?;
        if (overview != null) {
          managerOverview.assignAll(overview);
          totalTickets.value = (overview['total_tikets'] ?? 0) as int;
          openTickets.value = (overview['pending_tikets'] ?? 0) as int;
          closedTickets.value = (overview['resolved_today'] ?? 0) as int;
          managerTeamTickets.value = (overview['team_tikets'] ?? 0) as int;
          managerPendingReview.value = (overview['pending_review'] ?? 0) as int;
        }
        // tiket_distribution
        final dist = data['tiket_distribution'] as Map<String, dynamic>?;
        if (dist != null) {
          if (dist['by_unit'] is List) {
            managerByUnit.assignAll(List<Map<String, dynamic>>.from(dist['by_unit']));
          }
          if (dist['by_priority'] is List) {
            managerByPriority.assignAll(List<Map<String, dynamic>>.from(dist['by_priority']));
          }
        }
        // recent_activities
        final recent = data['recent_activities'] as Map<String, dynamic>?;
        if (recent != null) {
          if (recent['new_tikets'] is List) {
            try {
              final list = (recent['new_tikets'] as List)
                  .map((e) => Tiket.fromJson(e as Map<String, dynamic>))
                  .toList();
              managerRecentNewTikets.assignAll(list);
              recentTikets.value = list.take(5).toList();
            } catch (_) {}
          }
          if (recent['recent_comments'] is List) {
            managerRecentComments.assignAll(List<Map<String, dynamic>>.from(recent['recent_comments']));
          }
        }
      }

      // Karyawan
      else if (isKaryawan) {
        final overview = data['overview'] as Map<String, dynamic>?;
        if (overview != null) {
          karyawanOverview.assignAll(overview);
          final assigned = (overview['assigned_tikets'] ?? 0) as int;
          final unit = (overview['unit_tikets'] ?? 0) as int;
          totalTickets.value = assigned + unit;
          openTickets.value = (overview['pending_tikets'] ?? 0) as int;
          closedTickets.value = (overview['resolved_tikets'] ?? 0) as int;
          karyawanActiveTickets.value = assigned;
          karyawanCompletedToday.value = (overview['completed_today'] ?? 0) as int;
        }
        if (data['my_tikets'] is List) {
          try {
            final list = (data['my_tikets'] as List)
                .map((e) => Tiket.fromJson(e as Map<String, dynamic>))
                .toList();
            karyawanMyTikets.assignAll(list);
            recentTikets.value = list.take(5).toList();
          } catch (_) {}
        }
        if (data['unit_tikets'] is List) {
          try {
            final list = (data['unit_tikets'] as List)
                .map((e) => Tiket.fromJson(e as Map<String, dynamic>))
                .toList();
            karyawanUnitTikets.assignAll(list);
          } catch (_) {}
        }
      }

      // Direksi
      else if (isDireksi) {
        final exec = data['executive_summary'] as Map<String, dynamic>?;
        if (exec != null) {
          direksiExecutiveSummary.assignAll(exec);
          totalTickets.value = (exec['total_tikets'] ?? 0) as int;
          final resolved = (exec['resolved_tikets'] ?? 0) as int;
          closedTickets.value = resolved;
          final total = totalTickets.value;
          openTickets.value = total - resolved;
          if (openTickets.value < 0) openTickets.value = 0;
        }
        final perf = data['performance_metrics'] as Map<String, dynamic>?;
        if (perf != null) {
          direksiPerformanceMetrics.assignAll(perf);
        }
        final trends = data['trends'] as Map<String, dynamic>?;
        if (trends != null) {
          if (trends['priority_distribution'] is List) {
            direksiPriorityDistribution.assignAll(List<Map<String, dynamic>>.from(trends['priority_distribution']));
          }
        }
      }

      // User/Klien
      else if (isUser) {
        final my = data['my_tikets'] as Map<String, dynamic>?;
        if (my != null) {
          userMyTiketsSummary.assignAll(my);
          totalTickets.value = (my['total'] ?? 0) as int;
          openTickets.value = (my['open'] ?? 0) as int;
          final resolved = (my['resolved'] ?? 0) as int;
          final closed = (my['closed'] ?? 0) as int;
          closedTickets.value = resolved + closed;
          userOpenTickets.value = openTickets.value;
          userResolvedTickets.value = resolved;
        }
        if (data['recent_tikets'] is List) {
          try {
            final list = (data['recent_tikets'] as List)
                .map((e) => Tiket.fromJson(e as Map<String, dynamic>))
                .toList();
            userRecentTikets.assignAll(list);
            recentTikets.value = list.take(5).toList();
          } catch (_) {}
        }
        if (data['recent_comments'] is List) {
          userRecentComments.assignAll(List<Map<String, dynamic>>.from(data['recent_comments']));
        }
      }
    } catch (e) {
      ApiService.logError('Map backend dashboard error', context: '_mapBackendDashboardToState', stackTrace: e);
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  /// Load dashboard data based on user role
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;

      final user = currentUser;
      if (user == null) {
        showErrorSnackbar('User tidak ditemukan');
        return;
      }

      // Prioritaskan data dari endpoint dashboard backend
      await loadRoleDashboard();

      // Fallback pelengkap (jika ada yang belum terisi)
      await loadBasicDashboard();

    } catch (e) {
      handleError(e, context: 'loadDashboardData');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load Admin Reports based on current filter
  Future<void> loadAdminReports() async {
    try {
      final res = await apiService.getAdminReports(
        dateFrom: adminDateFrom.value,
        dateTo: adminDateTo.value,
      );
      if (res.isOk && res.body is Map && res.body['success'] == true) {
        final data = res.body['data'] as Map<String, dynamic>;
        adminReportSummary.assignAll({
          'period': data['period'],
          'tiket_summary': data['tiket_summary'],
        });
        if (data['top_units'] is List) {
          adminReportTopUnits.assignAll(List<Map<String, dynamic>>.from(data['top_units']));
        }
        if (data['user_activity'] is List) {
          adminReportUserActivity.assignAll(List<Map<String, dynamic>>.from(data['user_activity']));
        }
      }
    } catch (e) {
      ApiService.logError('Load admin reports error', context: 'loadAdminReports', stackTrace: e);
    }
  }

  /// Refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  /// Override BaseController refreshData method
  @override
  Future<void> refreshData() async {
    await refreshDashboard();
  }

  /// Get current user
  User? get currentUser => authService.user;

  /// Check if current user is admin
  bool get isAdmin => currentUser?.isAdmin() ?? false;

  /// Check if current user is manager
  bool get isManager => currentUser?.isManager() ?? false;
  
  /// Check if current user is karyawan
  bool get isKaryawan => currentUser?.isKaryawan() ?? false;
  
  /// Check if current user is direksi
  bool get isDireksi => currentUser?.isDireksi() ?? false;
  
  /// Check if current user is regular user/client
  bool get isUser => currentUser?.isUser() ?? false;

  /// Get greeting message based on time
  String get greetingMessage {
    final hour = DateTime.now().hour;
    final name = currentUser?.nama ?? 'User';
    
    if (hour < 12) {
      return 'Selamat Pagi, $name!';
    } else if (hour < 17) {
      return 'Selamat Siang, $name!';
    } else {
      return 'Selamat Malam, $name!';
    }
  }

  /// Get activity icon
  IconData getActivityIcon(String type) {
    switch (type) {
      case 'user_login':
      case 'login':
        return Icons.login;
      case 'user_logout':
      case 'logout':
        return Icons.logout;
      case 'ticket_created':
      case 'ticket':
        return Icons.confirmation_number;
      case 'ticket_updated':
        return Icons.edit;
      case 'ticket_resolved':
        return Icons.check_circle;
      case 'user_created':
      case 'user_add':
        return Icons.person_add;
      case 'user_updated':
        return Icons.person;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  /// Format timestamp
  String formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else {
        return '${difference.inDays} hari yang lalu';
      }
    } catch (e) {
      return 'Tidak diketahui';
    }
  }
  
  /// Update report date range
  void updateReportDateRange(DateTime start, DateTime end) {
    reportStartDate.value = start;
    reportEndDate.value = end;
    
    // Reload admin reports if admin
    if (isAdmin) {
      adminDateFrom.value = start.toIso8601String().split('T')[0];
      adminDateTo.value = end.toIso8601String().split('T')[0];
      loadAdminReports();
    }
  }
  
  /// Export report
  Future<void> exportReport(String format) async {
    try {
      isLoading.value = true;
      
      // Format date for API
      final startDate = reportStartDate.value.toIso8601String().split('T')[0];
      final endDate = reportEndDate.value.toIso8601String().split('T')[0];
      
      // Call export API based on format
      final response = await apiService.post('/reports/export', {
        'format': format,
        'type': selectedReportType.value,
        'start_date': startDate,
        'end_date': endDate,
      });
      
      if (response.isOk) {
        showSuccessSnackbar('Report exported successfully');
      }
    } catch (e) {
      handleError(e, context: 'exportReport');
    } finally {
      isLoading.value = false;
    }
  }

  /// Export dashboard to PDF (for Direksi role)
  Future<void> exportDashboardToPdf() async {
    if (isGeneratingPdf.value) return;
    
    try {
      isGeneratingPdf.value = true;
      
      // Validate that user is Direksi
      if (!isDireksi) {
        showErrorSnackbar('PDF export hanya tersedia untuk role Direksi');
        return;
      }
      
      // Extract current dashboard data from observables
      final exportData = _extractCurrentDashboardData();
      
      // Validate that we have sufficient data
      if (!_validateExportData(exportData)) {
        showErrorSnackbar('Data dashboard tidak mencukupi untuk export. Silakan refresh dashboard.');
        return;
      }
      
      // Generate PDF using current dashboard data
      final pdfBytes = await PdfExportService.generateDireksiDashboardReport(
        dashboardData: exportData,
        userName: currentUser?.nama ?? 'Unknown User',
      );
      
      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'dashboard_report_direksi_$timestamp.pdf';
      
      // Download PDF file
      await PdfExportService.downloadPdf(pdfBytes, filename);
      
      showSuccessSnackbar('Laporan dashboard berhasil di-export sebagai PDF');
    } catch (e) {
      handleError(e, context: 'exportDashboardToPdf');
      showErrorSnackbar('Gagal membuat PDF report. Silakan coba lagi.');
    } finally {
      isGeneratingPdf.value = false;
    }
  }
  
  /// Extract current dashboard data from observables
  Map<String, dynamic> _extractCurrentDashboardData() {
    return {
      'executive_summary': Map<String, dynamic>.from(direksiExecutiveSummary),
      'performance_metrics': Map<String, dynamic>.from(direksiPerformanceMetrics),
      'priority_distribution': direksiPriorityDistribution.toList(),
      'unit_performance': direksiUnitPerformance.toList(),
      'critical_metrics': Map<String, dynamic>.from(direksiCriticalMetrics),
      'recent_tickets': recentTikets.take(10).toList(),
      'export_metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'user_role': 'Direksi',
        'user_name': currentUser?.nama ?? 'Unknown',
        'data_source': 'Current Dashboard Session'
      }
    };
  }
  
  /// Validate export data availability
  bool _validateExportData(Map<String, dynamic> data) {
    // Check if essential data is available
    final summary = data['executive_summary'] as Map<String, dynamic>?;
    final hasBasicData = summary != null && summary.isNotEmpty;
    
    // Check if we have at least some ticket data
    final totalTickets = summary?['total_tikets'] ?? 0;
    final hasTicketData = totalTickets > 0;
    
    return hasBasicData || hasTicketData;
  }
}
