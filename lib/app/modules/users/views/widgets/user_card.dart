import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import '../../controllers/users_controller.dart';
import 'karyawan_detail_card.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  
  const UserCard({
    super.key, 
    required this.user,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Get karyawan data if user is karyawan
    final Karyawan? karyawan = user.isKaryawan() ? controller.karyawanMap[user.id] : null;
    
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
            // Avatar dengan gradient
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
                child: Text(
                  user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'U',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 20),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    user.nama,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      fontSize: 18,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Email
                  Text(
                    user.email,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Role and Status
                  Row(
                    children: [
                      // Role dengan styling yang lebih clean
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.roleName).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(user.roleName),
                              size: 16,
                              color: _getRoleColor(user.roleName),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.roleName ?? 'Unknown',
                              style: textTheme.labelMedium?.copyWith(
                                color: _getRoleColor(user.roleName),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      // Status dengan styling yang lebih modern
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(user.isActive).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getStatusColor(user.isActive),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(user.isActive),
                              style: textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(user.isActive),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tanggal bergabung
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bergabung: ${_formatDate(user.createdAt.toString())}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Show Karyawan Detail if user is Karyawan
                  if (user.isKaryawan() && karyawan != null)
                    KaryawanDetailCard(karyawan: karyawan),
                  
                  // Show loading indicator for karyawan data
                  if (user.isKaryawan() && karyawan == null)
                    Obx(() => controller.isLoadingKaryawan.value
                        ? Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    ),
                 ],
               ),
             ),
             
             const SizedBox(width: 16),
             
             // Action buttons dengan Material 3 design
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 // Edit button
                 Container(
                   width: 40,
                   height: 40,
                   decoration: BoxDecoration(
                     color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Edit User',
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                    ),
                 ),
                 
                 const SizedBox(width: 8),
                 
                 // Delete button
                 Container(
                   width: 40,
                   height: 40,
                   decoration: BoxDecoration(
                     color: colorScheme.errorContainer.withValues(alpha: 0.5),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Hapus User',
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                    ),
                 ),
               ],
             ),
           ],
         ),
       ),
     );
   }
  
  Color _getRoleColor(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return const Color(0xFF6750A4); // Material 3 Purple
      case 'manager':
        return const Color(0xFF1976D2); // Material 3 Blue
      case 'karyawan':
      case 'employee':
        return const Color(0xFF388E3C); // Material 3 Green
      case 'direksi':
      case 'director':
        return const Color(0xFFFF8F00); // Material 3 Orange
      case 'user':
      case 'klien':
      case 'client':
        return const Color(0xFF616161); // Material 3 Grey
      default:
        return const Color(0xFF616161); // Material 3 Grey
    }
  }
  
  IconData _getRoleIcon(String? roleName) {
    switch (roleName?.toLowerCase()) {
      case 'administrator':
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'karyawan':
      case 'employee':
        return Icons.work;
      case 'direksi':
      case 'director':
        return Icons.business;
      case 'user':
      case 'klien':
      case 'client':
        return Icons.person;
      default:
        return Icons.person;
    }
  }
  
  Color _getStatusColor(bool isActive) {
    if (isActive) {
      return const Color(0xFF4CAF50); // Green for active
    } else {
      return const Color(0xFFFF5722); // Red for inactive
    }
  }
  
  String _getStatusText(bool isActive) {
     if (isActive) {
       return 'Aktif';
     } else {
       return 'Non-aktif';
     }
   }
   
  String _formatDate(dynamic dateString) {
      if (dateString == null) return 'Tidak diketahui';
      
      try {
        DateTime date = DateTime.parse(dateString.toString());
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return 'Tidak diketahui';
      }
    }
    
   // Removed unused private helpers
  }