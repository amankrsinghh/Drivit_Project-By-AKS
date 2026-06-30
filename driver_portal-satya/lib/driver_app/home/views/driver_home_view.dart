import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common/driver_bottom_nav/driver_bottom_nav.dart';
import '../controllers/driver_home_controller.dart';

import '../../finding/views/driver_finding_view.dart';
import '../../history/views/driver_history_view.dart';
import '../../profile/views/driver_profile_view.dart';
import '../../package/views/driver_package_view.dart';
import 'driver_home_tab_view.dart';

class DriverHomeView extends GetView<DriverHomeController> {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Obx(() => PopScope(
        canPop: controller.index.value == 0,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (controller.index.value != 0) {
            controller.setIndex(0);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Obx(() {
            final idx = controller.index.value;
            return Stack(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, opacity, child) {
                    return Opacity(opacity: opacity, child: child);
                  },
                  child: IndexedStack(
                    index: idx,
                    children: const [
                      DriverHomeTabView(),
                      DriverPackageView(),
                      DriverFindingView(),
                      DriverHistoryView(),
                      DriverProfileView(),
                    ],
                  ),
                ),
                
                // Floating Active Ride Card (Shows on all dashboard tabs)
                Obx(() {
                  final ride = controller.activeTrip.value;
                  if (ride == null) return const SizedBox.shrink();
                  
                  final bookingId = ride['booking_id']?.toString() ?? "";
                  final String displayId = bookingId.isNotEmpty 
                      ? bookingId 
                      : "RID${(ride['_id']?.toString() ?? '').substring((ride['_id']?.toString() ?? '').length - 8).toUpperCase()}";
                  
                  final currentIdx = controller.index.value;
                  
                  return Positioned(
                    left: 16,
                    right: 16,
                    bottom: currentIdx == 0 ? 116 : 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: controller.resumeActiveTrip,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 226, 139, 9), // Vibrant premium orange
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Active Trip is Live",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Booking ID: $displayId • Tap to resume",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
          bottomNavigationBar: const DriverBottomNav(),
        ),
      )),
    );
  }
}
