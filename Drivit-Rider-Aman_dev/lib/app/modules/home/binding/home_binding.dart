//
// import 'package:get/get.dart';
//
// import '../../profile/bindings/profile_binding.dart';
// import '../controllers/home_controller.dart';
// import '../../my_ride/controllers/my_ride_controller.dart';
//
// import '../../packages/bindings/package_binding.dart';
//
// class HomeBinding extends Bindings {
//   @override
//   void dependencies() {
//     // Home controller
//     if (!Get.isRegistered<HomeController>()) {
//       Get.put<HomeController>(HomeController(), permanent: true);
//     }
//
//     // My Ride controller
//     if (!Get.isRegistered<MyRideController>()) {
//       Get.put<MyRideController>(MyRideController(), permanent: true);
//     }
//
//     // ✅ module bindings
//     PackagesBinding().dependencies();
//     ProfileBinding().dependencies();
//   }
// }





import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../my_ride/controllers/my_ride_controller.dart';
import '../../packages/controllers/package_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MyRideController>()) {
      Get.put<MyRideController>(MyRideController(), permanent: true);
    }
    if (!Get.isRegistered<PackagesController>()) {
      Get.put<PackagesController>(PackagesController(), permanent: true);
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put<ProfileController>(ProfileController(), permanent: true);
    }
    // HomeController relies on MyRideController in onInit, so it must be initialized last
    if (!Get.isRegistered<HomeController>()) {
      Get.put<HomeController>(HomeController(), permanent: true);
    }

  }
}