import 'tiket_model.dart';

// Base Dashboard Stats
class DashboardStats {
  final int totalTikets;
  final int openTikets;
  final int inProgressTikets;
  final int closedTikets;
  final int resolvedTikets;
  final Map<String, dynamic>? additionalStats;
  final List<Tiket>? recentTikets;

  DashboardStats({
    required this.totalTikets,
    required this.openTikets,
    required this.inProgressTikets,
    required this.closedTikets,
    required this.resolvedTikets,
    this.additionalStats,
    this.recentTikets,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalTikets: json["total_tikets"] ?? json["total"] ?? 0,
    openTikets: json["open_tikets"] ?? json["open"] ?? 0,
    inProgressTikets: json["in_progress_tikets"] ?? json["in_progress"] ?? 0,
    closedTikets: json["closed_tikets"] ?? json["closed"] ?? 0,
    resolvedTikets: json["resolved_tikets"] ?? json["resolved"] ?? 0,
    additionalStats: json["additional_stats"],
    recentTikets: json["recent_tikets"] != null
        ? List<Tiket>.from(json["recent_tikets"].map((x) => Tiket.fromJson(x)))
        : null,
  );

  double get completionRate {
    if (totalTikets == 0) return 0;
    return ((closedTikets + resolvedTikets) / totalTikets) * 100;
  }

  int get activeTikets => openTikets + inProgressTikets;
}

// Admin specific stats
class AdminDashboardStats extends DashboardStats {
  final int totalUsers;
  final int totalKaryawans;
  final int totalUnits;
  final Map<String, int>? tiketsByUnit;
  final Map<String, int>? tiketsByStatus;
  final Map<String, int>? tiketsByPriority;
  final List<dynamic>? reports;

  AdminDashboardStats({
    required super.totalTikets,
    required super.openTikets,
    required super.inProgressTikets,
    required super.closedTikets,
    required super.resolvedTikets,
    required this.totalUsers,
    required this.totalKaryawans,
    required this.totalUnits,
    this.tiketsByUnit,
    this.tiketsByStatus,
    this.tiketsByPriority,
    this.reports,
    super.additionalStats,
    super.recentTikets,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final base = DashboardStats.fromJson(json);
    return AdminDashboardStats(
      totalTikets: base.totalTikets,
      openTikets: base.openTikets,
      inProgressTikets: base.inProgressTikets,
      closedTikets: base.closedTikets,
      resolvedTikets: base.resolvedTikets,
      totalUsers: json["total_users"] ?? 0,
      totalKaryawans: json["total_karyawans"] ?? 0,
      totalUnits: json["total_units"] ?? 0,
      tiketsByUnit: json["tikets_by_unit"] != null
          ? Map<String, int>.from(json["tikets_by_unit"])
          : null,
      tiketsByStatus: json["tikets_by_status"] != null
          ? Map<String, int>.from(json["tikets_by_status"])
          : null,
      tiketsByPriority: json["tikets_by_priority"] != null
          ? Map<String, int>.from(json["tikets_by_priority"])
          : null,
      reports: json["reports"],
      additionalStats: base.additionalStats,
      recentTikets: base.recentTikets,
    );
  }
}

// Manager specific stats
class ManagerDashboardStats extends DashboardStats {
  final int unitTikets;
  final int assignedKaryawans;
  final Map<String, dynamic>? unitPerformance;
  final Map<String, int>? tiketsByKaryawan;

  ManagerDashboardStats({
    required super.totalTikets,
    required super.openTikets,
    required super.inProgressTikets,
    required super.closedTikets,
    required super.resolvedTikets,
    required this.unitTikets,
    required this.assignedKaryawans,
    this.unitPerformance,
    this.tiketsByKaryawan,
    super.additionalStats,
    super.recentTikets,
  });

