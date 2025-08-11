import 'package:get/get.dart';
import '../controllers/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    // ApiService sudah di-register global di main.dart
    // Hanya register controller yang dibutuhkan
    Get.lazyPut<RegisterController>(
      () => RegisterController(),
    );
  }
}