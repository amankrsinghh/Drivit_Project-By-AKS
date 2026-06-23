import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:get/get.dart';
import '../controllers/map_controller.dart';

class LocationFAB extends GetView<MapController> {
  final double bottom;
  final double right;
  final GoogleMapController? mapController;

  const LocationFAB({
    super.key,
    this.bottom = 310,
    this.right = 16,
    this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: Obx(
        () => FloatingActionButton(
          backgroundColor: Colors.orange,
          onPressed: controller.isLoadingLocation.value
              ? null
              : () => controller.moveMapToCurrent(mapController),
          child: controller.isLoadingLocation.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
