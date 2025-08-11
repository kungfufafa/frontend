import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/tikets/controllers/create_tiket_controller.dart';
import 'package:frontend/app/widgets/layouts/main_layout.dart';

class CreateTiketView extends GetView<CreateTiketController> {
  const CreateTiketView({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    
    return MainLayout(
      currentRoute: '/tikets/create',
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 24,
                vertical: 24,
              ),
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Tiket Baru',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Isi formulir di bawah untuk membuat tiket bantuan',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 24),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Form Card
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.edit_document,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Informasi Tiket',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                      
                                  // Judul Field
                                  TextFormField(
                                    controller: controller.judulController,
                                    decoration: InputDecoration(
                                      labelText: 'Judul Tiket',
                                      hintText: 'Ringkasan singkat masalah Anda',
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerLowest,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.title_rounded,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Judul tiket harus diisi';
                                      }
                                      if (value.trim().length < 5) {
                                        return 'Judul minimal 5 karakter';
                                      }
                                      if (value.trim().length > 100) {
                                        return 'Judul maksimal 100 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                      
                                  // Deskripsi Field
                                  TextFormField(
                                    controller: controller.deskripsiController,
                                    maxLines: 6,
                                    minLines: 4,
                                    decoration: InputDecoration(
                                      labelText: 'Deskripsi Masalah',
                                      hintText: 'Jelaskan masalah atau permintaan Anda secara detail...',
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerLowest,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                      alignLabelWithHint: true,
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.only(left: 12, right: 8, bottom: 80),
                                        child: Icon(
                                          Icons.description_outlined,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Deskripsi harus diisi';
                                      }
                                      if (value.trim().length < 20) {
                                        return 'Deskripsi minimal 20 karakter untuk menjelaskan masalah dengan jelas';
                                      }
                                      if (value.trim().length > 1000) {
                                        return 'Deskripsi maksimal 1000 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                      
                                  // Priority Field
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Prioritas',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Obx(() => Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.outline.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _buildPriorityOption(
                                              context,
                                              'rendah',
                                              'Rendah',
                                              'Dapat ditangani dalam beberapa hari',
                                              Icons.arrow_downward_rounded,
                                              Colors.green,
                                            ),
                                            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                            _buildPriorityOption(
                                              context,
                                              'sedang',
                                              'Sedang',
                                              'Perlu ditangani dalam 1-2 hari',
                                              Icons.remove_rounded,
                                              Colors.blue,
                                            ),
                                            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                            _buildPriorityOption(
                                              context,
                                              'tinggi',
                                              'Tinggi',
                                              'Harus ditangani hari ini',
                                              Icons.priority_high_rounded,
                                              Colors.orange,
                                            ),
                                            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                            _buildPriorityOption(
                                              context,
                                              'urgent',
                                              'Urgent',
                                              'Butuh penanganan segera',
                                              Icons.warning_rounded,
                                              Colors.red,
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                      
                          // Info Card
                          Card(
                            elevation: 0,
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Informasi Penting',
                                          style: textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tiket Anda akan segera diproses oleh tim kami. Anda akan menerima notifikasi untuk setiap pembaruan status.',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
              
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => Get.back(),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Batal'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Obx(() => FilledButton.icon(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () {
                                          if (controller.formKey.currentState!.validate()) {
                                            controller.createTiket();
                                          }
                                        },
                                  icon: controller.isLoading.value
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colorScheme.onPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                  label: Text(
                                    controller.isLoading.value
                                        ? 'Membuat Tiket...'
                                        : 'Kirim Tiket',
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriorityOption(
    BuildContext context,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = controller.selectedPriority.value == value;
    
    return InkWell(
      onTap: () => controller.selectedPriority.value = value,
      borderRadius: isSelected
          ? null
          : (value == 'rendah'
              ? const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                )
              : value == 'urgent'
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    )
                  : null),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : null,
          borderRadius: value == 'rendah'
              ? const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                )
              : value == 'urgent'
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(11),
                      bottomRight: Radius.circular(11),
                    )
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? color.withValues(alpha: 0.8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: controller.selectedPriority.value,
              onChanged: (v) => controller.selectedPriority.value = v!,
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }
}
