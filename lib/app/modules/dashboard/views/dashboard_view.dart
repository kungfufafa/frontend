import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/widgets/layouts/main_layout.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return MainLayout(
      currentRoute: '/dashboard',
      child: Container(
        color: colorScheme.surfaceContainerLowest,
        child: Column(
          children: [
            // Custom Header - Consistent with main layout style
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() => Text(
                      controller.greetingMessage,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    )),
                  ),
                  IconButton(
                  onPressed: controller.refreshDashboard,
                  icon: Icon(
                    Icons.refresh,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Refresh Dashboard',
                ),
                // PDF Export button for Direksi role only
                Obx(() {
                  if (controller.isDireksi) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton.icon(
                        onPressed: controller.isGeneratingPdf.value 
                            ? null 
                            : controller.exportDashboardToPdf,
                        icon: controller.isGeneratingPdf.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.file_download,
                                size: 18,
                                color: colorScheme.onPrimary,
                              ),
                        label: Text(
                          controller.isGeneratingPdf.value ? 'Generating...' : 'Download PDF',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                ],
              ),
            ),
            // Body Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: controller.refreshDashboard,
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        _buildStatsSection(context),
                        
                        const SizedBox(height: 32),
                        
                        // Role-specific sections
                        if (controller.isAdmin) _buildAdminSections(context),
                        if (controller.isManager) _buildManagerSections(context),
                        if (controller.isKaryawan) _buildKaryawanSections(context),
                        if (controller.isDireksi) _buildDireksiSections(context),
                        if (controller.isUser) _buildUserSections(context),
                        
                        const SizedBox(height: 32),
                        
                        // Recent Tikets
                        _buildRecentTiketsCard(context),
                        
                        const SizedBox(height: 32),
                        
                        // Quick Actions
                        _buildQuickActionsSection(context),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        Obx(() {
          final cards = <Widget>[];
          
          // Show user count only for admin
          if (controller.isAdmin && controller.totalUsers.value > 0) {
            cards.add(
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Users',
                  controller.totalUsers,
                  Icons.people_outline,
                  Colors.blue,
                ),
              ),
            );
            cards.add(const SizedBox(width: 16));
          }
          
          // Show tiket stats for all
          cards.addAll([
            Expanded(
              child: _buildStatCard(
                context,
                'Total Tiket',
                controller.totalTickets,
                Icons.confirmation_number_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Tiket Aktif',
                controller.openTickets,
                Icons.pending_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Tiket Selesai',
                controller.closedTickets,
                Icons.check_circle_outline,
                Colors.grey,
              ),
            ),
          ]);
          
          return Row(children: cards);
        }),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    RxInt value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => Text(
            value.value.toString(),
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          )),
          const SizedBox(height: 8),
          Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSections(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget card(String title, Widget child) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            'Admin Dashboard',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        // Admin Reports filter with Date Picker
        card(
          'Laporan Admin',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Date From Picker
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: controller.adminDateFrom.value != null
                              ? DateTime.parse(controller.adminDateFrom.value!)
                              : DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: colorScheme.copyWith(
                                  primary: colorScheme.primary,
                                  onPrimary: colorScheme.onPrimary,
                                  surface: colorScheme.surface,
                                  onSurface: colorScheme.onSurface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          controller.adminDateFrom.value = picked.toIso8601String().split('T')[0];
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dari Tanggal',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() => Text(
                                    controller.adminDateFrom.value ?? 'Pilih tanggal',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: controller.adminDateFrom.value != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Date To Picker
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: controller.adminDateTo.value != null
                              ? DateTime.parse(controller.adminDateTo.value!)
                              : DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: colorScheme.copyWith(
                                  primary: colorScheme.primary,
                                  onPrimary: colorScheme.onPrimary,
                                  surface: colorScheme.surface,
                                  onSurface: colorScheme.onSurface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          controller.adminDateTo.value = picked.toIso8601String().split('T')[0];
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sampai Tanggal',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() => Text(
                                    controller.adminDateTo.value ?? 'Pilih tanggal',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: controller.adminDateTo.value != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Load Button
                  FilledButton.icon(
                    onPressed: controller.loadAdminReports,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Muat Laporan'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.adminReportSummary.isEmpty && controller.adminReportTopUnits.isEmpty && controller.adminReportUserActivity.isEmpty) {
                  return Text('Belum ada data laporan', style: textTheme.bodyMedium);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.adminReportSummary.isNotEmpty)
                      Text('Periode: ${controller.adminReportSummary['period']}', style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    if (controller.adminReportTopUnits.isNotEmpty)
                      _buildSimpleList(
                        context,
                        title: 'Top Units',
                        items: controller.adminReportTopUnits.map((e) => '${e['nama_unit'] ?? e['name'] ?? 'Unit'} — ${e['tikets_count'] ?? e['count'] ?? 0} tiket').toList(),
                      ),
                    if (controller.adminReportUserActivity.isNotEmpty)
                      _buildSimpleList(
                        context,
                        title: 'User Activity',
                        items: controller.adminReportUserActivity.map((e) => '${e['nama'] ?? e['name'] ?? 'User'} — ${e['tikets_count'] ?? 0} tiket').toList(),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        // By Status & Priority - Grid Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 800;
            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: card(
                      'Distribusi Status',
                      Obx(() => _buildKeyCountList(
                            context,
                            controller.adminByStatus.map((e) => {'label': e['nama_status'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                          )),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: card(
                      'Distribusi Prioritas',
                      Obx(() => _buildKeyCountList(
                            context,
                            controller.adminByPriority.map((e) => {'label': e['prioritas'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                          )),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  card(
                    'Distribusi Status',
                    Obx(() => _buildKeyCountList(
                          context,
                          controller.adminByStatus.map((e) => {'label': e['nama_status'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                        )),
                  ),
                  card(
                    'Distribusi Prioritas',
                    Obx(() => _buildKeyCountList(
                          context,
                          controller.adminByPriority.map((e) => {'label': e['prioritas'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                        )),
                  ),
                ],
              );
            }
          },
        ),
        // User stats & Unit performance - Grid Layout
        LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 800;
            if (isWideScreen) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: card(
                      'User by Role',
                      Obx(() => _buildKeyCountList(
                            context,
                            controller.adminByRole.map((e) => {'label': e['role_name'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                          )),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: card(
                      'Registrasi Terbaru',
                      Obx(() => _buildSimpleList(
                            context,
                            items: controller.adminRecentRegistrations
                                .map((e) => "${e['nama'] ?? '-'} • ${e['email'] ?? ''}")
                                .toList(),
                          )),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  card(
                    'User by Role',
                    Obx(() => _buildKeyCountList(
                          context,
                          controller.adminByRole.map((e) => {'label': e['role_name'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                        )),
                  ),
                  card(
                    'Registrasi Terbaru',
                    Obx(() => _buildSimpleList(
                          context,
                          items: controller.adminRecentRegistrations
                              .map((e) => "${e['nama'] ?? '-'} • ${e['email'] ?? ''}")
                              .toList(),
                        )),
                  ),
                ],
              );
            }
          },
        ),
        card(
          'Performa Unit',
          Obx(() => _buildSimpleList(
                context,
                items: controller.adminUnitPerformance
                    .map((e) => "${e['nama_unit'] ?? '-'} — tiket: ${e['tikets_count'] ?? 0}, karyawan: ${e['karyawans_count'] ?? 0}")
                    .toList(),
              )),
        ),
      ],
    );
  }

  Widget _buildManagerSections(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget card(String title, Widget child) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: card(
            'Distribusi per Unit',
            Obx(() => _buildKeyCountList(
                  context,
                  controller.managerByUnit.map((e) => {'label': e['nama_unit'] ?? '-', 'count': e['tikets_count'] ?? e['count'] ?? 0}).toList(),
                )),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: card(
            'Distribusi Prioritas',
            Obx(() => _buildKeyCountList(
                  context,
                  controller.managerByPriority.map((e) => {'label': e['prioritas'] ?? '-', 'count': e['count'] ?? 0}).toList(),
                )),
          ),
        ),
      ]),
      card(
        'Komentar Terbaru',
        Obx(() => _buildSimpleList(
              context,
              items: controller.managerRecentComments
                  .map((e) => "${e['user']?['nama'] ?? e['user_name'] ?? 'User'} • tiket #${e['tiket_id'] ?? '-'}")
                  .toList(),
            )),
      )
    ]);
  }

  Widget _buildKaryawanSections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimpleList(
          context,
          title: 'Tiket Saya (terbaru)',
          items: controller.karyawanMyTikets.map((t) => '${t.judul} • ${t.statusString}').toList(),
        ),
        const SizedBox(height: 12),
        _buildSimpleList(
          context,
          title: 'Tiket Unit (belum ditugaskan)',
          items: controller.karyawanUnitTikets.map((t) => '${t.judul} • ${t.statusString}').toList(),
        ),
      ],
    );
  }

  Widget _buildDireksiSections(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSimpleList(
        context,
        title: 'Distribusi Prioritas',
        items: controller.direksiPriorityDistribution.map((e) => '${e['prioritas'] ?? '-'} — ${e['count'] ?? 0}').toList(),
      ),
    ]);
  }

  Widget _buildUserSections(BuildContext context) {
    final summary = controller.userMyTiketsSummary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (summary.isNotEmpty)
        _buildSimpleList(
          context,
          title: 'Ringkasan Tiket Saya',
          items: [
            'Total: ${summary['total'] ?? 0}',
            'Open: ${summary['open'] ?? 0}',
            'Resolved: ${summary['resolved'] ?? 0}',
            'Closed: ${summary['closed'] ?? 0}',
          ],
        ),
      const SizedBox(height: 12),
      _buildSimpleList(
        context,
        title: 'Tiket Terakhir',
        items: controller.userRecentTikets.map((t) => '${t.judul} • ${t.statusString}').toList(),
      ),
    ]);
  }

  Widget _buildSimpleList(BuildContext context, {String? title, required List<String> items}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        if (items.isEmpty)
          Text('Tidak ada data', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))
        else
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(e, style: textTheme.bodyMedium),
              )),
      ]),
    );
  }

  Widget _buildKeyCountList(BuildContext context, List<Map<String, dynamic>> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: items.isEmpty
          ? [
              Text('Tidak ada data', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ]
          : items
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          e['label']?.toString() ?? '-',
                          style: textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        (e['count'] ?? 0).toString(),
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildRecentTiketsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiket Terbaru',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed('/tikets'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.recentTikets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada tiket',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentTikets.length > 5 ? 5 : controller.recentTikets.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tiket = controller.recentTikets[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tiket.statusString).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(tiket.statusString),
                      color: _getStatusColor(tiket.statusString),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tiket.judul,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Unit: ${tiket.unitLabel} • Prioritas: ${tiket.prioritas}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () => Get.toNamed('/tikets/${tiket.id}'),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'baru':
        return Colors.blue;
      case 'in_progress':
      case 'proses':
        return Colors.orange;
      case 'closed':
      case 'selesai':
        return Colors.green;
      case 'cancelled':
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'baru':
        return Icons.radio_button_checked;
      case 'in_progress':
      case 'proses':
        return Icons.autorenew;
      case 'closed':
      case 'selesai':
        return Icons.check_circle;
      case 'cancelled':
      case 'dibatalkan':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Obx(() {
      final cards = <Widget>[];
      
      // Admin - Users management
      if (controller.isAdmin) {
        cards.add(
          Expanded(
            child: _buildQuickActionCard(
              context,
              'Manage Users',
              'Kelola pengguna sistem',
              Icons.people_outline,
              Colors.blue,
              () => Get.toNamed('/users'),
            ),
          ),
        );
        cards.add(const SizedBox(width: 16));
      }
      
      // Manager, Karyawan, User/Klien - Tiket management
      if (controller.isManager || controller.isKaryawan || controller.isUser) {
        cards.add(
          Expanded(
            child: _buildQuickActionCard(
              context,
              'Tiket',
              'Kelola tiket support',
              Icons.confirmation_number_outlined,
              Colors.purple,
              () => Get.toNamed('/tikets'),
            ),
          ),
        );
        cards.add(const SizedBox(width: 16));
      }
      
      // All roles - Profile
      cards.add(
        Expanded(
          child: _buildQuickActionCard(
            context,
            'View Profile',
            'Lihat profil Anda',
            Icons.person_outline,
            Colors.green,
            () => Get.toNamed('/profile'),
          ),
        ),
      );
      
      if (cards.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(children: cards),
        ],
      );
    });
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}