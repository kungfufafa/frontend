import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // ApiService sudah di-register global di main.dart
    // Hanya register controller yang dibutuhkan
    Get.lazyPut<LoginController>(
      () => LoginController(),
    );
  }
}