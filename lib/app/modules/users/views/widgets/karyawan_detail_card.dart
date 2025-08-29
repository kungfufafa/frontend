import 'package:flutter/material.dart';
import 'package:frontend/app/data/models/tiket_model.dart';

class KaryawanDetailCard extends StatelessWidget {
  final Karyawan karyawan;
  
  const KaryawanDetailCard({super.key, required this.karyawan});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
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
                size: 16,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 6),
              Text(
                'Detail Karyawan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // NIK
          if (karyawan.nik.isNotEmpty)
            _buildDetailRow(
              Icons.badge_outlined,
              'NIK',
              karyawan.nik,
            ),
          
          // Tanggal Lahir
          _buildDetailRow(
            Icons.cake,
            'Tanggal Lahir',
            '${karyawan.tanggalLahir.day}/${karyawan.tanggalLahir.month}/${karyawan.tanggalLahir.year}',
          ),
          
          // Jenis Kelamin
          _buildDetailRow(
            Icons.person,
            'Jenis Kelamin',
            karyawan.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan',
          ),
          
          // Unit
          if (karyawan.unit != null)
            _buildDetailRow(
              Icons.business,
              'Unit',
              karyawan.unit!.nama,
            ),
          
          // No Telp
          if (karyawan.nomorTelepon.isNotEmpty)
            _buildDetailRow(
              Icons.phone,
              'No. Telepon',
              karyawan.nomorTelepon,
            ),
          
          // Alamat
          if (karyawan.alamat.isNotEmpty)
            _buildDetailRow(
              Icons.location_on,
              'Alamat',
              karyawan.alamat,
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
