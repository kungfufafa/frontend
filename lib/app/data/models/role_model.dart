import 'dart:convert';

Role roleFromJson(String str) => Role.fromJson(json.decode(str));
String roleToJson(Role data) => json.encode(data.toJson());

List<Role> roleListFromJson(String str) =>
    List<Role>.from(json.decode(str).map((x) => Role.fromJson(x)));

class Role {
  final int id;
  final String namaRole;
  final String? description;  // renamed from deskripsi
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? userCount;  // Computed field from API - OK to keep

  Role({
    required this.id,
    required this.namaRole,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.userCount,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json["id"] ?? 0,
    namaRole: json["nama_role"] ?? json["name"] ?? '',
    description: json["description"] ?? json["deskripsi"],  // fallback for old field name
    createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.now(),
    userCount: json["user_count"] ?? json["users_count"],
  );

  Map<String, dynamic> toJson() => {
    "nama_role": namaRole,
    "description": description,
  };

  // Helper methods
  bool get isAdminRole => id == 1 || namaRole.toLowerCase().contains('admin');
  bool get isManagerRole => id == 2 || namaRole.toLowerCase().contains('manager');
  bool get isKaryawanRole => id == 3 || namaRole.toLowerCase().contains('karyawan');
  bool get isDireksiRole => id == 4 || namaRole.toLowerCase().contains('direksi');
  bool get isUserRole => id == 5 || 
      namaRole.toLowerCase().contains('user') || 
      namaRole.toLowerCase().contains('klien');

  // Removed hasPermission method as permissions are now in User model

  Role copyWith({
    int? id,
    String? namaRole,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? userCount,
  }) {
    return Role(
      id: id ?? this.id,
      namaRole: namaRole ?? this.namaRole,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userCount: userCount ?? this.userCount,
    );
  }
}

// Role option for dropdowns
class RoleOption {
  final int id;
  final String nama;

  RoleOption({
    required this.id,
    required this.nama,
  });

  factory RoleOption.fromJson(Map<String, dynamic> json) => RoleOption(
    id: json["id"] ?? 0,
    nama: json["nama_role"] ?? json["name"] ?? '',
  );
}
