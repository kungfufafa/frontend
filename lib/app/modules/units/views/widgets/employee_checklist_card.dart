import 'package:flutter/material.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'package:frontend/app/modules/units/views/widgets/unit_assignment_badge.dart';

class EmployeeChecklistCard extends StatelessWidget {
  final Karyawan employee;
  final bool isAssignedToCurrentUnit;
  final VoidCallback? onToggleAssignment;
  final bool isLoading;
  final Unit? currentUnit;

  const EmployeeChecklistCard({
    super.key,
    required this.employee,
    required this.isAssignedToCurrentUnit,
    this.onToggleAssignment,
    this.isLoading = false,
    this.currentUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isAssignedToCurrentUnit ? 2 : 1,
      child: ListTile(
        leading: Checkbox(
          value: isAssignedToCurrentUnit,
          onChanged: isLoading ? null : (_) => onToggleAssignment?.call(),
          activeColor: Theme.of(context).primaryColor,
        ),
        title: Text(
          employee.nama,
          style: TextStyle(
            fontWeight: isAssignedToCurrentUnit ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    employee.unit?.nama ?? 'Unassigned',
                    style: TextStyle(
                      color: employee.unit != null ? Colors.blue[700] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.badge, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'NIK: ${employee.nik}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : UnitAssignmentBadge(
              unit: employee.unit,
              isHighlighted: isAssignedToCurrentUnit,
            ),
      ),
    );
  }
}