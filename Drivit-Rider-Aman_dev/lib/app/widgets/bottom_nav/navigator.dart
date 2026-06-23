
import 'package:get/get.dart';

import '../../modules/home/controllers/home_controller.dart';
import '../../routes/app_routes.dart';


class TabNavigator {
  static Future<void> toTab(int index) async {
    // if home controller exists, set tab
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().changeTab(index);
    }

    // if not currently on home, go home (clear stack)
    if (Get.currentRoute != Routes.home) {
      await Get.offAllNamed(Routes.home);
      // after navigation, again ensure tab
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().changeTab(index);
      }
    }
  }

  static Future<void> toHome() => toTab(0);
  static Future<void> toMyRide() => toTab(1);
  static Future<void> toPackage() => toTab(2);
  static Future<void> toProfile() => toTab(3);
}