import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:get/get.dart';
import '../../../../routes/app_routes.dart';
import '../../controllers/map_controller.dart';
import '../../widgets/location_card.dart';
import '../../widgets/location_fab.dart';
import '../../widgets/map_search_bar.dart';
import '../../../../core/services/recent_destinations_service.dart';
import '../../widgets/map_search_result.dart';
import '../../widgets/app_google_map.dart';
import '../../widgets/ride_bottom_sheet.dart';
import '../controllers/select_ride_controller.dart';

class SelectRideView extends StatefulWidget {
  const SelectRideView({super.key});

  @override
  State<SelectRideView> createState() => _SelectRideViewState();
}

class _SelectRideViewState extends State<SelectRideView> {
  final SelectRideController controller = Get.find<SelectRideController>();
  final MapController mapC = Get.find<MapController>();
  GoogleMapController? internalMapC;
  Worker? _locationWorker;

  @override
  void initState() {
    super.initState();

    // Completely disable auto-fill of pickup location.
    // Reset controller and state every time booking page opens.
    controller.pickup.value = "";
    controller.pickupLat.value = 0.0;
    controller.pickupLng.value = 0.0;
    controller.dropoffLat.value = 0.0;
    controller.dropoffLng.value = 0.0;
    controller.totalPrice.value = 0.0;
    controller.isRideBooked.value = false;
    
    mapC.searchTextController.clear();
    mapC.suggestions.clear();
    controller.destination.value = "";
    controller.destinationTextController.clear();
    controller.hasTappedPickupField.value = false;
    controller.isPickupFocused.value = false;
    controller.isDestinationFocused.value = false;
    
    // Trigger an initial calculation to ensure UI reflected the resets
    controller.calculateTotalPrice();

    // Move map when location is initially fetched
    // Move map when location is initially fetched or if already exists
    _locationWorker = once(mapC.userPosition, (pos) {
      if (pos != null) {
        mapC.moveSafe(internalMapC, pos, 15.5);
      }
    });
    
    // If we already have a position, ensure we move there as soon as map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mapC.userPosition.value != null && internalMapC != null) {
        mapC.moveSafe(internalMapC, mapC.userPosition.value!, 15.5);
      }
    });

    // Listen to polylines and fit bounds when a route is drawn
    ever(controller.polylines, (Set<Polyline> polylines) {
      if (polylines.isNotEmpty && internalMapC != null) {
        final points = polylines.first.points;
        if (points.isNotEmpty) {
          double minLat = points.first.latitude;
          double maxLat = points.first.latitude;
          double minLng = points.first.longitude;
          double maxLng = points.first.longitude;

          for (var p in points) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLng) minLng = p.longitude;
            if (p.longitude > maxLng) maxLng = p.longitude;
          }

          internalMapC!.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              70, // padding
            ),
          );
        }
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
    final navBarHeight = MediaQuery.of(context).padding.bottom;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: null,
        body: Stack(
          children: [
            Positioned.fill(
              child: Obx(() => AppGoogleMap(
                key: const PageStorageKey('select_ride_map'),
                center:
                    mapC.currentPosition.value ??
                    const LatLng(26.9124, 75.7873),
                zoom: 15.5,
                padding: EdgeInsets.zero,
                showMarker: false, // Hide the map-layer default marker
                polylines: controller.polylines.toSet(),
                markers: controller.markers.toSet(),
                interactive: true,
                onTap: (latLng) {
                  final userPos = mapC.userPosition.value;
                  if (userPos != null) {
                    final distance = Geolocator.distanceBetween(
                      userPos.latitude,
                      userPos.longitude,
                      latLng.latitude,
                      latLng.longitude,
                    );
                    // Standard tap target tolerance: if they click within 100 meters, snap to their true GPS
                    if (distance < 100) {
                      mapC.pickLocationFromMap(userPos);
                      mapC.moveSafe(internalMapC, userPos, 15.5);
                      return;
                    }
                  }
                  // Otherwise, just dismiss the keyboard, don't pick random locations
                  FocusScope.of(context).unfocus();
                },
                onCameraMove: (camera) {
                  if (controller.isPickupFocused.value || controller.isDestinationFocused.value) {
                    return;
                  }
                  mapC.onMapMovedByUser(camera.target);
                },
                onMapCreated: (ctrl) {
                  if (mounted) {
                    setState(() {
                      internalMapC = ctrl;
                    });
                    // Force move to current location on first load
                    mapC.moveMapToCurrent(ctrl);
                  }
                },
              )),
            ),
            Obx(() {
              final isLoading = mapC.currentPosition.value == null;
              return isLoading
                  ? const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    )
                  : const SizedBox.shrink();
            }),

            // Centered Picker Icon (STAYS FIXED)
            Obx(() => controller.isBothLocationsSelected 
              ? const SizedBox.shrink()
              : const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 35,
                      ), // Align tip to exact center
                      child: Icon(
                        Icons.location_pin,
                        color: Colors.orange,
                        size: 45,
                      ),
                    ),
                  ),
                ),
            ),

            LocationFAB(
              bottom: isKeyboardOpen ? bottomInset + 16 : 310, // Move above keyboard when open
              right: 16,
              mapController: internalMapC,
            ),
            // if (!isKeyboardOpen) RideBottomSheet(navBarHeight: navBarHeight), // Moved to end of Stack

            // Top Left Back Button
            Positioned(
              top: 10 + MediaQuery.of(context).padding.top,
              left: 16,
              child: GestureDetector(
                onTap: () => controller.isRideBooked.value
                    ? Get.offAllNamed(Routes.home)
                    : Get.back(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
              ),
            ),

            RideBottomSheet(navBarHeight: navBarHeight, isKeyboardOpen: isKeyboardOpen),

            // --- SEARCH BARS AT THE VERY END TO BE ON TOP ---
            Positioned(
              top: 65 + MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Obx(() {
                    return Column(
                      children: [
                        MapSearchBar(
                          controller: mapC.searchTextController,
                          focusNode: controller.pickupFocusNode,
                          readOnly: controller.isAirportFlow.value,
                          onChanged: (val) {
                            controller.isManualTypingPickup.value = val.isNotEmpty;
                            mapC.onSearchChanged(val);
                            controller.pickup.value = val;
                          },
                          hintText: "Search Pickup",
                          isLoading: mapC.isSearching.value,
                          onTap: () {
                            if (controller.isAirportFlow.value) return;
                            controller.hasTappedPickupField.value = true;
                            controller.isPickupFocused.value = true;
                            controller.isDestinationFocused.value = false;
                            mapC.suggestions.clear();
                            controller.isManualTypingPickup.value = false;
                            controller.showLocationCardPickup.value = false;
                          },
                        ),
                        if (controller.isPickupFocused.value && !controller.isDestinationFocused.value)
                          Column(
                            children: [
                              if (!controller.showLocationCardPickup.value && !controller.isManualTypingPickup.value) ...[
                                const SizedBox(height: 8),
                                LocationCard(
                                  title: "Current Location",
                                  subtitle: mapC.currentAddressSubtitle.value == "Fetching address..." 
                                      ? "Fetching current location..." 
                                      : mapC.currentAddressSubtitle.value,
                                  onTap: () async {
                                    final pos = mapC.userPosition.value ?? mapC.pickedLocation.value;
                                    if (pos != null) {
                                      await mapC.refreshAddressForLocation(pos);
                                      final addr = mapC.currentAddressSubtitle.value;
                                      
                                      mapC.searchTextController.text = addr;
                                      controller.pickup.value = addr;
                                      controller.pickupLat.value = pos.latitude;
                                      controller.pickupLng.value = pos.longitude;
                                      mapC.moveSafe(internalMapC, pos, 16.0);
                                    }
                                    
                                     controller.isPickupFocused.value = false;
                                    controller.showLocationCardPickup.value = false;
                                    mapC.suggestions.clear();
                                    FocusScope.of(context).requestFocus(controller.destinationFocusNode);
                                  },
                                ),
                              ],
                              if (mapC.suggestions.isNotEmpty) ...[
                                MapSearchResults(
                                  items: mapC.suggestions.toList(),
                                  onTap: (s) async {
                                    controller.isManualTypingPickup.value = false;
                                    await mapC.selectSuggestion(s);
                                    controller.pickup.value = s.displayName;
                                    
                                    controller.isPickupFocused.value = false;
                                    controller.showLocationCardPickup.value = false;
                                    mapC.suggestions.clear();
                                     FocusScope.of(context).requestFocus(controller.destinationFocusNode);
                                    
                                    final latLng = mapC.pickedLocation.value;
                                    if (latLng != null) {
                                      mapC.moveSafe(internalMapC, latLng, 16.0);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        if (controller.isPickupFocused.value && !controller.isManualTypingPickup.value && controller.showLocationCardPickup.value)
                          Column(
                            children: [
                              const SizedBox(height: 8),
                              LocationCard(
                                title: "Confirm Pickup Location",
                                subtitle: mapC.isLoadingAddress.value
                                    ? "Fetching address..."
                                    : mapC.currentAddressSubtitle.value,
                                onTap: () {
                                  final addr = mapC.currentAddressSubtitle.value;
                                  mapC.searchTextController.text = addr;
                                  controller.pickup.value = addr;
                                  controller.pickupLat.value = mapC.pickedLocation.value?.latitude ?? 0;
                                  controller.pickupLng.value = mapC.pickedLocation.value?.longitude ?? 0;
                                  controller.isPickupFocused.value = false;
                                  controller.showLocationCardPickup.value = false;
                                  FocusScope.of(context).unfocus(); // Release cursor
                                },
                              ),
                            ],
                          ),
                      ],
                    );
                  }),
                  Obx(
                    () => Column(
                            children: [
                              const SizedBox(height: 10),
                              MapSearchBar(
                                controller: controller.destinationTextController,
                                readOnly: controller.isAirportFlow.value,
                                onChanged: (val) {
                                  controller.isManualTypingDestination.value = val.isNotEmpty;
                                  controller.onDestinationChanged(val);
                                },
                                hintText: "Where to?",
                                isLoading: controller.isSearchingDestination.value,
                                focusNode: controller.destinationFocusNode,
                                onTap: () {
                                  if (controller.isAirportFlow.value) return;
                                  controller.isPickupFocused.value = false;
                                  controller.isDestinationFocused.value = true;
                                  mapC.suggestions.clear();
                                  controller.destinationSuggestions.clear();
                                  controller.isManualTypingDestination.value = false;
                                  controller.showLocationCardDestination.value = false;
                                },
                              ),
                              // RECENT DESTINATIONS (show when focused, not typing, no map pin card)
                              if (controller.isDestinationFocused.value &&
                                  !controller.isManualTypingDestination.value &&
                                  !controller.showLocationCardDestination.value &&
                                  controller.recentDestinations.isNotEmpty)
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                                            child: Text(
                                              "Recent Destinations",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          ...controller.recentDestinations.take(3).map((d) => InkWell(
                                            onTap: () {
                                              controller.selectRecentDestination(d);
                                              FocusScope.of(context).unfocus();
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.history, size: 20, color: Colors.grey.shade500),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      d.name,
                                                      style: const TextStyle(fontSize: 14),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )),
                                          const SizedBox(height: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              if (controller.isDestinationFocused.value && controller.isManualTypingDestination.value && controller.destinationSuggestions.isNotEmpty)
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    MapSearchResults(
                                      items: controller.destinationSuggestions.toList(),
                                      onTap: (s) async {
                                        controller.isManualTypingDestination.value = false;
                                        await controller.selectDestinationSuggestion(s);
                                        controller.isDestinationFocused.value = false;
                                        FocusScope.of(context).unfocus();
                                        final latLng = mapC.pickedLocation.value;
                                        if (latLng != null) {
                                          mapC.moveSafe(internalMapC, latLng, 16.0);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              if (controller.isDestinationFocused.value && !controller.isManualTypingDestination.value && controller.showLocationCardDestination.value)
                                Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    LocationCard(
                                      title: "Confirm Destination Location",
                                      subtitle: mapC.isLoadingAddress.value
                                          ? "Fetching address..."
                                          : mapC.currentAddressSubtitle.value,
                                      onTap: () {
                                        final addr = mapC.currentAddressSubtitle.value;
                                        controller.destinationTextController.text = addr;
                                        controller.destination.value = addr;
                                        controller.dropoffLat.value = mapC.pickedLocation.value?.latitude ?? 0;
                                        controller.dropoffLng.value = mapC.pickedLocation.value?.longitude ?? 0;
                                        controller.isDestinationFocused.value = false;
                                        controller.showLocationCardDestination.value = false;
                                        controller.saveRecentDestination(
                                          addr,
                                          mapC.pickedLocation.value?.latitude ?? 0,
                                          mapC.pickedLocation.value?.longitude ?? 0,
                                        );
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
