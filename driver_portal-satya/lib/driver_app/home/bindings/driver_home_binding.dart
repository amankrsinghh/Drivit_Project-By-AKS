

import 'package:get/get.dart';

import '../../profile/controllers/driver_wallet_controller.dart';
import '../controllers/driver_home_controller.dart';
import '../../finding/controllers/driver_finding_controller.dart';
import '../../history/controllers/driver_history_controller.dart';
import '../../profile/controllers/driver_profile_controller.dart';
import '../../package/controllers/driver_package_controller.dart';

class DriverHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DriverHomeController(), permanent: true);
    Get.put(DriverFindingController(), permanent: true);
    Get.put(DriverHistoryController(), permanent: true);
    Get.put(DriverProfileController(), permanent: true);
    Get.put(DriverWalletController(), permanent: true);
    Get.put(DriverPackageController(), permanent: true);
  }
}