import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/app/services/api_service.dart';
import 'package:frontend/app/services/auth_service.dart';

// Custom mock for ApiService that properly handles GetX lifecycle
class TestApiService extends GetxService with Mock implements ApiService {
  @override
  InternalFinalCallback<void> get onStart => InternalFinalCallback(callback: () {});
  
  @override
  InternalFinalCallback<void> get onDelete => InternalFinalCallback(callback: () {});
  
  @override
  void onInit() {}
  
  @override
  void onReady() {}
  
  @override
  void onClose() {}
}

// Custom mock for AuthService that properly handles GetX lifecycle
class TestAuthService extends GetxService with Mock implements AuthService {
  @override
  InternalFinalCallback<void> get onStart => InternalFinalCallback(callback: () {});
  
  @override
  InternalFinalCallback<void> get onDelete => InternalFinalCallback(callback: () {});
  
  @override
  void onInit() {}
  
  @override
  void onReady() {}
  
  @override
  void onClose() {}
}
