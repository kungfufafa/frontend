import 'dart:convert';
import 'user_model.dart';

// Helper functions
Tiket tiketFromJson(String str) => Tiket.fromJson(json.decode(str));
String tiketToJson(Tiket data) => json.encode(data.toJson());

List<Tiket> tiketListFromJson(String str) =>
    List<Tiket>.from(json.decode(str).map((x) => Tiket.fromJson(x)));

class Tiket {
  final int id;
  final String kode;
  final String judul;
  final String deskripsi;
  final String prioritas; // Urgent, High, Medium, Low
  final int? idUser;
  final int? idUnit;
  final int? idStatus;
  final int? idKaryawan;
  final DateTime? tanggalSelesai;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relasi
  final User? user;
  final Unit? unit;
  final Status? status;
  final Karyawan? karyawan;
  final List<Komentar>? komentars;
  final int? komentarCount;

  Tiket({
    required this.id,
    required this.kode,
    required this.judul,
    required this.deskripsi,
    required this.prioritas,
    this.idUser,
    this.idUnit,
    this.idStatus,
    this.idKaryawan,
    this.tanggalSelesai,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.unit,
    this.status,
    this.karyawan,
    this.komentars,
    this.komentarCount,
  });

  factory Tiket.fromJson(Map<String, dynamic> json) {
    // Convert Indonesian priority to English for display
    String prioritasEng = json["prioritas"] ?? 'Medium';
    if (prioritasEng == 'rendah') {
      prioritasEng = 'Low';
    } else if (prioritasEng == 'sedang') {
      prioritasEng = 'Medium';
    } else if (prioritasEng == 'tinggi') {
      prioritasEng = 'High';
    } else if (prioritasEng == 'urgent' || prioritasEng == 'sangat_tinggi') {
      prioritasEng = 'Urgent';
    }
    
    return Tiket(
      id: json["id"] ?? 0,
      kode: json["nomor_tiket"] ?? json["kode"] ?? '',
      judul: json["judul"] ?? '',
      deskripsi: json["deskripsi_kerusakan"] ?? json["deskripsi"] ?? '',
      prioritas: prioritasEng,
      idUser: json["id_user"],
      idUnit: json["id_unit"],
      idStatus: json["id_status"] ?? json["status_id"],
      idKaryawan: json["id_karyawan"],
      tanggalSelesai: json["tanggal_selesai"] != null 
          ? DateTime.tryParse(json["tanggal_selesai"].toString())
          : null,
      createdAt: DateTime.tryParse(json["tanggal_pengajuan"]?.toString() ?? json["created_at"]?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.now(),
      user: json["user"] != null ? User.fromJson(json["user"]) : null,
      unit: json["unit"] != null ? Unit.fromJson(json["unit"]) : null,
      status: json["status"] != null ? Status.fromJson(json["status"]) : null,
      karyawan: json["karyawan"] != null ? Karyawan.fromJson(json["karyawan"]) : null,
      komentars: json["komentars"] != null
          ? List<Komentar>.from(json["komentars"].map((x) => Komentar.fromJson(x)))
          : null,
      komentarCount: json["komentar_count"] ?? json["komentars_count"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "kode": kode,
    "judul": judul,
    "deskripsi": deskripsi,
    "prioritas": prioritas,
    "id_user": idUser,
    "id_unit": idUnit,
    "id_status": idStatus,
    "id_karyawan": idKaryawan,
    "tanggal_selesai": tanggalSelesai?.toIso8601String(),
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };

  // Helper methods
  String get statusLabel => status?.nama ?? 'Status $idStatus';
  String get unitLabel => unit?.nama ?? 'Unit $idUnit';
  String get karyawanLabel => karyawan?.nama ?? 'Belum ditugaskan';
  String get userLabel => user?.nama ?? 'User $idUser';
  
  // Additional getters for dashboard
  String get statusString => statusLabel.toLowerCase();
  int? get unitId => idUnit;
  String? get unitName => unit?.nama;
  int? get assignedTo => idKaryawan;
  String? get assignedToName => karyawan?.nama;
  
  bool get isOpen => idStatus == 1 || statusLabel.toLowerCase().contains('open');
  bool get isInProgress => idStatus == 2 || statusLabel.toLowerCase().contains('progress');
  bool get isClosed => idStatus == 3 || statusLabel.toLowerCase().contains('closed');
  bool get isResolved => idStatus == 4 || statusLabel.toLowerCase().contains('resolved');
  
  bool get isHighPriority => prioritas == 'Urgent' || prioritas == 'High';
  
  Tiket copyWith({
    int? id,
    String? kode,
    String? judul,
    String? deskripsi,
    String? prioritas,
    int? idUser,
    int? idUnit,
    int? idStatus,
    int? idKaryawan,
    DateTime? tanggalSelesai,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
    Unit? unit,
    Status? status,
    Karyawan? karyawan,
    List<Komentar>? komentars,
    int? komentarCount,
  }) {
    return Tiket(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      prioritas: prioritas ?? this.prioritas,
      idUser: idUser ?? this.idUser,
      idUnit: idUnit ?? this.idUnit,
      idStatus: idStatus ?? this.idStatus,
      idKaryawan: idKaryawan ?? this.idKaryawan,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      karyawan: karyawan ?? this.karyawan,
      komentars: komentars ?? this.komentars,
      komentarCount: komentarCount ?? this.komentarCount,
    );
  }
}

// Model untuk Komentar
class Komentar {
  final int id;
  final int idTiket;
  final int? idUser;
  final String body;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  Komentar({
    required this.id,
    required this.idTiket,
    this.idUser,
    required this.body,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Komentar.fromJson(Map<String, dynamic> json) => Komentar(
    id: json["id"] ?? 0,
    idTiket: json["id_tiket"] ?? json["tiket_id"] ?? 0,
    idUser: json["id_user"] ?? json["user_id"],
    body: json["deskripsi"] ?? json["komentar"] ?? json["body"] ?? json["content"] ?? '', // Backend sends 'deskripsi' field
    attachments: json["attachments"] != null
        ? List<String>.from(json["attachments"])
        : null,
    createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.now(),
    user: json["user"] != null ? User.fromJson(json["user"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id_tiket": idTiket,
    "body": body,
    if (attachments != null) "attachments": attachments,
  };

  String get userLabel => user?.nama ?? 'User $idUser';
}

// Model untuk Status
class Status {
  final int id;
  final String nama;  // nama_status in database
  final String? keterangan;  // renamed from deskripsi
  final String colorCode;  // renamed from warna, NOT NULL with default '#6c757d'
  final int orderSequence;  // renamed from urutan
  final DateTime createdAt;
  final DateTime updatedAt;

  Status({
    required this.id,
    required this.nama,
    this.keterangan,
    required this.colorCode,
    required this.orderSequence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    id: json["id"] ?? 0,
    nama: json["nama"] ?? json["nama_status"] ?? '',
    keterangan: json["keterangan"] ?? json["deskripsi"],  // fallback for old field name
    colorCode: json["color_code"] ?? json["warna"] ?? '#6c757d',  // fallback with default
    orderSequence: json["order_sequence"] ?? json["urutan"] ?? 0,  // fallback for old field name
    createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "nama_status": nama,
    "keterangan": keterangan,
    "color_code": colorCode,
    "order_sequence": orderSequence,
  };
}

// Model untuk Unit
class Unit {
  final int id;
  final String nama;  // nama_unit in database
  final String kategoriUnit;  // NOT NULL in database
  final String? description;  // renamed from deskripsi
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    required this.id,
    required this.nama,
    required this.kategoriUnit,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
    id: json["id"] ?? 0,
    nama: json["nama"] ?? json["nama_unit"] ?? '',
    kategoriUnit: json["kategori_unit"] ?? '',
    description: json["description"] ?? json["deskripsi"],  // fallback for old field name
    createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    "nama_unit": nama,
    "kategori_unit": kategoriUnit,
    "description": description,
  };
}

// Model untuk Karyawan
class Karyawan {
  final int id;
  final int idUser;  // NOT NULL in database
  final int idUnit;  // NOT NULL in database
  final String nama;
  final String nik;  // NOT NULL in database
  final DateTime tanggalLahir;  // NOT NULL in database
  final String jenisKelamin;  // 'L' or 'P'
  final String nomorTelepon;  // renamed from noTelp
  final String alamat;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final Unit? unit;

  Karyawan({
    required this.id,
    required this.idUser,
    required this.idUnit,
    required this.nama,
    required this.nik,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.nomorTelepon,
    required this.alamat,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.unit,
  });

  factory Karyawan.fromJson(Map<String, dynamic> json) => Karyawan(
    id: json["id"] ?? 0,
    idUser: json["id_user"] ?? 0,
    idUnit: json["id_unit"] ?? 0,
    nama: json["nama"] ?? '',
    nik: json["nik"] ?? '',
    tanggalLahir: DateTime.tryParse(json["tanggal_lahir"]?.toString() ?? '') ?? DateTime.now(),
    jenisKelamin: json["jenis_kelamin"] ?? 'L',
    nomorTelepon: json["nomor_telepon"] ?? json["no_telp"] ?? '',  // fallback for old field name
    alamat: json["alamat"] ?? '',
    createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.now(),
    user: json["user"] != null ? User.fromJson(json["user"]) : null,
    unit: json["unit"] != null ? Unit.fromJson(json["unit"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id_user": idUser,
    "id_unit": idUnit,
    "nama": nama,
    "nik": nik,
    "tanggal_lahir": tanggalLahir.toIso8601String().split('T')[0],  // Format as YYYY-MM-DD
    "jenis_kelamin": jenisKelamin,
    "nomor_telepon": nomorTelepon,
    "alamat": alamat,
  };

  String get unitLabel => unit?.nama ?? 'Unit $idUnit';
}

// Request Models
class CreateTiketRequest {
  final String judul;
  final String deskripsi;
  final String prioritas;
  final int? idUnit;
  final List<String>? attachments;
  
  CreateTiketRequest({
    required this.judul,
    required this.deskripsi,
    this.prioritas = 'sedang', // Default to 'sedang' (medium in Indonesian)
    this.idUnit,
    this.attachments,
  });
  
  Map<String, dynamic> toJson() {
    // Convert English priority to Indonesian for backend
    String prioritasIndo = prioritas;
    switch (prioritas.toLowerCase()) {
      case 'rendah':
        prioritasIndo = 'rendah';
        break;
      case 'sedang':
        prioritasIndo = 'sedang';
        break;
      case 'tinggi':
        prioritasIndo = 'tinggi';
        break;
      case 'urgent':
        prioritasIndo = 'urgent';
        break;
    }
    
    return {
      'judul': judul,
      'deskripsi_kerusakan': deskripsi, // Backend expects this field name
      'prioritas': prioritasIndo,
      if (idUnit != null) 'id_unit': idUnit,
      if (attachments != null) 'attachments': attachments,
    };
  }
}

class UpdateTiketRequest {
  final String? judul;
  final String? deskripsi;
  final String? prioritas;
  final int? idUnit;
  final int? idStatus;
  final int? idKaryawan;
  
  UpdateTiketRequest({
    this.judul,
    this.deskripsi,
    this.prioritas,
    this.idUnit,
    this.idStatus,
    this.idKaryawan,
  });
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (judul != null) data['judul'] = judul;
    if (deskripsi != null) data['deskripsi'] = deskripsi;
    if (prioritas != null) data['prioritas'] = prioritas;
    if (idUnit != null) data['id_unit'] = idUnit;
    if (idStatus != null) data['id_status'] = idStatus;
    if (idKaryawan != null) data['id_karyawan'] = idKaryawan;
    return data;
  }
}

class AssignTiketRequest {
  final int? unitId;
  final int? karyawanId;
  
  AssignTiketRequest({this.unitId, this.karyawanId});
  
  Map<String, dynamic> toJson() {
    if (unitId != null) return {'unit_id': unitId};
    if (karyawanId != null) return {'karyawan_id': karyawanId};
    return {};
  }
}

class UpdateStatusRequest {
  final int? statusId;
  final String? status;
  final String? komentar;
  
  UpdateStatusRequest({this.statusId, this.status, this.komentar});
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (statusId != null) data['id_status'] = statusId; // Backend expects 'id_status'
    if (status != null) data['status'] = status;
    if (komentar != null && komentar!.isNotEmpty) data['komentar'] = komentar;
    return data;
  }
}

class CreateKomentarRequest {
  final String body;
  final List<String>? attachments;
  
  CreateKomentarRequest({
    required this.body,
    this.attachments,
  });
  
  Map<String, dynamic> toJson() => {
    'komentar': body, // Backend expects 'komentar' field
    if (attachments != null) 'attachments': attachments,
  };
}
