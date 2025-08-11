import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // ApiService sudah di-register global di main.dart
    // Hanya register controller yang dibutuhkan
    Get.lazyPut<ProfileController>(
      () => ProfileController(),
    );
  }
}