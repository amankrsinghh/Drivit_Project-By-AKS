import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/driver_finding_controller.dart';
import '../../home/controllers/driver_home_controller.dart';
import 'package:lottie/lottie.dart' hide Marker;

class DriverFindingView extends StatefulWidget {
  const DriverFindingView({super.key});

  @override
  State<DriverFindingView> createState() => _DriverFindingViewState();
}

class _DriverFindingViewState extends State<DriverFindingView> {
  final c = Get.find<DriverFindingController>();
  Set<Marker> _currentMarkers = {};
  StreamSubscription? _posSub;

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#212121" }]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#212121" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{ "color": "#757575" }]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#9e9e9e" }]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{ "color": "#181818" }]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{ "color": "#181818" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#2c2c2c" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#8a8a8a" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{ "color": "#3c3c3c" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "#000000" }]
  }
]
  ''';

  @override
  void initState() {
    super.initState();
    _posSub = c.displayLat.listen((_) => _updateMarkers());
    c.displayLng.listen((_) => _updateMarkers());
    c.rotation.listen((_) => _updateMarkers());
    c.driverIcon.listen((_) => _updateMarkers());
    c.nearbyRequests.listen((_) => _updateMarkers());
    _updateMarkers();
  }

  void _updateMarkers() {
    if (!mounted) return;
    final markers = <Marker>{};

    for (int i = 0; i < c.nearbyRequests.length; i++) {
      markers.add(Marker(
        markerId: MarkerId('request_$i'),
        position: c.nearbyRequests[i],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(title: 'Nearby Ride Request'),
      ));
    }

    setState(() {
      _currentMarkers = markers;
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<DriverHomeController>();

    return Obx(() {
      final online = homeController.isOnline.value;

      return Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              key: const ValueKey('driver_finding_map_stable'),
              initialCameraPosition: CameraPosition(
                target: LatLng(c.lat.value, c.lng.value),
                zoom: 15,
              ),
              onMapCreated: (ctrl) {
                c.mapController = ctrl;
              },
              markers: _currentMarkers,
              onCameraMove: (camPos) {
                c.isFollowing.value = false;
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              style: _darkMapStyle,
            ),
          ),
          if (!online)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          color: Colors.redAccent,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "You are Offline",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "You must go online to start searching and receiving ride requests.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => homeController.toggleOnline(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Go Online",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else ...[
            IgnorePointer(
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/finding.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE6E6E6), width: 1),
                    bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE5E5),
                        shape: BoxShape.circle,
                      ),
                      child: Lottie.asset(
                        'assets/lottie/finding.json',
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Waiting for request",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "finding rides nearby you",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(() {
                      if (c.isLoadingLocation.value) {
                        return const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return InkWell(
                        onTap: c.getCurrentLocation,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Icon(Icons.my_location, size: 20),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }
}