  factory ManagerDashboardStats.fromJson(Map<String, dynamic> json) {
    final base = DashboardStats.fromJson(json);
    return ManagerDashboardStats(
      totalTikets: base.totalTikets,
      openTikets: base.openTikets,
      inProgressTikets: base.inProgressTikets,
      closedTikets: base.closedTikets,
      resolvedTikets: base.resolvedTikets,
      unitTikets: json["unit_tikets"] ?? 0,
      assignedKaryawans: json["assigned_karyawans"] ?? 0,
      unitPerformance: json["unit_performance"],
      tiketsByKaryawan: json["tikets_by_karyawan"] != null
          ? Map<String, int>.from(json["tikets_by_karyawan"])
          : null,
      additionalStats: base.additionalStats,
      recentTikets: base.recentTikets,
    );
  }
}

// Karyawan specific stats
class KaryawanDashboardStats extends DashboardStats {
  final int myTikets;
  final int completedTikets;
  final int pendingTikets;
  final List<Tiket>? myAssignedTikets;
  final double? averageResolutionTime;

  KaryawanDashboardStats({
    required super.totalTikets,
    required super.openTikets,
    required super.inProgressTikets,
    required super.closedTikets,
    required super.resolvedTikets,
    required this.myTikets,
    required this.completedTikets,
    required this.pendingTikets,
    this.myAssignedTikets,
    this.averageResolutionTime,
    super.additionalStats,
    super.recentTikets,
  });

  factory KaryawanDashboardStats.fromJson(Map<String, dynamic> json) {
    final base = DashboardStats.fromJson(json);
    return KaryawanDashboardStats(
      totalTikets: base.totalTikets,
      openTikets: base.openTikets,
      inProgressTikets: base.inProgressTikets,
      closedTikets: base.closedTikets,
      resolvedTikets: base.resolvedTikets,
      myTikets: json["my_tikets"] ?? 0,
      completedTikets: json["completed_tikets"] ?? 0,
      pendingTikets: json["pending_tikets"] ?? 0,
      myAssignedTikets: json["my_assigned_tikets"] != null
          ? List<Tiket>.from(json["my_assigned_tikets"].map((x) => Tiket.fromJson(x)))
          : null,
      averageResolutionTime: json["average_resolution_time"]?.toDouble(),
      additionalStats: base.additionalStats,
      recentTikets: base.recentTikets,
    );
  }
}

// Direksi specific stats  
class DireksiDashboardStats extends DashboardStats {
  final Map<String, dynamic>? performanceReports;
  final Map<String, dynamic>? overallMetrics;
  final List<dynamic>? departmentPerformance;

  DireksiDashboardStats({
    required super.totalTikets,
    required super.openTikets,
    required super.inProgressTikets,
    required super.closedTikets,
    required super.resolvedTikets,
    this.performanceReports,
    this.overallMetrics,
    this.departmentPerformance,
    super.additionalStats,
    super.recentTikets,
  });

  factory DireksiDashboardStats.fromJson(Map<String, dynamic> json) {
    final base = DashboardStats.fromJson(json);
    return DireksiDashboardStats(
      totalTikets: base.totalTikets,
      openTikets: base.openTikets,
      inProgressTikets: base.inProgressTikets,
      closedTikets: base.closedTikets,
      resolvedTikets: base.resolvedTikets,
      performanceReports: json["performance_reports"],
      overallMetrics: json["overall_metrics"],
      departmentPerformance: json["department_performance"],
      additionalStats: base.additionalStats,
      recentTikets: base.recentTikets,
    );
  }
}

// User/Client specific stats
class UserDashboardStats extends DashboardStats {
  final int myTikets;
  final List<Tiket>? mySubmittedTikets;

  UserDashboardStats({
    required super.totalTikets,
    required super.openTikets,
    required super.inProgressTikets,
    required super.closedTikets,
    required super.resolvedTikets,
    required this.myTikets,
    this.mySubmittedTikets,
    super.additionalStats,
    super.recentTikets,
  });

  factory UserDashboardStats.fromJson(Map<String, dynamic> json) {
    final base = DashboardStats.fromJson(json);
    return UserDashboardStats(
      totalTikets: base.totalTikets,
      openTikets: base.openTikets,
      inProgressTikets: base.inProgressTikets,
      closedTikets: base.closedTikets,
      resolvedTikets: base.resolvedTikets,
      myTikets: json["my_tikets"] ?? 0,
      mySubmittedTikets: json["my_submitted_tikets"] != null
          ? List<Tiket>.from(json["my_submitted_tikets"].map((x) => Tiket.fromJson(x)))
          : null,
      additionalStats: base.additionalStats,
      recentTikets: base.recentTikets,
    );
  }
}
