import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/tiket_model.dart';
import '../controllers/units_controller.dart';
import 'widgets/unit_card.dart';
import 'widgets/unit_form_dialog.dart';
import '../../../widgets/layouts/main_layout.dart';

class UnitsView extends GetView<UnitsController> {
  const UnitsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MainLayout(
      currentRoute: '/units',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Manajemen Unit',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 24,
          actions: [
            FilledButton.icon(
              onPressed: () => _showUnitForm(),
              icon: const Icon(Icons.business_outlined, size: 20),
              label: const Text(
                'Tambah Unit',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
        body: Column(
          children: [
            // Search area dengan spacing yang lebih clean
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: SearchBar(
                onChanged: controller.searchUnits,
                hintText: 'Cari berdasarkan nama unit atau kategori',
                hintStyle: WidgetStateProperty.all(
                  TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                leading: Icon(
                  Icons.search_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerHigh),
                side: WidgetStateProperty.all(
                  BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
                textStyle: WidgetStateProperty.all(
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Content area dengan spacing yang lebih elegant
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                ),
                child: Obx(() {
                  if (controller.isLoading.value && controller.filteredUnits.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Memuat data unit',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mohon tunggu sebentar...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (controller.filteredUnits.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.business_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Belum ada unit',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tambahkan unit pertama untuk memulai\nmengelola organisasi Anda',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: () => _showUnitForm(),
                              icon: const Icon(Icons.business_outlined, size: 20),
                              label: const Text(
                                'Tambah Unit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    itemCount: controller.filteredUnits.length,
                    itemBuilder: (context, index) {
                      final unit = controller.filteredUnits[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: UnitCard(
                           unit: unit,
                           onEdit: () => _showUnitForm(unit),
                           onDelete: () => controller.deleteUnit(unit.id, unit.nama),
                           onManageEmployees: () => _showEmployeeManagement(unit),
                         ),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  void _showUnitForm([Unit? unit]) {
    if (unit != null) {
      controller.prepareEditForm(unit);
    } else {
      controller.clearForm();
    }
    
    Get.dialog(
      UnitFormDialog(isEdit: unit != null),
      barrierDismissible: false,
    );
  }
  
  void _showEmployeeManagement(Unit unit) {
    controller.loadEmployeesForUnit(unit.id.toString());
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kelola Karyawan - ${unit.nama}',
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih karyawan yang akan ditugaskan ke unit ini:',
                style: Get.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Obx(() {
                  if (controller.isLoadingEmployees.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: controller.availableEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = controller.availableEmployees[index];
                      final isAssigned = controller.unitEmployees.contains(employee.id.toString());
                      
                      return CheckboxListTile(
                        title: Text(employee.nama),
                        subtitle: Text(employee.email),
                        value: isAssigned,
                        onChanged: (bool? value) {
                          if (value == true) {
                            controller.assignEmployeeToUnit(unit.id.toString(), employee.id.toString());
                          } else {
                            controller.removeEmployeeFromUnit(unit.id.toString(), employee.id.toString());
                          }
                        },
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}