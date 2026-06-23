


import 'package:get/get.dart';
import '../../finding/controllers/driver_finding_controller.dart';

class DriverHomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DriverFindingController>()) {
      Get.put(DriverFindingController(), permanent: true);
    }
  }
}