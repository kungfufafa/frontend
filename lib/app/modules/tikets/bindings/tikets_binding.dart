import 'package:get/get.dart';
import '../controllers/tikets_controller.dart';

class TiketsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TiketsController>(
      () => TiketsController(),
    );
  }
}
