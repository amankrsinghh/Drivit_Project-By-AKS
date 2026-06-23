import 'package:get/get.dart';
import '../controllers/select_ride_controller.dart';

class SelectRideBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SelectRideController>(() => SelectRideController());
  }
}
