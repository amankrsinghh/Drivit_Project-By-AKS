import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../modules/home/controllers/home_controller.dart';
import 'bottom_nav_item.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  HomeController _homeC() {
    return Get.find<HomeController>();
  }

  Future<void> _goToTab(int index) async {
    try {
      final homeC = _homeC();
      
      // Close all overlays (dialogs, snackbars, etc.) without while loop to avoid hangs
      if (Get.isOverlaysOpen) {
        Get.closeAllSnackbars();
        // Close one layer of dialogs or bottom sheets if open
        if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
          Get.back();
        }
      }

      if (homeC.selectedIndex.value == index && (Get.currentRoute == Routes.home || Get.currentRoute == "/")) {
        return;
      }

      // Navigate
      if (Get.currentRoute != Routes.home && Get.currentRoute != "/") {
        homeC.changeTab(index);
        Get.offAllNamed(Routes.home, arguments: {'tab': index});
      } else {
        homeC.changeTab(index);
      }
    } catch (e) {
      debugPrint("Nav Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeC = _homeC();

    return Obx(
      () => Container(
        height: 100, // Increased height for more space
        padding: const EdgeInsets.only(top: 10, bottom: 20), // Added top/bottom padding for centered feel
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavItem(
              icon: Icons.home_rounded,
              label: "Home",
              active: homeC.selectedIndex.value == 0,
              onTap: () => _goToTab(0),
            ),
            BottomNavItem(
              icon: Icons.directions_car_rounded,
              label: "My Ride",
              active: homeC.selectedIndex.value == 1,
              onTap: () => _goToTab(1),
            ),
            BottomNavItem(
              icon: Icons.person_rounded,
              label: "Profile",
              active: homeC.selectedIndex.value == 2,
              onTap: () => _goToTab(2),
            ),
          ],
        ),
      ),
    );
  }
}
