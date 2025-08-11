import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/app/modules/tikets/controllers/tiket_detail_controller.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart';
import 'test_helpers.dart';

void main() {
  late TiketDetailController controller;
  late TestApiService mockApiService;
  late TestAuthService mockAuthService;

  setUp(() {
    Get.testMode = true;
    
    mockApiService = TestApiService();
    mockAuthService = TestAuthService();
    
    // Put services with permanent: false to avoid lifecycle issues
    Get.put<ApiService>(mockApiService, permanent: false);
    Get.put<AuthService>(mockAuthService, permanent: false);
    
    controller = TiketDetailController();
  });

  tearDown(() {
    Get.reset();
  });

  group('TiketDetailController Permission Tests', () {
    test('Karyawan cannot edit tickets', () {
      // Arrange
      final karyawan = User(
        id: 2,
        nama: 'Test Karyawan',
        email: 'karyawan@test.com',
        idRole: 3, // Karyawan role
        roleName: 'Karyawan',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(karyawan);
      
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        idKaryawan: 2,
        karyawan: Karyawan(
          id: 2,
          idUser: 2,
          idUnit: 1,
          nama: 'Test Karyawan',
          nik: '123456',
          tanggalLahir: DateTime(1990, 1, 1),
          jenisKelamin: 'L',
          nomorTelepon: '08123456789',
          alamat: 'Test Address',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canEditTiket(), false);
    });

    test('User can edit their own open tickets', () {
      // Arrange
      final user = User(
        id: 1,
        nama: 'Test User',
        email: 'user@test.com',
        idRole: 5, // User/Klien role
        roleName: 'User/Klien',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(user);
      
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1, // Same as user
        idStatus: 1, // Open status
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canEditTiket(), true);
    });

    test('Manager can edit all tickets', () {
      // Arrange
      final manager = User(
        id: 3,
        nama: 'Test Manager',
        email: 'manager@test.com',
        idRole: 2, // Manager role
        roleName: 'Manager',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(manager);
      
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canEditTiket(), true);
    });

    test('Admin can edit all tickets', () {
      // Arrange
      final admin = User(
        id: 4,
        nama: 'Test Admin',
        email: 'admin@test.com',
        idRole: 1, // Administrator role
        roleName: 'Administrator',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(admin);
      
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canEditTiket(), true);
    });
  });

  group('Status Transition Tests', () {
    test('Karyawan can only update status for assigned tickets', () {
      // Arrange
      final karyawan = User(
        id: 2,
        nama: 'Test Karyawan',
        email: 'karyawan@test.com',
        idRole: 3, // Karyawan role
        roleName: 'Karyawan',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(karyawan);
      
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        idKaryawan: 2,
        karyawan: Karyawan(
          id: 2,
          idUser: 2,
          idUnit: 1,
          nama: 'Test Karyawan',
          nik: '123456',
          tanggalLahir: DateTime(1990, 1, 1),
          jenisKelamin: 'L',
          nomorTelepon: '08123456789',
          alamat: 'Test Address',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canUpdateStatus(), true);
    });

    test('Karyawan cannot update status for unassigned tickets', () {
      // Arrange
      final karyawan = User(
        id: 2,
        nama: 'Test Karyawan',
        email: 'karyawan@test.com',
        idRole: 3, // Karyawan role
        roleName: 'Karyawan',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(karyawan);
      
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        idKaryawan: null, // Not assigned
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canUpdateStatus(), false);
    });

    test('Status transitions follow correct workflow for Karyawan', () {
      // Arrange
      final karyawan = User(
        id: 2,
        nama: 'Test Karyawan',
        email: 'karyawan@test.com',
        idRole: 3, // Karyawan role
        roleName: 'Karyawan',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(karyawan);
      
      // Test BARU -> DIPROSES
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: TiketDetailController.STATUS_BARU,
        idKaryawan: 2,
        karyawan: Karyawan(
          id: 2,
          idUser: 2,
          idUnit: 1,
          nama: 'Test Karyawan',
          nik: '123456',
          tanggalLahir: DateTime(1990, 1, 1),
          jenisKelamin: 'L',
          nomorTelepon: '08123456789',
          alamat: 'Test Address',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      var transitions = controller.getAvailableStatusTransitions();
      expect(transitions, contains(TiketDetailController.STATUS_DIPROSES));
      expect(transitions.length, 1);
      
      // Test DIPROSES -> PENDING or SELESAI
      controller.tiket.value = controller.tiket.value!.copyWith(
        idStatus: TiketDetailController.STATUS_DIPROSES,
      );
      
      transitions = controller.getAvailableStatusTransitions();
      expect(transitions, contains(TiketDetailController.STATUS_PENDING));
      expect(transitions, contains(TiketDetailController.STATUS_SELESAI));
      expect(transitions.length, 2);
      
      // Test PENDING -> DIPROSES
      controller.tiket.value = controller.tiket.value!.copyWith(
        idStatus: TiketDetailController.STATUS_PENDING,
      );
      
      transitions = controller.getAvailableStatusTransitions();
      expect(transitions, contains(TiketDetailController.STATUS_DIPROSES));
      expect(transitions.length, 1);
      
      // Test SELESAI -> no more transitions
      controller.tiket.value = controller.tiket.value!.copyWith(
        idStatus: TiketDetailController.STATUS_SELESAI,
      );
      
      transitions = controller.getAvailableStatusTransitions();
      expect(transitions.isEmpty, true);
    });

    test('Admin and Manager can change status freely except from SELESAI', () {
      // Arrange
      final admin = User(
        id: 4,
        nama: 'Test Admin',
        email: 'admin@test.com',
        idRole: 1, // Administrator role
        roleName: 'Administrator',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(admin);
      
      // Test any status except SELESAI
      controller.tiket.value = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: TiketDetailController.STATUS_BARU,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      var transitions = controller.getAvailableStatusTransitions();
      expect(transitions.length, greaterThan(0));
      expect(transitions, isNot(contains(TiketDetailController.STATUS_BARU))); // Cannot transition to same status
      
      // Test from SELESAI - no transitions
      controller.tiket.value = controller.tiket.value!.copyWith(
        idStatus: TiketDetailController.STATUS_SELESAI,
      );
      
      transitions = controller.getAvailableStatusTransitions();
      expect(transitions.isEmpty, true);
    });
  });

  group('Assignment Permission Tests', () {
    test('Only Admin and Manager can assign tickets', () {
      // Test Admin
      final admin = User(
        id: 4,
        nama: 'Test Admin',
        email: 'admin@test.com',
        idRole: 1, // Administrator role
        roleName: 'Administrator',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(admin);
      expect(controller.canAssignTiket(), true);
      
      // Test Manager
      final manager = User(
        id: 3,
        nama: 'Test Manager',
        email: 'manager@test.com',
        idRole: 2, // Manager role
        roleName: 'Manager',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(manager);
      expect(controller.canAssignTiket(), true);
      
      // Test Karyawan
      final karyawan = User(
        id: 2,
        nama: 'Test Karyawan',
        email: 'karyawan@test.com',
        idRole: 3, // Karyawan role
        roleName: 'Karyawan',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(karyawan);
      expect(controller.canAssignTiket(), false);
      
      // Test User
      final user = User(
        id: 1,
        nama: 'Test User',
        email: 'user@test.com',
        idRole: 5, // User/Klien role
        roleName: 'User/Klien',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      when(mockAuthService.user).thenReturn(user);
      expect(controller.canAssignTiket(), false);
    });
  });

  // Priority conversion is a private method, so we skip testing it directly

  group('CRUD Operations Tests', () {
    test('updateTiket sends correct request and shows success snackbar', () async {
      // Arrange
      controller.tiketId = 1;
      controller.judulController.text = 'Updated Title';
      controller.deskripsiController.text = 'Updated Description';
      controller.selectedPriority.value = 'tinggi';
      
      final mockResponse = Response(
        statusCode: 200,
        body: {'message': 'Tiket berhasil diperbarui'},
      );
      
      when(mockApiService.updateTiket(any, any))
          .thenAnswer((_) async => mockResponse);
      
      when(mockApiService.getTiketById(1))
          .thenAnswer((_) async => Response(
            statusCode: 200,
            body: {
              'data': {
                'id': 1,
                'nomor_tiket': 'TKT-001',
                'judul': 'Updated Title',
                'deskripsi_kerusakan': 'Updated Description',
                'prioritas': 'tinggi',
                'id_user': 1,
                'id_status': 1,
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-01T00:00:00Z',
              }
            },
          ));
      
      // Act
      await controller.updateTiket();
      
      // Assert
      verify(mockApiService.updateTiket(1, any)).called(1);
      expect(controller.isLoading.value, false);
    });

    test('sendKomentar validates empty comment', () async {
      // Arrange
      controller.tiketId = 1;
      controller.komentarController.text = '';
      
      // Act
      await controller.sendKomentar();
      
      // Assert
      verifyNever(mockApiService.createKomentar(any, any));
      expect(controller.isSendingKomentar.value, false);
    });

    test('sendKomentar sends comment and reloads comments', () async {
      // Arrange
      controller.tiketId = 1;
      controller.komentarController.text = 'Test comment';
      
      final mockCreateResponse = Response(
        statusCode: 201,
        body: {'message': 'Komentar berhasil ditambahkan'},
      );
      
      final mockLoadResponse = Response(
        statusCode: 200,
        body: {
          'data': [
            {
              'id': 1,
              'deskripsi': 'Test comment',
              'id_user': 1,
              'id_tiket': 1,
              'created_at': '2024-01-01T00:00:00Z',
              'user': {
                'id': 1,
                'nama': 'Test User',
                'email': 'user@test.com',
              }
            }
          ]
        },
      );
      
      when(mockApiService.createKomentar(any, any))
          .thenAnswer((_) async => mockCreateResponse);
      
      when(mockApiService.getKomentars(1))
          .thenAnswer((_) async => mockLoadResponse);
      
      // Act
      await controller.sendKomentar();
      
      // Assert
      verify(mockApiService.createKomentar(1, any)).called(1);
      verify(mockApiService.getKomentars(1)).called(1);
      expect(controller.komentarController.text, '');
      expect(controller.komentars.length, 1);
    });

    test('assignToKaryawan updates ticket and shows success message', () async {
      // Arrange
      controller.tiketId = 1;
      
      final mockResponse = Response(
        statusCode: 200,
        body: {'message': 'Tiket berhasil ditugaskan'},
      );
      
      when(mockApiService.assignTiketToKaryawan(any, any, komentar: anyNamed('komentar')))
          .thenAnswer((_) async => mockResponse);
      
      when(mockApiService.getTiketById(1))
          .thenAnswer((_) async => Response(
            statusCode: 200,
            body: {
              'data': {
                'id': 1,
                'nomor_tiket': 'TKT-001',
                'judul': 'Test Ticket',
                'deskripsi_kerusakan': 'Test Description',
                'prioritas': 'medium',
                'id_user': 1,
                'id_status': 1,
                'id_karyawan': 2,
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-01T00:00:00Z',
              }
            },
          ));
      
      // Act
      await controller.assignToKaryawan(2, komentar: 'Assigned to karyawan');
      
      // Assert
      verify(mockApiService.assignTiketToKaryawan(1, 2, komentar: 'Assigned to karyawan')).called(1);
      verify(mockApiService.getTiketById(1)).called(1);
    });
  });
}
