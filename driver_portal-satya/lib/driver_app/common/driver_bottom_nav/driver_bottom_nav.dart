

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/controllers/driver_home_controller.dart';
import '../../theme/driver_colors.dart';

class DriverBottomNav extends GetView<DriverHomeController> {
  const DriverBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Obx(() {
        return BottomNavigationBar(
          currentIndex: controller.index.value,
          onTap: controller.setIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: DriverColors.primary,
          unselectedItemColor: const Color(0xFF888888),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          type: BottomNavigationBarType.fixed,
          iconSize: 30,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Package'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Finding'),
            BottomNavigationBarItem(icon: Icon(Icons.work_history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        );
      }),
    );
  }
}