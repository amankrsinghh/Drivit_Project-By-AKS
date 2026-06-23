import 'package:get/get.dart';
import '../controllers/map_controller.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MapController>()) {
      Get.put<MapController>(MapController(), permanent: true);
    }
  }
}

