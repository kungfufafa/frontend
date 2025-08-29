import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/modules/units/views/widgets/employee_checklist_card.dart';
import 'package:frontend/app/modules/units/views/widgets/employee_filter_panel.dart';
import '../../controllers/units_controller.dart';

class EmployeeManagementDialog extends StatelessWidget {
  final Unit unit;
  
  const EmployeeManagementDialog({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UnitsController>();
    
    // Load employees with checklist status when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAllKaryawansWithUnitStatus(unit.id);
    });
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelola Karyawan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Unit: ${unit.nama}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Filter Panel
            Obx(() => EmployeeFilterPanel(
              units: controller.units,
              selectedUnitId: controller.currentManagingUnitId.value > 0 ? controller.currentManagingUnitId.value : null,
              showOnlyUnassigned: controller.showOnlyUnassigned.value,
              onUnitChanged: (unitId) {
                if (unitId != null) {
                  controller.loadAllKaryawansWithUnitStatus(unitId);
                }
              },
              onUnassignedToggle: (value) {
                controller.showOnlyUnassigned.value = value;
              },
            )),
            
            const SizedBox(height: 16),
            
            // Employee Checklist
            Expanded(
              child: Obx(() {
                if (controller.isLoadingEmployees.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading employees...'),
                      ],
                    ),
                  );
                }
                
                if (controller.currentManagingUnitId.value == 0) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Pilih unit untuk mengelola karyawan',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                final filteredEmployees = controller.filteredEmployeesForChecklist;
                
                if (filteredEmployees.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          controller.showOnlyUnassigned.value 
                            ? 'Tidak ada karyawan yang belum ditugaskan'
                            : 'Tidak ada karyawan tersedia',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with count
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Text(
                            'Daftar Karyawan (${filteredEmployees.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Centang untuk menugaskan ke unit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Employee List
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            final isAssigned = controller.employeeChecklistStatus[employee.id] ?? false;
                            
                            return EmployeeChecklistCard(
                              employee: employee,
                              isAssignedToCurrentUnit: isAssigned,
                              currentUnit: controller.units.where((u) => u.id == controller.currentManagingUnitId.value).isNotEmpty ? controller.units.where((u) => u.id == controller.currentManagingUnitId.value).first : null,
                              onToggleAssignment: () {
                                controller.toggleEmployeeUnitAssignment(
                                  employee.id,
                                  controller.currentManagingUnitId.value,
                                  !isAssigned,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Stats
                Obx(() {
                  final totalAssigned = controller.employeeChecklistStatus.values
                      .where((assigned) => assigned)
                      .length;
                  return Text(
                    'Ditugaskan: $totalAssigned karyawan',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  );
                }),
                
                // Close button
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Selesai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}