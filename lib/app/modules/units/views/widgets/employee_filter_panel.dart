import 'package:flutter/material.dart';
import 'package:frontend/app/data/models/tiket_model.dart';

class EmployeeFilterPanel extends StatelessWidget {
  final List<Unit> units;
  final int? selectedUnitId;
  final bool showOnlyUnassigned;
  final Function(int?) onUnitChanged;
  final Function(bool) onUnassignedToggle;
  
  const EmployeeFilterPanel({
    super.key,
    required this.units,
    this.selectedUnitId,
    required this.showOnlyUnassigned,
    required this.onUnitChanged,
    required this.onUnassignedToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Manage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedUnitId,
                    decoration: const InputDecoration(
                      labelText: 'Select Unit to Manage',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: units.map((unit) => DropdownMenuItem(
                      value: unit.id,
                      child: Text(unit.nama),
                    )).toList(),
                    onChanged: onUnitChanged,
                  ),
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('Show only unassigned'),
                  selected: showOnlyUnassigned,
                  onSelected: onUnassignedToggle,
                  avatar: Icon(
                    showOnlyUnassigned ? Icons.filter_alt : Icons.filter_alt_outlined,
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}