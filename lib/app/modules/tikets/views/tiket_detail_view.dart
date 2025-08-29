import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/tikets/controllers/tiket_detail_controller.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/core/widgets/app_loading.dart';
import 'package:frontend/app/widgets/layouts/main_layout.dart';
import 'package:frontend/app/widgets/priority_badge.dart';
import 'package:intl/intl.dart';

class TiketDetailView extends GetView<TiketDetailController> {
  const TiketDetailView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return MainLayout(
      currentRoute: '/tikets/${controller.tiketId}',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: Obx(() {
          if (controller.isLoading.value && controller.tiket.value == null) {
            return const AppLoading();
          }
          
          if (controller.errorMessage.value.isNotEmpty) {
            return _buildErrorState(context);
          }
          
          final tiket = controller.tiket.value;
          if (tiket == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tiket tidak ditemukan',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadTiketDetail();
              await controller.loadKomentars();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, tiket),
                  
                  // Content
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 32 : 24),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Main Content
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _buildTiketDetailCard(context, tiket),
                                    const SizedBox(height: 24),
                                    _buildKomentarSection(context),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Sidebar
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildInfoCard(context, tiket),
                                    if (controller.canUpdateStatus() || controller.canAssignTiket()) ...[
                                      const SizedBox(height: 24),
                                      _buildActionCard(context, tiket),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildTiketDetailCard(context, tiket),
                              const SizedBox(height: 24),
                              _buildInfoCard(context, tiket),
                              if (controller.canUpdateStatus() || controller.canAssignTiket()) ...[
                                const SizedBox(height: 24),
                                _buildActionCard(context, tiket),
                              ],
                              const SizedBox(height: 24),
                              _buildKomentarSection(context),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, Tiket tiket) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 24,
        vertical: 24,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tiket.kode,
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPriorityBadge(context, tiket.prioritas),
                    const SizedBox(width: 12),
                    _buildStatusBadge(context, tiket.statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tiket.judul,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (controller.canEditTiket())
            FilledButton.tonal(
              onPressed: () => _showEditDialog(context),
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Tiket'),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTiketDetailCard(BuildContext context, Tiket tiket) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Deskripsi',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tiket.deskripsi,
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, Tiket tiket) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Informasi Tiket',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              Icons.person_outline,
              'Pembuat',
              tiket.userLabel,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today_outlined,
              'Dibuat',
              DateFormat('dd MMM yyyy, HH:mm').format(tiket.createdAt),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.update_outlined,
              'Diperbarui',
              DateFormat('dd MMM yyyy, HH:mm').format(tiket.updatedAt),
            ),
            if (tiket.unit != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.business_outlined,
                'Unit',
                tiket.unitLabel,
              ),
            ],
            if (tiket.karyawan != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.assignment_ind_outlined,
                'Ditugaskan ke',
                tiket.karyawanLabel,
              ),
            ],
            if (tiket.tanggalSelesai != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiket Selesai',
                            style: textTheme.titleSmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(tiket.tanggalSelesai!),
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionCard(BuildContext context, Tiket tiket) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUnassigned = tiket.idKaryawan == null && tiket.idUnit == null;
    final isNew = tiket.idStatus == TiketDetailController.STATUS_BARU;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Aksi Cepat',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Show assignment alert for new unassigned tickets
            if (isNew && isUnassigned && controller.canAssignTiket()) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tiket belum ditugaskan. Tugaskan ke karyawan atau unit untuk diproses.',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Assignment buttons with better UX
            if (controller.canAssignTiket()) ...[
              if (isUnassigned) ...[
                // Primary assignment actions for unassigned tickets
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _showAssignKaryawanDialog(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Tugaskan ke Karyawan'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => _showAssignUnitDialog(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Tugaskan ke Unit'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Reassignment options for already assigned tickets
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showAssignKaryawanDialog(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 8),
                        Text('Tugaskan Ulang'),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],
            
            // Status change button - only show if ticket is assigned or user can change
            if (controller.canUpdateStatus()) ...[
              if (!isUnassigned || !controller.canAssignTiket()) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: controller.getAvailableStatusTransitions().isEmpty
                        ? null
                        : () => _showStatusDialog(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          controller.getAvailableStatusTransitions().isEmpty
                              ? 'Tidak ada transisi status'
                              : 'Ubah Status',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildKomentarSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Komentar',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.komentars.length}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 20),
            
            // Add Comment Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: controller.komentarController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => controller.komentarController.clear(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      Obx(() => FilledButton.icon(
                        onPressed: controller.isSendingKomentar.value
                            ? null
                            : controller.sendKomentar,
                        icon: controller.isSendingKomentar.value
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          controller.isSendingKomentar.value
                              ? 'Mengirim...'
                              : 'Kirim',
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Comments List
            Obx(() {
              if (controller.isLoadingKomentar.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              if (controller.komentars.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada komentar',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jadilah yang pertama memberikan komentar',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: controller.komentars.map((komentar) {
                  return _buildKomentarItem(context, komentar);
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildKomentarItem(BuildContext context, Komentar komentar) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  komentar.userLabel[0].toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      komentar.userLabel,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(komentar.createdAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.canDeleteKomentar(komentar))
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  onPressed: () => _confirmDeleteKomentar(context, komentar),
                  tooltip: 'Hapus komentar',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            komentar.body,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriorityBadge(BuildContext context, String priority) {
    return PriorityBadge(priority: priority);
  }
  
  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    if (status.toLowerCase().contains('open')) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
      icon = Icons.radio_button_checked;
    } else if (status.toLowerCase().contains('progress')) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      icon = Icons.timelapse;
    } else if (status.toLowerCase().contains('resolved')) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
      icon = Icons.check_circle_outline;
    } else if (status.toLowerCase().contains('closed')) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
      icon = Icons.cancel_outlined;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
      icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: controller.loadTiketDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Tiket'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller.judulController,
                  decoration: InputDecoration(
                    labelText: 'Judul',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.deskripsiController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedPriority.value,
                  decoration: InputDecoration(
                    labelText: 'Prioritas',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rendah', child: Text('Rendah')),
                    DropdownMenuItem(value: 'sedang', child: Text('Sedang')),
                    DropdownMenuItem(value: 'tinggi', child: Text('Tinggi')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.selectedPriority.value = value;
                  },
                )),
              ],
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.updateTiket();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
  
  void _showStatusDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableStatuses = controller.getAvailableStatusTransitions();
    
    if (availableStatuses.isEmpty) {
      Get.snackbar(
        'Info',
        'Tidak ada transisi status yang tersedia untuk tiket ini',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
      return;
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('Ubah Status Tiket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show current status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Status saat ini: ${controller.getStatusLabel(controller.tiket.value?.idStatus ?? 1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Show available transitions
              ...availableStatuses.map((statusId) {
                final statusColor = controller.getStatusColor(statusId);
                final statusLabel = controller.getStatusLabel(statusId);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      child: Icon(
                        _getStatusIcon(statusId),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(statusLabel),
                    subtitle: Text(_getStatusDescription(statusId)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    onTap: () {
                      Get.back();
                      _promptUpdateStatus(context, statusId);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
  
  IconData _getStatusIcon(int statusId) {
    switch (statusId) {
      case TiketDetailController.STATUS_BARU:
        return Icons.fiber_new_outlined;
      case TiketDetailController.STATUS_DIPROSES:
        return Icons.engineering_outlined;
      case TiketDetailController.STATUS_PENDING:
        return Icons.pause_circle_outlined;
      case TiketDetailController.STATUS_SELESAI:
        return Icons.check_circle_outline;
      case TiketDetailController.STATUS_DITUTUP:
        return Icons.lock_outline;
      case TiketDetailController.STATUS_DIBATALKAN:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
  
  String _getStatusDescription(int statusId) {
    switch (statusId) {
      case TiketDetailController.STATUS_BARU:
        return 'Tandai sebagai tiket baru';
      case TiketDetailController.STATUS_DIPROSES:
        return 'Mulai proses penanganan tiket';
      case TiketDetailController.STATUS_PENDING:
        return 'Tunda sementara, menunggu informasi lebih lanjut';
      case TiketDetailController.STATUS_SELESAI:
        return 'Tandai tiket sudah selesai dikerjakan';
      case TiketDetailController.STATUS_DITUTUP:
        return 'Tutup tiket secara permanen';
      case TiketDetailController.STATUS_DIBATALKAN:
        return 'Batalkan tiket';
      default:
        return '';
    }
  }
  
  void _showAssignUnitDialog(BuildContext context) {
    int? selectedUnitId = controller.tiket.value?.idUnit;
    final komentarController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Tugaskan ke Unit'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Obx(() => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...controller.unitOptions.map((unit) {
                        return RadioListTile<int>(
                          title: Text(unit.nama),
                          subtitle: unit.description != null ? Text(unit.description!) : null,
                          value: unit.id,
                          groupValue: selectedUnitId,
                          onChanged: (value) {
                            setState(() {
                              selectedUnitId = value;
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text('Komentar (opsional):'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: komentarController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Tambahkan instruksi/komentar penugasan...',
                        ),
                      ),
                    ],
                  ),
                ));
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedUnitId != null) {
                final k = komentarController.text.trim();
                controller.assignToUnit(selectedUnitId!, komentar: k.isEmpty ? null : k);
              }
              Get.back();
            },
            child: const Text('Tugaskan'),
          ),
        ],
      ),
    );
  }
  
  void _showAssignKaryawanDialog(BuildContext context) {
    int? selectedKaryawanId = controller.tiket.value?.idKaryawan;
    final komentarController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Tugaskan ke Karyawan'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Obx(() => SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...controller.karyawanOptions.map((karyawan) {
                        return RadioListTile<int>(
                          title: Text(karyawan.nama),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NIK: ${karyawan.nik}'),
                              Text('Unit: ${karyawan.unitLabel}'),
                            ],
                          ),
                          value: karyawan.id,
                          groupValue: selectedKaryawanId,
                          onChanged: (value) {
                            setState(() {
                              selectedKaryawanId = value;
                            });
                          },
                          isThreeLine: true,
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text('Komentar (opsional):'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: komentarController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Tambahkan instruksi/komentar penugasan...',
                        ),
                      ),
                    ],
                  ),
                ));
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedKaryawanId != null) {
                final k = komentarController.text.trim();
                controller.assignToKaryawan(selectedKaryawanId!, komentar: k.isEmpty ? null : k);
              }
              Get.back();
            },
            child: const Text('Tugaskan'),
          ),
        ],
      ),
    );
  }
  
  void _promptUpdateStatus(BuildContext context, int statusId) {
    final komentarController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Perbarui Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ubah ke: ${_getStatusDescription(statusId)}'),
            const SizedBox(height: 12),
            const Text('Komentar (opsional):'),
            const SizedBox(height: 6),
            TextField(
              controller: komentarController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Tambahkan komentar perubahan status...',
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              // komentar optional; controller handles without it
              controller.updateStatus(statusId);
              Get.back();
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }
  
  void _confirmDeleteKomentar(BuildContext context, Komentar komentar) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin menghapus komentar ini?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.deleteKomentar(komentar.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
