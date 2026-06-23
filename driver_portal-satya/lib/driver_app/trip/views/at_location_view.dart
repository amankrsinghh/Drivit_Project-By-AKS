import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../../theme/driver_colors.dart';
import '../controllers/driver_trip_controller.dart';
import '../../common/widgets/app_google_map.dart';
import '../widgets/swipe_button.dart';

class AtLocationView extends StatefulWidget {
  const AtLocationView({super.key});

  @override
  State<AtLocationView> createState() => _AtLocationViewState();
}

class _AtLocationViewState extends State<AtLocationView> {
  final DriverTripController controller = Get.find<DriverTripController>();
  GoogleMapController? _mapController;
  final _markersSet = <Marker>{}.obs;

  @override
  void initState() {
    super.initState();
    controller.displayDriverLat.listen((_) => _updateMarkers());
    controller.displayDriverLng.listen((_) => _updateMarkers());
    controller.rotation.listen((_) => _updateMarkers());
    controller.driverIcon.listen((_) => _updateMarkers());
    
    // Fit bounds for destination path too
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
    _updateMarkers();
  }

  void _updateMarkers() {
    final pickupPos = LatLng(controller.pickupLat.value, controller.pickupLng.value);
    final markers = <Marker>{
      if (controller.pickupLat.value != 0)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Rider: ${controller.customerName.value}'),
          zIndexInt: 50,
        ),
      if (controller.displayDriverLat.value != 0)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(controller.displayDriverLat.value, controller.displayDriverLng.value),
          icon: controller.driverIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: controller.rotation.value, 
          zIndexInt: 100,
        ),
    };
    _markersSet.assignAll(markers);
  }

  void _fitBounds() {
    final List<LatLng> points = [
      if (controller.pickupLat.value != 0) LatLng(controller.pickupLat.value, controller.pickupLng.value),
      if (controller.displayDriverLat.value != 0) LatLng(controller.displayDriverLat.value, controller.displayDriverLng.value),
    ];
    
    if (points.length < 2) return;

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
        70,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Map Area
            Positioned.fill(
              child: Obx(() => AppGoogleMap(
                center: controller.pickupLat.value != 0 
                  ? LatLng(controller.pickupLat.value, controller.pickupLng.value) 
                  : const LatLng(0, 0),
                zoom: 14.5,
                markers: _markersSet.toSet(),
                polylines: const {}, // Removed route to dropoff
                onMapCreated: (c) {
                  _mapController = c;
                  _fitBounds();
                },
              )),
            ),

            // Bottom UI
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.35,
              maxChildSize: 0.5,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                                      margin: const EdgeInsets.symmetric(vertical: 12),
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  
                                  const Text("Arrived at pickup location",
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Please verify customer OTP to start the trip.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.black54, fontSize: 12),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Obx(() {
                                    if (!controller.requireCarWash.value) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.cleaning_services, color: Colors.green, size: 20),
                                          SizedBox(width: 10),
                                          Text("CAR WASH REQUESTED", 
                                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: SwipeButton(
                          text: "Continue to Quick Check",
                          onSwipe: () {
                            controller.goQuickCheck();
                            return true;
                          },
                          backgroundColor: DriverColors.primary,
                          icon: Icons.keyboard_double_arrow_right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
}