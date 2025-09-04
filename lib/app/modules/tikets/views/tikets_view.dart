import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/tikets/controllers/tikets_controller.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/core/widgets/app_loading.dart';
import 'package:frontend/app/core/widgets/app_empty_state.dart';
import 'package:frontend/app/widgets/layouts/main_layout.dart';
import 'package:frontend/app/widgets/priority_badge.dart';
import 'package:intl/intl.dart';

class TiketsView extends GetView<TiketsController> {
  const TiketsView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    
    return MainLayout(
      currentRoute: '/tikets',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: Column(
          children: [
            // Header Section
            Container(
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
              child: Column(
                children: [
                  // Title Bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 24,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Text(
                                controller.isManager ? 'Kelola Tiket' : 
                                controller.isKaryawan ? 'Tiket Ditugaskan' :
                                controller.isUser ? 'Tiket Saya' : 'Manajemen Tiket',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              )),
                              const SizedBox(height: 4),
                              Obx(() => Text(
                                'Total ${controller.totalItems.value} tiket',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => controller.loadTikets(refresh: true),
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Refresh',
                            ),
                            const SizedBox(width: 8),
                            // Create button for Admin, Manager, Karyawan, and User
                            Obx(() => 
                              controller.showCreateButton || controller.isUser
                                ? FilledButton.icon(
                                    onPressed: controller.navigateToCreate,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Buat Tiket'),
                                  )
                                : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Filter Section
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: _buildFilterSection(isDesktop, isTablet),
                  ),
                ],
              ),
            ),
            
            // Content Area
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 24,
                  vertical: 24,
                ),
                child: Obx(() {
                  if (controller.isLoading.value && controller.tikets.isEmpty) {
                    return const AppLoading();
                  }
                  
                  if (controller.errorMessage.value.isNotEmpty) {
                    return _buildErrorState();
                  }
                  
                  if (controller.filteredTikets.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return _buildTiketGrid(isDesktop, isTablet);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterSection(bool isDesktop, bool isTablet) {
    // Simplified filter for User/Klien - only search and date
    if (controller.isUser) {
      if (isDesktop) {
        return Row(
          children: [
            // Search Field
            Expanded(
              flex: 3,
              child: _buildSearchField(),
            ),
            const SizedBox(width: 16),
            // Date From
            Expanded(
              flex: 2,
              child: _buildDatePicker('Dari Tanggal', controller.dateFrom.value, 
                (date) => controller.setDateFrom(date)),
            ),
            const SizedBox(width: 16),
            // Date To
            Expanded(
              flex: 2,
              child: _buildDatePicker('Sampai Tanggal', controller.dateTo.value,
                (date) => controller.setDateTo(date)),
            ),
            const SizedBox(width: 16),
            // Clear Filters Button
            FilledButton.tonal(
              onPressed: controller.clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            _buildSearchField(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker('Dari', controller.dateFrom.value,
                    (date) => controller.setDateFrom(date)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePicker('Sampai', controller.dateTo.value,
                    (date) => controller.setDateTo(date)),
                ),
              ],
            ),
          ],
        );
      }
    }
    
    // Full filter for Admin, Manager, and Karyawan
    if (isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: _buildSearchField(),
              ),
              const SizedBox(width: 16),
              // Status Filter
              Expanded(
                flex: 2,
                child: _buildStatusDropdown(),
              ),
              const SizedBox(width: 16),
              // Priority Filter
              Expanded(
                flex: 2,
                child: _buildPriorityDropdown(),
              ),
              if (controller.isAdmin || controller.isManager) ...[
                const SizedBox(width: 16),
                // Unit Filter
                Expanded(
                  flex: 2,
                  child: _buildUnitDropdown(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date From
              Expanded(
                child: _buildDatePicker('Dari Tanggal', controller.dateFrom.value, 
                  (date) => controller.setDateFrom(date)),
              ),
              const SizedBox(width: 16),
              // Date To
              Expanded(
                child: _buildDatePicker('Sampai Tanggal', controller.dateTo.value,
                  (date) => controller.setDateTo(date)),
              ),
              const SizedBox(width: 16),
              // Clear Filters Button
              FilledButton.tonal(
                onPressed: controller.clearFilters,
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatusDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildPriorityDropdown()),
            ],
          ),
          if (controller.isAdmin || controller.isManager) ...[
            const SizedBox(height: 12),
            _buildUnitDropdown(),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker('Dari', controller.dateFrom.value,
                  (date) => controller.setDateFrom(date)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePicker('Sampai', controller.dateTo.value,
                  (date) => controller.setDateTo(date)),
              ),
            ],
          ),
        ],
      );
    }
  }
  
  Widget _buildSearchField() {
    return TextField(
      onChanged: controller.setSearchQuery,
      decoration: InputDecoration(
        hintText: 'Cari nomor tiket, deskripsi, nama user, atau email...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Get.theme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
  
  Widget _buildUnitDropdown() {
    return Obx(() => DropdownButtonFormField<int>(
      value: controller.selectedUnitId.value == 0 ? null : controller.selectedUnitId.value,
      decoration: InputDecoration(
        labelText: 'Unit',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Semua Unit'),
        ),
        ...controller.unitOptions.map((unit) {
          return DropdownMenuItem(
            value: unit.id,
            child: Text(unit.nama),
          );
        }),
      ],
      onChanged: (value) {
        controller.setUnitFilter(value ?? 0);
      },
    ));
  }
  
  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
    final textController = TextEditingController(
      text: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate) : '',
    );
    
    return TextField(
      controller: textController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: selectedDate != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => onDateSelected(null),
            )
          : const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: Get.context!,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
    );
  }
  
