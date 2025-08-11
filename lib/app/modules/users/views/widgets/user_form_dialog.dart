import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/users_controller.dart';

class UserFormDialog extends StatelessWidget {
  final bool isEdit;
  
  const UserFormDialog({Key? key, required this.isEdit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UsersController>();
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEdit ? Icons.edit : Icons.add,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Edit User' : 'Tambah User Baru',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form fields
            Form(
              child: Column(
                children: [
                  // Nama field
                  TextFormField(
                    controller: controller.namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email field
                  TextFormField(
                    controller: controller.emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan alamat email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: controller.passwordController,
                    decoration: InputDecoration(
                      labelText: isEdit ? 'Password Baru (Opsional)' : 'Password',
                      hintText: isEdit ? 'Kosongkan jika tidak ingin mengubah' : 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Role dropdown
                  Obx(() => DropdownButtonFormField<int>(
                    value: controller.selectedRoleId.value,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: const Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: controller.roles.map((role) => DropdownMenuItem<int>(
                      value: role['id'] as int,
                      child: Text(role['name'] as String),
                    )).toList(),
                    onChanged: (value) => controller.onRoleChanged(value),
                  )),
                  
                  const SizedBox(height: 16),
                  
                  // Karyawan fields (show only if role is Karyawan)
                  Obx(() => controller.isKaryawanRole.value
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.badge,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Data Karyawan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // NIK field
                                  TextFormField(
                                    controller: controller.nikController,
                                    decoration: InputDecoration(
                                      labelText: 'NIK',
                                      hintText: 'Nomor Induk Kependudukan',
                                      prefixIcon: const Icon(Icons.badge),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Tanggal Lahir field
                                  TextFormField(
                                    controller: controller.tanggalLahirController,
                                    decoration: InputDecoration(
                                      labelText: 'Tanggal Lahir',
                                      hintText: 'YYYY-MM-DD',
                                      prefixIcon: const Icon(Icons.calendar_today),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    readOnly: true,
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                                        firstDate: DateTime(1950),
                                        lastDate: DateTime.now(),
                                      );
                                      if (pickedDate != null) {
                                        controller.tanggalLahirController.text = 
                                            pickedDate.toIso8601String().split('T')[0];
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Jenis Kelamin dropdown
                                  DropdownButtonFormField<String>(
                                    value: controller.jenisKelaminController.text.isNotEmpty 
                                        ? controller.jenisKelaminController.text 
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: 'Jenis Kelamin',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'L',
                                        child: Text('Laki-laki'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'P',
                                        child: Text('Perempuan'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      controller.jenisKelaminController.text = value ?? '';
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Unit dropdown
                                  Obx(() => DropdownButtonFormField<int>(
                                    value: controller.selectedUnitId.value > 0 
                                        ? controller.selectedUnitId.value 
                                        : null,
                                    decoration: InputDecoration(
                                      labelText: 'Unit',
                                      hintText: 'Pilih unit',
                                      prefixIcon: const Icon(Icons.business),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('-- Pilih Unit --'),
                                      ),
                                      ...controller.units.map((unit) => DropdownMenuItem<int>(
                                        value: unit.id,
                                        child: Text(unit.nama),
                                      )).toList(),
                                    ],
                                    onChanged: (value) {
                                      controller.selectedUnitId.value = value ?? 0;
                                    },
                                  )),
                                  const SizedBox(height: 12),
                                  
                                  // Nomor Telepon field
                                  TextFormField(
                                    controller: controller.nomorTeleponController,
                                    decoration: InputDecoration(
                                      labelText: 'Nomor Telepon',
                                      hintText: 'Masukkan nomor telepon',
                                      prefixIcon: const Icon(Icons.phone),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Alamat field
                                  TextFormField(
                                    controller: controller.alamatController,
                                    decoration: InputDecoration(
                                      labelText: 'Alamat',
                                      hintText: 'Masukkan alamat lengkap',
                                      prefixIcon: const Icon(Icons.location_on),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      : const SizedBox.shrink(),
                  ),
                  
                  // Status switch
                  Obx(() => SwitchListTile(
                    title: const Text('Status Aktif'),
                    subtitle: Text(
                      controller.isActiveStatus.value 
                          ? 'User dapat login dan menggunakan sistem'
                          : 'User tidak dapat login ke sistem',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    value: controller.isActiveStatus.value,
                    onChanged: (value) {
                      controller.isActiveStatus.value = value;
                    },
                    activeColor: Colors.green,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () {
                            if (isEdit) {
                              controller.updateUser();
                            } else {
                              controller.createUser();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isEdit ? 'Update' : 'Simpan'),
                  )),
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