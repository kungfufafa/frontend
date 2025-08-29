import 'package:flutter/material.dart';
import 'package:frontend/app/data/models/tiket_model.dart';

class UnitCard extends StatelessWidget {
  final Unit unit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageEmployees;
  
  const UnitCard({
    super.key, 
    required this.unit,
    this.onEdit,
    this.onDelete,
    this.onManageEmployees,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon dengan gradient
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.business_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Unit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    unit.nama,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      unit.kategoriUnit,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (unit.description?.isNotEmpty == true)
                    Text(
                      unit.description!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Manage employees button
                if (onManageEmployees != null)
                  IconButton(
                    onPressed: onManageEmployees,
                    icon: Icon(
                      Icons.people_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    tooltip: 'Kelola Karyawan',
                  ),
                
                const SizedBox(height: 8),
                
                // Edit button
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    tooltip: 'Edit Unit',
                  ),
                
                const SizedBox(height: 8),
                
                // Delete button
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    tooltip: 'Hapus Unit',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}