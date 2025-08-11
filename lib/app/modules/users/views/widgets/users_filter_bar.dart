import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/users_controller.dart';

class UsersFilterBar extends StatelessWidget {
  const UsersFilterBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        children: [
          // Role filter chips
          Obx(() => Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text('Semua'),
                selected: controller.selectedRole.value == 0,
                onSelected: (_) => controller.filterByRole(0),
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: controller.selectedRole.value == 0 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurfaceVariant,
                  fontWeight: controller.selectedRole.value == 0 
                    ? FontWeight.w600 
                    : FontWeight.w500,
                ),
                side: BorderSide(
                  color: controller.selectedRole.value == 0
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              ...controller.roles.map((role) => FilterChip(
                label: Text(role['name']),
                selected: controller.selectedRole.value == role['id'],
                onSelected: (_) => controller.filterByRole(role['id']),
                backgroundColor: colorScheme.surfaceContainerHigh,
                selectedColor: colorScheme.primaryContainer,
                checkmarkColor: colorScheme.primary,
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: controller.selectedRole.value == role['id'] 
                    ? colorScheme.onPrimaryContainer 
                    : colorScheme.onSurfaceVariant,
                  fontWeight: controller.selectedRole.value == role['id'] 
                    ? FontWeight.w600 
                    : FontWeight.w500,
                ),
                side: BorderSide(
                  color: controller.selectedRole.value == role['id']
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              )).toList(),
            ],
          )),
          
          const Spacer(),
          
          // Status filter
          Obx(() => SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: false,
                label: Text('Non-aktif'),
                icon: Icon(Icons.block, size: 18),
              ),
              ButtonSegment<bool>(
                value: true,
                label: Text('Aktif'),
                icon: Icon(Icons.check_circle_outline, size: 18),
              ),
            ],
            selected: {controller.isActiveFilter.value},
            onSelectionChanged: (Set<bool> newSelection) {
              controller.filterByActiveStatus(newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return colorScheme.primaryContainer;
                }
                return colorScheme.surfaceContainerHigh;
              }),
              foregroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return colorScheme.onPrimaryContainer;
                }
                return colorScheme.onSurfaceVariant;
              }),
              side: MaterialStateProperty.all(
                BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
          )),
          
          // Results count & refresh
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.users.value.length} / ${controller.totalUsers.value}',
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => controller.loadUsers(refresh: true),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  foregroundColor: colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}