import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/units_controller.dart';

class UnitFormDialog extends StatelessWidget {
  final bool isEdit;
  
  const UnitFormDialog({super.key, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UnitsController>();
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
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
                    isEdit ? 'Edit Unit' : 'Tambah Unit Baru',
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
                    // Nama Unit field
                    TextFormField(
                      controller: controller.namaController,
                      decoration: InputDecoration(
                        labelText: 'Nama Unit',
                        hintText: 'Masukkan nama unit',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Kategori Unit field
                    TextFormField(
                      controller: controller.kategoriUnitController,
                      decoration: InputDecoration(
                        labelText: 'Kategori Unit',
                        hintText: 'Masukkan kategori unit',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextFormField(
                      controller: controller.descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        hintText: 'Masukkan deskripsi unit (opsional)',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
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
                                controller.updateUnit();
                              } else {
                                controller.createUnit();
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