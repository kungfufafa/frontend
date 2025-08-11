import 'package:get/get.dart';
import '../controllers/tiket_detail_controller.dart';

class TiketDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TiketDetailController>(
      () => TiketDetailController(),
    );
  }
}
