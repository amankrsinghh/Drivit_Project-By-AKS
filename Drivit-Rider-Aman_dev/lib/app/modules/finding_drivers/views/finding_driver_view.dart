import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

import '../../map/controllers/map_controller.dart';
import '../../map/widgets/app_google_map.dart';
import '../controllers/finding_driver_controller.dart';
import '../widgets/driver_bottom_sheet.dart';
import '../../map/widgets/location_fab.dart';

class FindingDriverView extends StatefulWidget {
  const FindingDriverView({super.key});

  @override
  State<FindingDriverView> createState() => _FindingDriverViewState();
}

class _FindingDriverViewState extends State<FindingDriverView> {
  final FindingDriverController controller = Get.find<FindingDriverController>();
  final MapController mapC = Get.find<MapController>();
  GoogleMapController? internalMapC;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mapC.currentPosition.value != null && internalMapC != null) {
        mapC.moveSafe(internalMapC, mapC.currentPosition.value!, 15.5);
      }
    });
  }

  @override
  void dispose() {
    controller.detachMapController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (controller.stage.value != BookingStage.finding) {
          if (controller.stage.value == BookingStage.tripCompleted) {
            Get.snackbar(
              "Payment Pending",
              "Please make payment to complete the ride.",
              backgroundColor: Colors.redAccent,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
            return;
          }
          Get.snackbar(
            "Active Ride",
            "You cannot leave this screen during an active ride.",
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
        controller.stopAll();
        Get.back();
      },
      child: Scaffold(
        body: Obx(() {
          // Robust center logic: Current position -> Pickup position -> Fallback (0,0 or default)
          LatLng? centerPos = mapC.currentPosition.value;
          if (centerPos == null && controller.pickupLat.value != 0) {
            centerPos = LatLng(controller.pickupLat.value, controller.pickupLng.value);
          }
          
          if (centerPos == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          // Build markers
          final markers = <Marker>{};

          // Pickup marker (Shown until trip starts)
          if (controller.pickupLat.value != 0 && controller.stage.value != BookingStage.tripStarted) {
            markers.add(
              Marker(
                markerId: const MarkerId('pickup'),
                position: LatLng(controller.pickupLat.value, controller.pickupLng.value),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                infoWindow: InfoWindow(title: "Pickup: ${controller.pickup.value}"),
              ),
            );
          }

          // Driver marker (using raw coordinates for 'exact' position as requested)
          if (controller.stage.value != BookingStage.finding && controller.driverLat.value != 0) {
            markers.add(
              Marker(
                markerId: const MarkerId('driver'),
                position: LatLng(controller.driverLat.value, controller.driverLng.value),
                icon: controller.driverIcon.value ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                anchor: const Offset(0.5, 0.5),
                flat: true,
                rotation: controller.displayDriverRotation.value,
                zIndexInt: 100,
              ),
            );
          }

          // Destination marker (Shown only once trip starts)
          if (controller.stage.value == BookingStage.tripStarted && controller.dropoffLat.value != 0) {
            markers.add(
              Marker(
                markerId: const MarkerId('dropoff'),
                position: LatLng(controller.dropoffLat.value, controller.dropoffLng.value),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: 'Destination: ${controller.destination.value}'),
                zIndexInt: 50,
              ),
            );
          }

          // Build polylines
          final polylines = <Polyline>{};

          // Routing polylines
          if (controller.stage.value == BookingStage.accepted || 
              controller.stage.value == BookingStage.arrived ||
              controller.stage.value == BookingStage.tripStarted) {
            
            // Driver → Pickup (Only in Accepted stage)
            if (controller.routeToPickup.isNotEmpty && controller.stage.value == BookingStage.accepted) {
              polylines.add(
                Polyline(
                  polylineId: const PolylineId('route_pickup'),
                  points: controller.routeToPickup.toList(),
                  width: 6,
                  color: Colors.orange,
                  jointType: JointType.round,
                ),
              );
            }
 
            // Pickup → Destination (Only in tripStarted stage)
            if (controller.routeToDropoff.isNotEmpty && 
                controller.stage.value == BookingStage.tripStarted) {
              polylines.add(
                Polyline(
                  polylineId: const PolylineId('route_dropoff'),
                  points: controller.routeToDropoff.toList(),
                  width: 6,
                  color: Colors.orange,
                  jointType: JointType.round,
                ),
              );
            }
          }

          // Full actual path taken (Show after completion)
          if (controller.stage.value == BookingStage.tripCompleted && controller.actualPath.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('full_actual_path'),
                points: controller.actualPath.toList(),
                width: 6,
                color: Colors.blueAccent,
                jointType: JointType.round,
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: AppGoogleMap(
                  key: const PageStorageKey('finding_driver_map'),
                  center: centerPos,
                  zoom: 15.5,
                  interactive: true,
                  allowZoom: true,
                  showMarker: false,
                  myLocationEnabled: controller.stage.value == BookingStage.finding,
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (ctrl) {
                    internalMapC = ctrl;
                    controller.attachMapController(ctrl);
                  },
                ),
              ),

              // Floating Location Button
              LocationFAB(
                bottom: 310, // Consistent with SelectRide page
                right: 16,
                mapController: internalMapC,
              ),

              // Finding stage bottom overlay
              Positioned(
                left: 16,
                right: 16,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
                child: Obx(() {
                  final stage = controller.stage.value;
                  if (stage == BookingStage.finding) {
                    return const DriverBottomSheet();
                  }
                  return const SizedBox.shrink();
                }),
              ),

              // Other stages draggable bottom sheet
              Positioned.fill(
                child: Obx(() {
                  final stage = controller.stage.value;
                  if (stage != BookingStage.finding) {
                    return const DriverBottomSheet();
                  }
                  return const SizedBox.shrink();
                }),
              ),

              // Floating Exit Button (Removed to prevent going back before payment is made)
            ],
          );
        }),
      ),
    );
  }
}
