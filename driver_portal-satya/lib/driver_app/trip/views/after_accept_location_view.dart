import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../theme/driver_colors.dart';
import '../widgets/cancel_request_dialog.dart';
import '../../routes/driver_routes.dart';
import '../controllers/driver_trip_controller.dart';
import '../../common/widgets/app_google_map.dart';
import '../../../services/api_service.dart';
import '../widgets/swipe_button.dart';

class DriverAfterAcceptLocationView extends StatefulWidget {
  const DriverAfterAcceptLocationView({super.key});

  @override
  State<DriverAfterAcceptLocationView> createState() =>
      _DriverAfterAcceptLocationViewState();
}

class _DriverAfterAcceptLocationViewState
    extends State<DriverAfterAcceptLocationView> {
  final DriverTripController ctrl = Get.find<DriverTripController>();
  GoogleMapController? _mapController;
  StreamSubscription? _posSub;
  Worker? _fitBoundsWorker;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final RxDouble _sheetExtent = 0.55.obs;

  @override
  void initState() {
    super.initState();
    // 1. High-frequency listeners for markers only
    _posSub = ctrl.displayDriverLat.listen((_) => _updateMarkers());
    ctrl.displayDriverLng.listen((_) => _updateMarkers());
    ctrl.rotation.listen((_) => _updateMarkers());
    ctrl.driverIcon.listen((_) => _updateMarkers());
    // Listener removed

    // 2. Initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });

    // 3. Stable listeners for camera
    _fitBoundsWorker = ever(ctrl.routeToPickup, (_) => _fitBounds());

    _updateMarkers();
  }

  void _updateMarkers() {
    // Moved to reactive Obx builder for fresh logic consistency with Rider app
  }

  void _fitBounds() {
    if (ctrl.routeToPickup.isEmpty) {
      if (ctrl.pickupLat.value != 0 && ctrl.pickupLng.value != 0) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(ctrl.pickupLat.value, ctrl.pickupLng.value),
            14.5,
          ),
        );
      }
      return;
    }

    final points = ctrl.routeToPickup;
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _fitBoundsWorker?.dispose();
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ===== Map area (Full Screen) =====
            Positioned.fill(
              child: Obx(() {
                // FRESH LOGIC: 1. Calculate Real-time Distance to Rider
                final dLat = ctrl.displayDriverLat.value != 0
                    ? ctrl.displayDriverLat.value
                    : ctrl.driverLat.value;
                final dLng = ctrl.displayDriverLng.value != 0
                    ? ctrl.displayDriverLng.value
                    : ctrl.driverLng.value;
                final pLat = ctrl.pickupLat.value;
                final pLng = ctrl.pickupLng.value;

                double distToRider = double.infinity;
                if (dLat != 0 && pLat != 0 && pLat != 1) {
                  distToRider = Geolocator.distanceBetween(
                    dLat,
                    dLng,
                    pLat,
                    pLng,
                  );
                }

                // FRESH LOGIC: 2. Only show Route if Driver is NOT near Pickup (> 20 meters)
                final bool showRouteToPickup = distToRider > 20.0;

                debugPrint(
                  "🔥[DEBUG_BUG_VIEW] AppGoogleMap Builder Executing...",
                );
                debugPrint(
                  "🔥[DEBUG_BUG_VIEW] Driver: ($dLat, $dLng) | Pickup: ($pLat, $pLng) | Dest was (${ctrl.dropoffLat.value}, ${ctrl.dropoffLng.value})",
                );
                debugPrint(
                  "🔥[DEBUG_BUG_VIEW] Distance to Pickup: $distToRider meters. Show Route: $showRouteToPickup",
                );
                debugPrint(
                  "🔥[DEBUG_BUG_VIEW] routeToPickup Length: ${ctrl.routeToPickup.length} points",
                );

                // FRESH LOGIC: 3. Create fresh markers state
                final markers = <Marker>{};
                if (pLat != 0 && pLat != 1) {
                  markers.add(
                    Marker(
                      markerId: const MarkerId('pickup_rider_marker'),
                      position: LatLng(pLat, pLng),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ), // Matches Rider App
                      infoWindow: InfoWindow(
                        title: 'Rider: ${ctrl.customerName.value}',
                      ),
                      zIndexInt: 50,
                    ),
                  );
                }

                if (dLat != 0) {
                  markers.add(
                    Marker(
                      markerId: const MarkerId('driver_marker'),
                      position: LatLng(dLat, dLng),
                      icon:
                          ctrl.driverIcon.value ??
                          BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                      anchor: const Offset(0.5, 0.5),
                      flat: true,
                      rotation: ctrl.rotation.value,
                      zIndexInt: 100, // Ensure car is on top
                    ),
                  );
                }

                // FRESH LOGIC: 4. Create fresh polyline state (Strictly Driver -> Pickup ONLY)
                final polylines = <Polyline>{};
                if (showRouteToPickup && ctrl.routeToPickup.isNotEmpty) {
                  debugPrint(
                    "🔥[DEBUG_BUG_VIEW] ADDING POLYLINE (Driver to Pickup) to map!",
                  );
                  polylines.add(
                    Polyline(
                      polylineId: PolylineId(
                        'strict_route_pickup_${ctrl.currentRideId.value}_${DateTime.now().millisecondsSinceEpoch ~/ 10000}',
                      ), // Defeats caching entirely
                      points: ctrl.routeToPickup.toList(),
                      width: 6,
                      color: Colors
                          .orange, // Standard driver -> pickup color matching Rider App
                      jointType: JointType.round,
                    ),
                  );
                } else {
                  debugPrint(
                    "🔥[DEBUG_BUG_VIEW] NOT SHOWING POLYLINE. showRoute=$showRouteToPickup, routeLen=${ctrl.routeToPickup.length}",
                  );
                }

                return AppGoogleMap(
                  key: ValueKey(
                    'after_accept_map_${ctrl.currentRideId.value}',
                  ), // Fresh unique key
                  center: pLat != 0 && pLat != 1
                      ? LatLng(pLat, pLng)
                      : const LatLng(26.9124, 75.7873),
                  zoom: 14.5,
                  markers: markers,
                  polylines: polylines,
                  interactive: true,
                  myLocationEnabled: false,
                  onMapCreated: (c) {
                    _mapController = c;
                    _fitBounds();
                  },
                );
              }),
            ),

            // ===== Draggable Content Sheet =====
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                _sheetExtent.value = notification.extent;
                return true;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.65,
                minChildSize:
                    0.12, // Reduced to show only the 'reach location' text
                maxChildSize: 0.65, // Increased height to prevent scroll cutoff
                snap: true,
                snapSizes: const [0.12, 0.65],
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Pull handle
                                    Center(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 15,
                                        ),
                                        width: 65,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Obx(
                                        () => Text(
                                          ctrl.estimatedTime.value == "0 min"
                                              ? "You are near the pickup location"
                                              : "You will reach pickup location in ${ctrl.estimatedTime.value}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            color: DriverColors.text,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                  ],
                                ),
                              ),

                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  140,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Obx(() {
                                    // Conditional visibility based on sheet expansion
                                    final bool isExpanded =
                                        _sheetExtent.value > 0.3;

                                    return AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      opacity: isExpanded ? 1.0 : 0.0,
                                      child: isExpanded
                                          ? Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFEEEEEE,
                                                      ),
                                                    ),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Color(
                                                          0x06000000,
                                                        ),
                                                        blurRadius: 12,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Obx(() {
                                                            final url = ctrl
                                                                .customerImage
                                                                .value;
                                                            return Container(
                                                              width: 44,
                                                              height: 44,
                                                              decoration:
                                                                  const BoxDecoration(
                                                                    color: Color(
                                                                      0xFFEFEFEF,
                                                                    ),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                              child: ClipOval(
                                                                child:
                                                                    url.isNotEmpty
                                                                    ? Image.network(
                                                                        ApiService.getImageUrl(
                                                                          url,
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder:
                                                                            (
                                                                              context,
                                                                              error,
                                                                              stackTrace,
                                                                            ) => const Icon(
                                                                              Icons.person,
                                                                              color: Colors.grey,
                                                                              size: 24,
                                                                            ),
                                                                      )
                                                                    : const Icon(
                                                                        Icons
                                                                            .person,
                                                                        color: Colors
                                                                            .grey,
                                                                        size:
                                                                            24,
                                                                      ),
                                                              ),
                                                            );
                                                          }),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Obx(
                                                                      () => Text(
                                                                        ctrl
                                                                            .customerName
                                                                            .value,
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.w900,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                      decoration: BoxDecoration(
                                                                        color: const Color(
                                                                          0xFFFFF3E6,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              12,
                                                                            ),
                                                                      ),
                                                                      child: Row(
                                                                        children: [
                                                                          const Icon(
                                                                            Icons.star,
                                                                            size:
                                                                                12,
                                                                            color:
                                                                                Colors.orange,
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                2,
                                                                          ),
                                                                          Obx(
                                                                            () => Text(
                                                                              ctrl.customerRating.value,
                                                                              style: const TextStyle(
                                                                                color: Colors.orange,
                                                                                fontWeight: FontWeight.w900,
                                                                                fontSize: 12,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Obx(
                                                                  () => Text(
                                                                    "${ctrl.carType.value} / ${ctrl.carModel.value}",
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .black54,
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Obx(
                                                                () => Text(
                                                                  ctrl
                                                                      .bookingId
                                                                      .value,
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              const Text(
                                                                "Booking ID",
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .black54,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Row(
                                                        children: [
                                                          _smallAction(
                                                            Icons.chat_bubble_outline,
                                                            () {
                                                              final ctrl =
                                                                  Get.find<
                                                                    DriverTripController
                                                                  >();
                                                              Get.toNamed(
                                                                DriverRoutes
                                                                    .chat,
                                                                arguments: {
                                                                  'rideId': ctrl
                                                                      .currentRideId
                                                                      .value,
                                                                  'name': ctrl
                                                                      .customerName
                                                                      .value,
                                                                  'otherId': ctrl
                                                                      .customerId
                                                                      .value,
                                                                  'profileImage': ctrl
                                                                      .customerImage
                                                                      .value,
                                                                  'rating': ctrl
                                                                      .customerRating
                                                                      .value,
                                                                },
                                                              );
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          _smallAction(
                                                            Icons.navigation,
                                                            ctrl.openGoogleMapsForPickup,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          _smallAction(
                                                            Icons.call,
                                                            ctrl.callRider,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          _smallAction(
                                                            Icons.share,
                                                            ctrl.shareTrip,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      const Divider(height: 1),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Obx(
                                                        () => _locationSection(
                                                          ctrl.pickup.value,
                                                          ctrl.drop.value,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ===== Bottom buttons (pinned to sheet bottom) =====
                        Obx(() {
                          final bool isExpanded = _sheetExtent.value > 0.3;

                          return AnimatedSlide(
                            offset: isExpanded
                                ? Offset.zero
                                : const Offset(0, 1),
                            duration: const Duration(milliseconds: 300),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isExpanded ? 1.0 : 0.0,
                              child: isExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        20,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SwipeButton(
                                            text: "Arrive At Location",
                                            onSwipe: () async {
                                              final success = await ctrl.arriveAtLocation();
                                              if (success) {
                                                Get.toNamed(DriverRoutes.quickCheck);
                                                return true;
                                              }
                                              return false;
                                            },
                                            backgroundColor:
                                                DriverColors.primary,
                                            icon: Icons
                                                .keyboard_double_arrow_right,
                                          ),
                                          const SizedBox(height: 12),
                                          SwipeButton(
                                            text: "Cancel Request",
                                            onSwipe: () async {
                                              final result = await Get.dialog<bool>(
                                                CancelRequestDialog(
                                                  onNo: () => Get.back(result: false),
                                                  onYes: () {
                                                    Get.back(result: true); // close dialog
                                                    ctrl.cancelRideByDriver();
                                                  },
                                                ),
                                                barrierDismissible: false,
                                              );
                                              return result ?? false;
                                            },
                                            backgroundColor: const Color(
                                              0xFFFF3B30,
                                            ),
                                            textColor: Colors.white,
                                            icon: Icons
                                                .keyboard_double_arrow_right,
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _smallAction(IconData icon, VoidCallback onTap) {
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

  static Widget _locationSection(String pickupVal, String dropoffVal) {
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
