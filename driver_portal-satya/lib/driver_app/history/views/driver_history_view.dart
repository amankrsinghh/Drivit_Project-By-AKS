import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_history_controller.dart';
import '../models/driver_trip_history_model.dart';

class DriverHistoryView extends StatefulWidget {
  const DriverHistoryView({super.key});

  @override
  State<DriverHistoryView> createState() => _DriverHistoryViewState();
}

class _DriverHistoryViewState extends State<DriverHistoryView> {
  final controller = Get.find<DriverHistoryController>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        controller.fetchRides(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: DriverColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        children: [
          // Orange header
          Container(
            color: DriverColors.primary,
            padding: EdgeInsets.only(top: top),
            child: const SizedBox(
              height: 56,
              child: Center(
                child: Text(
                  "History",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
          ),

          // Tabs (Past / Scheduled)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8), // Refined outer padding
            child: Obx(() {
              final i = controller.tabIndex.value;
              return Container(
                height: 44, // Reduced height for a more compact look
                padding: const EdgeInsets.all(4), // Balanced inner padding
                decoration: BoxDecoration(
                  color: DriverColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _segBtn(
                        selected: i == 0,
                        title: "Past Trips",
                        onTap: () => controller.setTab(0),
                      ),
                    ),
                    Expanded(
                      child: _segBtn(
                        selected: i == 1,
                        title: "Scheduled Trips",
                        onTap: () => controller.setTab(1),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // List with PageView for Swipe Navigation
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: (index) {
                controller.tabIndex.value = index;
              },
              children: [
                // Page 0: Past Trips
                _buildTripList(true),
                // Page 1: Scheduled Trips
                _buildTripList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(bool isPast) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: DriverColors.primary),
        );
      }

      return RefreshIndicator(
        color: DriverColors.primary,
        onRefresh: controller.fetchRides,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: isPast ? _scrollController : null, // Only sync scroll for past trips pagination
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 19),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPast) ...[
                      _buildSection("Today", controller.pastToday),
                      _buildSection("This Week", controller.pastThisWeek),
                      _buildSection("This Month", controller.pastThisMonth),
                      
                      if (controller.pastTrips.isEmpty)
                        _buildEmptyState(true),
                      
                      if (controller.isMoreLoading.value)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: DriverColors.primary),
                          ),
                        ),
                    ] else ...[
                      _buildSection("Today", controller.scheduledToday),
                      _buildSection("This Week", controller.scheduledThisWeek),
                      _buildSection("This Month", controller.scheduledThisMonth),

                      if (controller.scheduledTrips.isEmpty)
                        _buildEmptyState(false),
                    ],
                  ],
                ),
              ),
            );
          }
        ),
      );
    });
  }

  Widget _buildSection(String title, List<DriverTripHistoryModel> trips) {
    if (trips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        ..._buildCards(trips, title.toLowerCase().replaceAll(' ', '_')),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildEmptyState(bool isPast) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.history,
              size: 60,
              color: Colors.black12,
            ),
            const SizedBox(height: 12),
            Text(
              isPast ? 'No trips found' : 'No scheduled trips',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pull down to refresh',
              style: TextStyle(
                color: Colors.black26,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segBtn({
    required bool selected,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14, // Proportional text size
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black : Colors.black45,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCards(List<DriverTripHistoryModel> trips, String section) {
    if (trips.isEmpty) {
      return [
        Text(
          "No trips",
          key: ValueKey("no_trips_$section"),
          style: const TextStyle(color: Colors.black45, fontSize: 18),
        ),
      ];
    }

    return trips
        .map(
          (t) => _TripCard(
            key: ValueKey("${section}_${t.bookingId}"),
            trip: t,
            onTap: () => controller.openDetails(t),
          ),
        )
        .toList();
  }
}

class _TripCard extends StatelessWidget {
  final DriverTripHistoryModel trip;
  final VoidCallback onTap;

  const _TripCard({super.key, required this.trip, required this.onTap});

  Color get statusColor {
    switch (trip.status) {
      case TripStatus.completed:
        return const Color(0xFF2DBE60);
      case TripStatus.canceled:
        return const Color(0xFFFF3B30);
      case TripStatus.upcoming:
        return const Color(0xFFFF9500);
      case TripStatus.expired:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (trip.status) {
      case TripStatus.completed:
        return "Completed";
      case TripStatus.canceled:
        return "Cancelled";
      case TripStatus.upcoming:
        return "Upcoming";
      case TripStatus.expired:
        return "Expired";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.dateLine,
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                ),
                Text(
                  "₹ ${trip.amount}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: DriverColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.pickupShort,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 10, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trip.tripEndAddress,
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: trip.passengerImage != null && trip.passengerImage!.isNotEmpty
                      ? Image.network(
                          ApiService.getImageUrl(trip.passengerImage),
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Image.asset("assets/images/user.png", fit: BoxFit.cover),
                        )
                      : Image.asset("assets/images/user.png", fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.passenger,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
