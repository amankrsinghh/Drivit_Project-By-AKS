import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/driver_colors.dart';
import '../../routes/driver_routes.dart';
import '../controllers/driver_trip_controller.dart';
import '../widgets/swipe_button.dart';
import '../../common/widgets/app_google_map.dart';
import '../../../services/api_service.dart';

class DriverReachDestinationView extends StatefulWidget {
  const DriverReachDestinationView({super.key});

  @override
  State<DriverReachDestinationView> createState() => _DriverReachDestinationViewState();
}

class _DriverReachDestinationViewState extends State<DriverReachDestinationView> {
  final controller = Get.find<DriverTripController>();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final RxDouble _sheetExtent = 0.55.obs;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Obx(() => Stack(
          children: [
            // ===== Map area (Full Screen) =====
            Positioned.fill(
              child: AppGoogleMap(
                key: const ValueKey('reach_destination_map_stable'),
                center: (controller.routeToDropoff.isNotEmpty) 
                    ? controller.routeToDropoff.first 
                    : (controller.displayDriverLat.value != 0 ? LatLng(controller.displayDriverLat.value, controller.displayDriverLng.value) : (controller.dropoffLat.value != 0 ? LatLng(controller.dropoffLat.value, controller.dropoffLng.value) : const LatLng(26.9124, 75.7873))),
                zoom: 13.5,
                markers: {
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: LatLng(controller.displayDriverLat.value, controller.displayDriverLng.value),
                    icon: controller.driverIcon.value ?? BitmapDescriptor.defaultMarker,
                    rotation: controller.rotation.value,
                    anchor: const Offset(0.5, 0.5),
                  ),
                  Marker(
                    markerId: const MarkerId('dropoff'),
                    position: LatLng(controller.dropoffLat.value, controller.dropoffLng.value),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                },
                polylines: {
                  if (controller.routeToDropoff.isNotEmpty)
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: controller.routeToDropoff.toList(),
                      width: 6,
                      color: DriverColors.primary,
                      jointType: JointType.round,
                    ),
                },
                interactive: true,
                myLocationEnabled: false,
                onMapCreated: (c) {},
              ),
            ),

            // Back Button
            Positioned(
              top: top + 10,
              left: 16,
              child: InkWell(
                onTap: controller.goHomeTab,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),

            // Draggable Content Sheet (Repositioned Buttons Inside)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                _sheetExtent.value = notification.extent;
                return true;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.65,
                minChildSize: 0.16,
                maxChildSize: 0.65, // Increased height to prevent scroll cutoff
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                      ],
                    ),
                    child: Column(
                      children: [
                        // Full-surface gesture handle
                        GestureDetector(
                          onVerticalDragUpdate: (details) {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            width: double.infinity,
                            color: Colors.transparent,
                            child: Center(
                              child: Container(
                                width: 65,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                                  child: Column(
                                    children: [
                                      // Dynamic Text
                                      Obx(() => Text(
                                        (controller.tripType.value == 'Round Trip')
                                            ? "Trip Ongoing (Round Trip)"
                                            : (controller.estimatedTime.value == "0 min"
                                                ? "You are near the destination"
                                                : "You will reach destination in ${controller.estimatedTime.value}"),
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                        textAlign: TextAlign.center,
                                      )),
                                      const SizedBox(height: 16),

                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFEEEEEE)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x06000000),
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Obx(() {
                                                  final url = controller.customerImage.value;
                                                  return Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFFEFEFEF),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: ClipOval(
                                                      child: url.isNotEmpty
                                                          ? Image.network(
                                                              ApiService.getImageUrl(url),
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                                  const Icon(Icons.person, color: Colors.grey, size: 24),
                                                            )
                                                          : const Icon(Icons.person, color: Colors.grey, size: 24),
                                                    ),
                                                  );
                                                }),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Obx(() => Text(
                                                            controller.customerName.value,
                                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                                          )),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFFFF3E6),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.star, size: 12, color: Colors.orange),
                                                                const SizedBox(width: 2),
                                                                Obx(() => Text(
                                                                  controller.customerRating.value,
                                                                  style: const TextStyle(
                                                                    color: Colors.orange,
                                                                    fontWeight: FontWeight.w900,
                                                                    fontSize: 12,
                                                                  ),
                                                                )),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Obx(() => Text("${controller.carType.value} / ${controller.carModel.value}", 
                                                        style: const TextStyle(color: Colors.black54, fontSize: 13))),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Obx(() => Text(
                                                      controller.bookingId.value,
                                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                                    )),
                                                    const SizedBox(height: 4),
                                                    const Text("Booking ID", style: TextStyle(color: Colors.black54, fontSize: 13)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                _smallAction(
                                                  Icons.chat_bubble_outline,
                                                  () {
                                                    Get.toNamed(
                                                      DriverRoutes.chat,
                                                      arguments: {
                                                        'rideId': controller.currentRideId.value,
                                                        'name': controller.customerName.value,
                                                        'otherId': controller.customerId.value,
                                                        'profileImage': controller.customerImage.value,
                                                        'rating': controller.customerRating.value,
                                                      },
                                                    );
                                                  },
                                                ),
                                                const SizedBox(width: 12),
                                                _smallAction(Icons.navigation, controller.openGoogleMapsForDropoff),
                                                const SizedBox(width: 12),
                                                _smallAction(Icons.call, controller.callRider),
                                                const SizedBox(width: 12),
                                                _smallAction(Icons.share, controller.shareTrip),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            if (controller.requireCarWash.value) 
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                margin: const EdgeInsets.only(bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50], 
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.cleaning_services, color: Colors.green, size: 18),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Car Wash Requested",
                                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            _locationSection(controller.pickup.value, controller.drop.value),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ===== Bottom buttons (Inside the sheet Column) =====
                        Obx(() {
                          final bool isExpanded = _sheetExtent.value > 0.3;
                          return isExpanded ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SwipeButton(
                                  text: "Arrive At Destination",
                                  onSwipe: controller.completeRide,
                                  backgroundColor: DriverColors.primary,
                                  icon: Icons.keyboard_double_arrow_right,
                                ),
                                const SizedBox(height: 12),
                                SwipeButton(
                                  text: "Cancel Ride",
                                  onSwipe: controller.openReasonDialog,
                                  backgroundColor: const Color(0xFFB84B4B),
                                  textColor: Colors.white,
                                  icon: Icons.keyboard_double_arrow_right,
                                ),
                              ],
                            ),
                          ) : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Loading Overlay
            if (controller.isCompletingRide.value)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: DriverColors.primary),
                        SizedBox(height: 16),
                        Text(
                          "Completing Ride...",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (controller.isCancelling.value)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: DriverColors.primary),
                        SizedBox(height: 16),
                        Text(
                          "Cancelling Ride...",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        )),
      ),
    );
  }

  Widget _smallAction(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.orange),
        ),
      ),
    );
  }

  Widget _locationSection(String pickupVal, String dropoffVal) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, size: 12, color: Colors.green),
                  Container(
                    width: 1.5,
                    height: 28,
                    color: const Color(0xFFE0E0E0),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pickup Location",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickupVal,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 14, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dropoff Location",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoffVal,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
