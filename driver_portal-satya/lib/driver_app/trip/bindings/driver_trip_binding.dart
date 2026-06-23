// import 'package:get/get.dart';
// import '../controllers/driver_trip_controller.dart';
//
// class DriverTripBinding extends Bindings {
//   @override
//   void dependencies() {
//     if (!Get.isRegistered<DriverTripController>()) {
//       Get.put(DriverTripController());
//     }
//   }
// }






import 'package:get/get.dart';
import '../controllers/driver_trip_controller.dart';

class DriverTripBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<DriverTripController>()) {
      Get.put(DriverTripController());
    }
  }
}