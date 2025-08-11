import 'package:get/get.dart';
import '../controllers/create_tiket_controller.dart';

class CreateTiketBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateTiketController>(
      () => CreateTiketController(),
    );
  }
}
