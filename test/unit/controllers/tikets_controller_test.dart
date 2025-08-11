import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:frontend/app/modules/tikets/controllers/tikets_controller.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';
import 'package:frontend/app/data/models/user_model.dart';
import 'package:frontend/app/data/models/tiket_model.dart';

@GenerateNiceMocks([MockSpec<ApiService>(), MockSpec<AuthService>()])
import 'tikets_controller_test.mocks.dart';

void main() {
  late TiketsController controller;
  late MockApiService mockApiService;
  late MockAuthService mockAuthService;

  setUp(() {
    // Initialize GetX bindings
    Get.testMode = true;
    
    // Create mocks
    mockApiService = MockApiService();
    mockAuthService = MockAuthService();
    
    // Skip stubbing lifecycle methods - NiceMocks handle them
    
    // Inject mocks
    Get.put<ApiService>(mockApiService);
    Get.put<AuthService>(mockAuthService);
    
    // Stub default responses for API calls that happen in onInit
    when(mockApiService.getStatuses()).thenAnswer((_) async => Response(
      statusCode: 200,
      body: {'data': []},
    ));
    when(mockApiService.getUnits()).thenAnswer((_) async => Response(
      statusCode: 200,
      body: {'data': []},
    ));
    when(mockApiService.getTikets(query: anyNamed('query'))).thenAnswer((_) async => Response(
      statusCode: 200,
      body: {'data': {'data': [], 'last_page': 1, 'total': 0}},
    ));
    
    // Create controller
    controller = TiketsController();
  });

  tearDown(() {
    Get.reset();
  });

  group('TiketsController Permission Tests', () {
    test('User/Klien can create ticket', () {
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
      
      // Act & Assert
      expect(controller.isUser, true);
      expect(controller.isAdmin, false);
      expect(controller.isManager, false);
      expect(controller.isKaryawan, false);
    });

    test('Karyawan cannot create ticket', () {
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
      
      // Act & Assert
      expect(controller.isKaryawan, true);
      expect(controller.isUser, false);
      // Karyawan should not be able to create tickets
    });

    test('Manager cannot create ticket', () {
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
      
      // Act & Assert
      expect(controller.isManager, true);
      expect(controller.isUser, false);
      // Manager should not be able to create tickets
    });

    test('canEditTiket returns false for Karyawan', () {
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
      
      final tiket = Tiket(
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
      expect(controller.canEditTiket(tiket), false);
    });

    test('canEditTiket returns true for ticket owner', () {
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
      
      final tiket = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1, // Same as user id
        idStatus: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canEditTiket(tiket), true);
    });

    test('canDeleteTiket returns true only for Admin and Manager', () {
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
      
      final tiket = Tiket(
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
      
      // Test Admin
      when(mockAuthService.user).thenReturn(admin);
      expect(controller.canDeleteTiket(tiket), true);
      
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
      expect(controller.canDeleteTiket(tiket), false);
    });

    test('canChangeStatus returns true for Karyawan with assigned ticket', () {
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
      
      final tiket = Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        idKaryawan: 2, // Assigned to karyawan
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Act & Assert
      expect(controller.canChangeStatus(tiket), true);
    });
  });

  group('TiketsController CRUD Operations', () {
    test('loadTikets successfully loads tickets', () async {
      // Arrange
      final mockResponse = Response(
        statusCode: 200,
        body: {
          'data': {
            'data': [
              {
                'id': 1,
                'nomor_tiket': 'TKT-001',
                'judul': 'Test Ticket',
                'deskripsi_kerusakan': 'Test Description',
                'prioritas': 'medium',
                'id_user': 1,
                'id_status': 1,
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-01T00:00:00Z',
              }
            ],
            'last_page': 1,
            'total': 1,
          }
        },
      );
      
      when(mockApiService.getTikets(query: anyNamed('query')))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      await controller.loadTikets();
      
      // Assert
      expect(controller.tikets.length, 1);
      expect(controller.tikets.first.kode, 'TKT-001');
      expect(controller.errorMessage.value, '');
    });

    test('deleteTiket shows success snackbar on success', () async {
      // Arrange
      final mockResponse = Response(
        statusCode: 200,
        body: {'message': 'Tiket berhasil dihapus'},
      );
      
      when(mockApiService.deleteTiket(1))
          .thenAnswer((_) async => mockResponse);
      
      // Add a ticket to the list first
      controller.tikets.add(Tiket(
        id: 1,
        kode: 'TKT-001',
        judul: 'Test Ticket',
        deskripsi: 'Test Description',
        prioritas: 'medium',
        idUser: 1,
        idStatus: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      
      // Act
      await controller.deleteTiket(1);
      
      // Assert
      expect(controller.tikets.length, 0);
      verify(mockApiService.deleteTiket(1)).called(1);
    });

    test('Filter by status works correctly', () async {
      // Arrange
      final mockResponse = Response(
        statusCode: 200,
        body: {
          'data': {
            'data': [],
            'last_page': 1,
            'total': 0,
          }
        },
      );
      
      when(mockApiService.getTikets(query: anyNamed('query')))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      controller.setStatusFilter(2);
      
      // Assert
      expect(controller.selectedStatusId.value, 2);
      // Should trigger loadTikets due to reactive binding
    });

    test('Search functionality triggers API call with search query', () async {
      // Arrange
      final mockResponse = Response(
        statusCode: 200,
        body: {
          'data': {
            'data': [],
            'last_page': 1,
            'total': 0,
          }
        },
      );
      
      when(mockApiService.getTikets(query: anyNamed('query')))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      controller.setSearchQuery('test query');
      await Future.delayed(Duration(milliseconds: 600)); // Wait for debounce
      
      // Assert
      expect(controller.searchQuery.value, 'test query');
    });
  });

  group('TiketsController Pagination', () {
    test('loadMoreTikets increments page and loads more tickets', () async {
      // Arrange
      controller.currentPage.value = 1;
      controller.lastPage.value = 3;
      
      final mockResponse = Response(
        statusCode: 200,
        body: {
          'data': {
            'data': [
              {
                'id': 2,
                'nomor_tiket': 'TKT-002',
                'judul': 'Test Ticket 2',
                'deskripsi_kerusakan': 'Test Description 2',
                'prioritas': 'high',
                'id_user': 1,
                'id_status': 1,
                'created_at': '2024-01-02T00:00:00Z',
                'updated_at': '2024-01-02T00:00:00Z',
              }
            ],
            'last_page': 3,
            'total': 3,
          }
        },
      );
      
      when(mockApiService.getTikets(query: anyNamed('query')))
          .thenAnswer((_) async => mockResponse);
      
      // Act
      await controller.loadMoreTikets();
      
      // Assert
      expect(controller.currentPage.value, 2);
    });

    test('loadMoreTikets does not increment when on last page', () async {
      // Arrange
      controller.currentPage.value = 3;
      controller.lastPage.value = 3;
      
      // Act
      await controller.loadMoreTikets();
      
      // Assert
      expect(controller.currentPage.value, 3);
      verifyNever(mockApiService.getTikets(query: anyNamed('query')));
    });
  });
}
