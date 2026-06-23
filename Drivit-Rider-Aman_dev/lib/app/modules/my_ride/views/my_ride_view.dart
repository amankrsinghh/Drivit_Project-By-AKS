import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/my_ride_controller.dart';
import '../models/ride_items.dart';
import '../widgets/ride_card.dart';
import '../widgets/ride_segmented.dart';

class MyRideView extends StatelessWidget {
  const MyRideView({super.key});

  MyRideController get controller => Get.isRegistered<MyRideController>()
      ? Get.find<MyRideController>()
      : Get.put(MyRideController());

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // White Header
          Container(
            color: Colors.white,
            child: const SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  "History",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
          ),

          // Fixed Segmented Control
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: RideSegmented(),
          ),

          // Scrollable List with PageView for Swipe Navigation
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: (index) {
                controller.segment.value = index == 0
                    ? RideSegment.past
                    : RideSegment.scheduled;
              },
              children: [
                // Page 0: Past Trips
                _buildRideList(controller, RideSegment.past),
                // Page 1: Scheduled Trips
                _buildRideList(controller, RideSegment.scheduled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideList(MyRideController controller, RideSegment segment) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFF38900)),
        );
      }

      final list = segment == RideSegment.past
          ? controller.pastTrips
          : controller.scheduledTrips;

      return RefreshIndicator(
        onRefresh: () => controller.fetchMyRides(),
        color: const Color(0xFFF38900),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
          children: list.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 150),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car_filled_outlined,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          segment == RideSegment.past
                              ? "No trips found"
                              : "No scheduled trips found",
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : segment == RideSegment.past
              ? [
                  _buildSection(list, "Today"),
                  _buildSection(list, "This Week"),
                  _buildSection(list, "This Month"),
                ]
              : [
                  _buildSection(list, "Today", useScheduledSection: true),
                  _buildSection(list, "This Week", useScheduledSection: true),
                  _buildSection(list, "This Month", useScheduledSection: true),
                ],
        ),
      );
    });
  }

  Widget _buildSection(
    List<RideItem> list,
    String title, {
    bool useScheduledSection = false,
  }) {
    final items = list
        .where(
          (e) => useScheduledSection
              ? e.scheduledSection == title
              : e.section == title,
        )
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 15),
        ...items.map((e) => RideCard(item: e)),
      ],
    );
  }
}
