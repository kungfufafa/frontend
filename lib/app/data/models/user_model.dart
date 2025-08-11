import 'dart:convert';
import 'package:flutter/foundation.dart';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  final int id;
  final String nama;
  final String email;
  final String? password;
  final int? idRole;
  final bool isActive;
  final DateTime? emailVerifiedAt;
  final String? rememberToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional fields untuk relasi dan permissions
  final String? roleName;
  final dynamic permissions; // JSON nullable dari database, bisa null atau Map/List
  final Map<String, dynamic>? additionalData;

  User({
    required this.id,
    required this.nama,
    required this.email,
    this.password,
    this.idRole,
    required this.isActive,
    this.emailVerifiedAt,
    this.rememberToken,
    required this.createdAt,
    required this.updatedAt,
    this.roleName,
    this.permissions,
    this.additionalData,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: _parseIntSafe(json["id"]),
    nama: json["nama"]?.toString() ?? '',
    email: json["email"]?.toString() ?? '',
    password: json["password"]?.toString(),
    idRole: _parseIntNullable(json["id_role"]),
    isActive: _parseIsActiveSafe(json),
    emailVerifiedAt: _parseDateTimeSafe(json["email_verified_at"]),
    rememberToken: json["remember_token"]?.toString(),
    createdAt: _parseDateTimeSafe(json["created_at"]) ?? DateTime.now(),
    updatedAt: _parseDateTimeSafe(json["updated_at"]) ?? DateTime.now(),
    roleName: _parseRoleNameSafe(json),
    permissions: json["permissions"], // Murni dari database, null jika tidak ada
    additionalData: json["additional_data"] is Map<String, dynamic>
        ? json["additional_data"]
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "nama": nama,
    "email": email,
    // password tidak di-expose untuk keamanan
    "id_role": idRole,
    "is_active": isActive,
    "email_verified_at": emailVerifiedAt?.toIso8601String(),
    // remember_token tidak di-expose untuk keamanan
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    if (roleName != null) "role_name": roleName,
    if (permissions != null) "permissions": permissions,
    if (additionalData != null) "additional_data": additionalData,
  };

  // Helper methods untuk kemudahan akses
  String get displayName => nama;
  
  String get displayRole => roleName ?? 'Role $idRole';
  
  bool get isVerified => emailVerifiedAt != null;
  
  String get statusText => isActive ? 'Aktif' : 'Non-aktif';
  
  // Method untuk check permission (jika ada)
  bool hasPermission(String permission) {
    if (permissions == null) return false;
    
    // Handle jika permissions adalah List
    if (permissions is List) {
      return (permissions as List).contains(permission);
    }
    
    // Handle jika permissions adalah Map (JSON object)
    if (permissions is Map) {
      return (permissions as Map).containsKey(permission);
    }
    
    return false;
  }
  
  // Method untuk role checking
  bool isAdmin() => idRole == 1 || roleName?.toLowerCase() == 'administrator';
  bool isManager() => idRole == 2 || roleName?.toLowerCase() == 'manager';
  bool isKaryawan() => idRole == 3 || roleName?.toLowerCase() == 'karyawan';
  bool isDireksi() => idRole == 4 || roleName?.toLowerCase() == 'direksi';
  bool isUser() => idRole == 5 ||
    (roleName?.toLowerCase().contains('user') == true) ||
    (roleName?.toLowerCase().contains('klien') == true);
  
  // Copy method untuk update data user
  User copyWith({
    int? id,
    String? nama,
    String? email,
    String? password,
    int? idRole,
    bool? isActive,
    DateTime? emailVerifiedAt,
    String? rememberToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? roleName,
    dynamic permissions,
    Map<String, dynamic>? additionalData,
  }) {
    return User(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
      idRole: idRole ?? this.idRole,
      isActive: isActive ?? this.isActive,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      rememberToken: rememberToken ?? this.rememberToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roleName: roleName ?? this.roleName,
      permissions: permissions ?? this.permissions,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, nama: $nama, email: $email, role: $displayRole, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  // Safe parsing helper methods
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTimeSafe(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint('ERROR: Failed to parse DateTime: $value - $e');
        return null;
      }
    }
    return null;
  }

  static bool _parseIsActiveSafe(Map<String, dynamic> json) {
    // Check multiple possible field names and formats
    var isActiveValue = json["isActive"] ?? json["is_active"];
    
    if (isActiveValue == null) return false;
    if (isActiveValue is bool) return isActiveValue;
    if (isActiveValue is int) return isActiveValue == 1;
    if (isActiveValue is String) {
      String lower = isActiveValue.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static String? _parseRoleNameSafe(Map<String, dynamic> json) {
    try {
      // Try nested role object first
      if (json["role"] is Map<String, dynamic>) {
        var roleName = json["role"]["nama_role"];
        if (roleName != null) return roleName.toString();
      }
      
      // Fallback to direct role_name field
      var directRoleName = json["role_name"];
      if (directRoleName != null) return directRoleName.toString();
      
      return null;
    } catch (e) {
      debugPrint('ERROR: Failed to parse role name: $e');
      return null;
    }
  }
  
  // Dihapus karena permissions sekarang langsung menggunakan dynamic type dari JSON
}

// Class untuk update profile request
class UpdateProfileRequest {
  final String nama;
  final String email;
  
  UpdateProfileRequest({
    required this.nama,
    required this.email,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'email': email,
    };
  }
}

// Class untuk change password request
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String newPasswordConfirmation;
  
  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.newPasswordConfirmation,
  });
  
  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
    'new_password_confirmation': newPasswordConfirmation,
  };
}

// Class untuk register request
class RegisterRequest {
  final String nama;
  final String email;
  final String password;
  final String passwordConfirmation;
  
  RegisterRequest({
    required this.nama,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });
  
  Map<String, dynamic> toJson() => {
    'nama': nama,
    'email': email,
    'password': password,
    'password_confirmation': passwordConfirmation,
  };
}