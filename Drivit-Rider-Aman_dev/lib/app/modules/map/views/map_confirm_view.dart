import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:get/get.dart';
import '../../../theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/register/controller/register_controller.dart';
import '../controllers/map_controller.dart';
import '../widgets/confirm_button.dart';
import '../widgets/location_fab.dart';
import '../widgets/app_google_map.dart';

class MapConfirmView extends StatefulWidget {
  const MapConfirmView({super.key});

  @override
  State<MapConfirmView> createState() => _MapConfirmViewState();
}

class _MapConfirmViewState extends State<MapConfirmView> {
  final MapController controller = Get.find<MapController>();
  GoogleMapController? internalMapC;
  Worker? _locationWorker;

  @override
  void initState() {
    super.initState();
    _locationWorker = once(controller.currentPosition, (pos) {
      if (pos != null) {
        controller.moveSafe(internalMapC, pos, 16);
      }
    });
  }

  @override
  void dispose() {
    _locationWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final pos = controller.currentPosition.value;
        if (pos == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
                if (controller.locationError.value != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      controller.locationError.value!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (controller.locationError.value != null)
                  TextButton(
                    onPressed: () => controller.getCurrentLocation(),
                    child: const Text("Retry"),
                  ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: AppGoogleMap(
                center: pos,
                zoom: 16,
                showMarker: false, // Hide the map-layer marker
                interactive: true,
                onTap: (latLng) => controller.pickLocationFromMap(latLng),
                onMapCreated: (ctrl) => internalMapC = ctrl,
                onCameraMove: (camPos) {
                  controller.followUser.value = false;
                  controller.onMapMovedByUser(camPos.target);
                },
              ),
            ),
            
            // Fixed centered pin
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 35),
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.orange,
                    size: 45,
                  ),
                ),
              ),
            ),

            LocationFAB(mapController: internalMapC),
            ConfirmButton(
              onTap: () {
                if (Get.arguments != null && Get.arguments is Map && Get.arguments['returnLocation'] == true) {
                  Get.back(result: {
                    'address': controller.currentAddressSubtitle.value,
                    'lat': controller.pickedLocation.value?.latitude ?? controller.currentPosition.value?.latitude ?? 0.0,
                    'lng': controller.pickedLocation.value?.longitude ?? controller.currentPosition.value?.longitude ?? 0.0,
                  });
                } else if (Get.isRegistered<RegisterController>()) {
                  Get.find<RegisterController>().register();
                } else {
                  Get.toNamed(Routes.carDetails);
                }
              },
            ),
          ],
        );
      }),
    ));
  }
}
