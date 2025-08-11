import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../controllers/users_controller.dart';
import 'widgets/user_card.dart';
import 'widgets/users_filter_bar.dart';
import 'widgets/user_form_dialog.dart';
import '../../../widgets/layouts/main_layout.dart';

class UsersView extends GetView<UsersController> {
  const UsersView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return MainLayout(
      currentRoute: '/users',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Manajemen Users',
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
              onPressed: () => _showUserForm(),
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text(
                'Tambah User',
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
                onChanged: controller.searchUsers,
                hintText: 'Cari berdasarkan nama atau email',
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
            
            // Filter bar
            const UsersFilterBar(),
            
            // Content area dengan spacing yang lebih elegant
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                ),
                child: Obx(() {
                  if (controller.isLoading.value && controller.users.value.isEmpty) {
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
                            'Memuat data users',
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
                  
                  if (controller.users.value.isEmpty) {
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
                                Icons.people_outline_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Belum ada users',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tambahkan user pertama untuk memulai\nmengelola tim Anda',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            FilledButton.icon(
                              onPressed: () => _showUserForm(),
                              icon: const Icon(Icons.person_add_outlined, size: 20),
                              label: const Text(
                                'Tambah User',
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
                    itemCount: controller.users.value.length,
                    itemBuilder: (context, index) {
                      final user = controller.users.value[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: UserCard(
                           user: user,
                           onEdit: () => _showUserForm(user),
                           onDelete: () => controller.deleteUser(user.id, user.nama),
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

  
  void _showUserForm([User? user]) {
    if (user != null) {
      controller.prepareEditForm(user);
    } else {
      controller.clearForm();
    }
    
    Get.dialog(
      UserFormDialog(isEdit: user != null),
      barrierDismissible: false,
    );
  }
}