  Widget _buildStatusDropdown() {
    return Obx(() => DropdownButtonFormField<int>(
      value: controller.selectedStatusId.value == 0 ? null : controller.selectedStatusId.value,
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Semua Status'),
        ),
        ...controller.statusOptions.map((status) {
          return DropdownMenuItem(
            value: status.id,
            child: Text(status.nama),
          );
        }),
      ],
      onChanged: (value) {
        controller.setStatusFilter(value ?? 0);
      },
    ));
  }
  
  Widget _buildPriorityDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
      value: controller.selectedPriority.value,
      decoration: InputDecoration(
        labelText: 'Prioritas',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: controller.priorityOptions.map((option) {
        return DropdownMenuItem(
          value: option['value'],
          child: Text(option['label']!),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) controller.setPriorityFilter(value);
      },
    ));
  }
  
  Widget _buildErrorState() {
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
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => controller.loadTikets(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: AppEmptyState(
          icon: Icons.confirmation_number_outlined,
          title: 'Belum Ada Tiket',
          subtitle: controller.searchQuery.value.isNotEmpty 
            ? 'Tidak ada tiket yang sesuai dengan pencarian Anda'
            : 'Mulai buat tiket pertama Anda',
          action: controller.searchQuery.value.isEmpty && 
                  (controller.isUser || controller.isAdmin || controller.isManager)
            ? FilledButton.icon(
                onPressed: controller.navigateToCreate,
                icon: const Icon(Icons.add),
                label: const Text('Buat Tiket Baru'),
              )
            : null,
        ),
      ),
    );
  }
  
  Widget _buildTiketGrid(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
    
    return RefreshIndicator(
      onRefresh: () => controller.loadTikets(refresh: true),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: isDesktop ? 1.5 : (isTablet ? 1.4 : 1.3),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: controller.filteredTikets.length + 
            (controller.currentPage.value < controller.lastPage.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.filteredTikets.length) {
            return _buildLoadMoreButton();
          }
          
          final tiket = controller.filteredTikets[index];
          return _buildTiketCard(tiket);
        },
      ),
    );
  }
  
  Widget _buildTiketCard(Tiket tiket) {
    final colorScheme = Get.theme.colorScheme;
    final textTheme = Get.textTheme;
    final isUnassigned = tiket.idKaryawan == null && tiket.idUnit == null;
    final isNew = tiket.idStatus == 1; // STATUS_BARU
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnassigned && isNew 
              ? Colors.amber.shade300
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isUnassigned && isNew ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => controller.navigateToDetail(tiket),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show unassigned alert badge for admin/manager
              if (isUnassigned && isNew && (controller.isAdmin || controller.isManager)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Belum Ditugaskan',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tiket.kode,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tiket.judul,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildPriorityBadge(tiket.prioritas),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Expanded(
                child: Text(
                  tiket.deskripsi,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status and Info
              Column(
                children: [
                  Row(
                    children: [
                      _buildStatusChip(tiket.statusLabel),
                      const SizedBox(width: 8),
                      if (tiket.unit != null)
                        Expanded(
                          child: _buildInfoChip(
                            Icons.business_outlined,
                            tiket.unitLabel,
                            colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.person_outline,
                          tiket.karyawan != null 
                            ? tiket.karyawanLabel 
                            : 'Belum ditugaskan',
                          tiket.karyawan != null 
                            ? colorScheme.tertiary
                            : Colors.grey,
                        ),
                      ),
                      if (tiket.komentarCount != null && tiket.komentarCount! > 0) ...[
                        const SizedBox(width: 8),
                        _buildCommentCount(tiket.komentarCount!),
                      ],
                    ],
                  ),
                ],
              ),
              
              // Footer with date and actions
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(tiket.createdAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Unit management actions for Admin and Manager
                  if (controller.isManager || controller.isAdmin) ...[
                    if (controller.canEditUnit(tiket))
                      IconButton(
                        icon: Icon(
                          Icons.business,
                          size: 18,
                          color: Colors.blue.shade600,
                        ),
                        onPressed: () => _showQuickUnitEditDialog(tiket),
                        tooltip: 'Edit Unit',
                      ),
                    if (controller.canReassignTicket(tiket))
                      IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          size: 18,
                          color: Colors.orange.shade600,
                        ),
                        onPressed: () => _showQuickReassignDialog(tiket),
                        tooltip: 'Tugaskan Ulang',
                      ),
                  ],
                  if (controller.canDeleteTiket(tiket))
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDelete(tiket),
                      tooltip: 'Hapus tiket',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPriorityBadge(String priority) {
    return PriorityBadge(priority: priority);
  }
  
  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    
    if (status.toLowerCase().contains('open')) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade700;
    } else if (status.toLowerCase().contains('progress')) {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else if (status.toLowerCase().contains('resolved')) {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (status.toLowerCase().contains('closed')) {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    } else {
      bgColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCommentCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 12,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadMoreButton() {
    return Center(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Get.theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
        ),
        child: InkWell(
          onTap: controller.isLoadingMore.value ? null : controller.loadMoreTikets,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() => controller.isLoadingMore.value
                  ? const CircularProgressIndicator()
                  : Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Get.theme.colorScheme.primary,
                    ),
                ),
                const SizedBox(height: 16),
                Text(
                  controller.isLoadingMore.value
                    ? 'Memuat...'
                    : 'Muat Lebih Banyak',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Get.theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _confirmDelete(Tiket tiket) {
    // Get role-specific message
    String warningMessage;
    String additionalWarning = '';
    
  if (controller.isManager || controller.isAdmin) {
      String roleText = controller.isAdmin ? 'Admin' : 'Manager';
      warningMessage = 'Sebagai $roleText, Anda dapat menghapus tiket apapun. Apakah Anda yakin ingin menghapus tiket ini?';
  if (controller.isCompletedTicket(tiket)) {
        additionalWarning = 'Tiket ini sudah selesai dan dapat dihapus.';
      }
    } else if (controller.isKaryawan) {
      if (tiket.idUser == controller.currentUser?.id) {
        warningMessage = 'Anda hanya dapat menghapus tiket yang Anda buat sendiri. Apakah Anda yakin ingin menghapus tiket ini?';
      } else {
        // This shouldn't happen due to UI permissions, but just in case
        warningMessage = 'Anda tidak memiliki izin untuk menghapus tiket ini.';
      }
    } else {
      warningMessage = 'Apakah Anda yakin ingin menghapus tiket ini?';
    }
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi Hapus'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(warningMessage),
            if (additionalWarning.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                additionalWarning,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tiket.kode,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tiket.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              controller.deleteTiket(tiket.id);
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
  
  void _showQuickUnitEditDialog(Tiket tiket) {
    int? selectedUnitId = tiket.idUnit;
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            const Text('Edit Unit Tiket'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiket: ${tiket.kode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tiket.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Unit:'),
                  const SizedBox(height: 8),
                  Obx(() => Column(
                    children: [
                      // No unit option
                      RadioListTile<int?>(
                        title: const Text('Tidak ada unit'),
                        value: null,
                        groupValue: selectedUnitId,
                        onChanged: (value) {
                          setState(() {
                            selectedUnitId = value;
                          });
                        },
                      ),
                      // Available units
                      ...controller.availableUnits.map((unit) {
                        return RadioListTile<int>(
                          title: Text(unit.nama),
                          subtitle: unit.description != null 
                            ? Text(unit.description!) 
                            : null,
                          value: unit.id,
                          groupValue: selectedUnitId,
                          onChanged: (value) {
                            setState(() {
                              selectedUnitId = value;
                            });
                          },
                        );
                      }),
                    ],
                  )),
                  const SizedBox(height: 12),
                  const Text('Alasan (opsional):'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Alasan perubahan unit...',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedUnitId != null) {
                final unit = controller.availableUnits
                    .firstWhere((u) => u.id == selectedUnitId);
                final reason = reasonController.text.trim();
                controller.updateTicketUnit(
                  tiket, 
                  unit, 
                  reason: reason.isEmpty ? null : reason
                );
              }
              Get.back();
            },
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }
  
  void _showQuickReassignDialog(Tiket tiket) {
    User? selectedMember;
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Tugaskan Ulang ke Tim'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiket: ${tiket.kode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tiket.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Anggota Tim:'),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (controller.teamMembers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Tidak ada anggota tim tersedia',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      );
                    }
                    
                    return Column(
                      children: controller.teamMembers.map((member) {
                        return RadioListTile<User>(
                          title: Text(member.nama),
                          subtitle: Text(member.email),
                          value: member,
                          groupValue: selectedMember,
                          onChanged: (value) {
                            setState(() {
                              selectedMember = value;
                            });
                          },
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Text('Alasan penugasan (opsional):'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Alasan penugasan ulang...',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (selectedMember != null) {
                final reason = reasonController.text.trim();
                controller.reassignTicketToTeamMember(
                  tiket, 
                  selectedMember!, 
                  reason: reason.isEmpty ? null : reason
                );
              }
              Get.back();
            },
            child: const Text('Tugaskan'),
          ),
        ],
      ),
    );
  }
}
