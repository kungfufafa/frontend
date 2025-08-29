import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import '../../controllers/units_controller.dart';

class EmployeeManagementDialog extends StatelessWidget {
  final Unit unit;
  
  const EmployeeManagementDialog({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UnitsController>();
    
    // Load employees when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadEmployeesForUnit(unit.id.toString());
    });
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
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
            
            Expanded(
              child: Obx(() {
                if (controller.isLoadingEmployees.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                return Row(
                  children: [
                    // Available employees
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Karyawan Tersedia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: controller.availableEmployees.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Tidak ada karyawan tersedia',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: controller.availableEmployees.length,
                                      itemBuilder: (context, index) {
                                        final employee = controller.availableEmployees[index];
                                        return _buildEmployeeCard(
                                          employee,
                                          isAssigned: false,
                                          onTap: () => controller.assignEmployeeToUnit(unit.id.toString(), employee.id.toString()),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Arrow
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Unit employees
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Karyawan di Unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: controller.unitEmployees.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Belum ada karyawan di unit ini',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: controller.unitEmployees.length,
                                      itemBuilder: (context, index) {
                                        final employeeId = controller.unitEmployees[index];
                                        // Find the employee from available employees by ID
                                        final employee = controller.availableEmployees.firstWhereOrNull(
                                          (emp) => emp.id.toString() == employeeId,
                                        );
                                        if (employee == null) return const SizedBox.shrink();
                                        return _buildEmployeeCard(
                                          employee,
                                          isAssigned: true,
                                          onTap: () => controller.removeEmployeeFromUnit(unit.id.toString(), employee.id.toString()),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
  
  Widget _buildEmployeeCard(User employee, {required bool isAssigned, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAssigned ? Colors.green[100] : Colors.blue[100],
          child: Icon(
            Icons.person,
            color: isAssigned ? Colors.green[700] : Colors.blue[700],
          ),
        ),
        title: Text(
          employee.nama,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(employee.email),
        trailing: IconButton(
          onPressed: onTap,
          icon: Icon(
            isAssigned ? Icons.remove_circle : Icons.add_circle,
            color: isAssigned ? Colors.red : Colors.green,
          ),
          tooltip: isAssigned ? 'Keluarkan dari unit' : 'Tambahkan ke unit',
        ),
      ),
    );
  }
}