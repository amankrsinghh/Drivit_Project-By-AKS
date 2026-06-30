import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/map_controller.dart';
import '../select_ride/controllers/select_ride_controller.dart';
import '../../../theme/app_colors.dart';


class RideBottomSheet extends StatefulWidget {
  final double navBarHeight;
  final bool isKeyboardOpen;
  const RideBottomSheet({super.key, this.navBarHeight = 0, this.isKeyboardOpen = false});

  @override
  State<RideBottomSheet> createState() => _RideBottomSheetState();
}

class _RideBottomSheetState extends State<RideBottomSheet> {
  final SelectRideController controller = Get.find<SelectRideController>();

  @override
  void didUpdateWidget(covariant RideBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isKeyboardOpen != oldWidget.isKeyboardOpen &&
        controller.sheetController.isAttached) {
      if (widget.isKeyboardOpen) {
        if (controller.travelPlanFocusNode.hasFocus) {
          // If the travel plan details field is focused, keep/animate sheet to expanded 0.72 snap level
          controller.sheetController.animateTo(
            0.72,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          // Keyboard open -> move down to minimum for other flows
          controller.sheetController.animateTo(
            0.3, 
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        // Keyboard closed -> return to appropriate "default" position
        // Only return if it's currently at or below the minimum (meaning it was moved by keyboard)
        // or if both locations are selected (to maintain the 0.72 state)
        final target = controller.isBothLocationsSelected ? 0.72 : 0.6;
        controller.sheetController.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        controller.sheetExtent.value = notification.extent;
        return true;
      },
      child: DraggableScrollableSheet(
        controller: controller.sheetController,
        initialChildSize: 0.6, // Start partially expanded
        minChildSize: 0.3,     // minimum collapse
        maxChildSize: 0.72,      // Stopped exactly below the search bars
        snap: true,
        snapSizes: const [0.3, 0.6, 0.72],
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                // Top Handle Area - Integrated into scrollController for dragging
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                width: 45,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Book Your Ride",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Obx(() {
                              if (controller.isAirportFlow.value) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  _buildCarSelection(),
                                  const SizedBox(height: 12),
                                  _buildCarWashSelection(),
                                  const SizedBox(height: 12),
                                  if (controller.isOutstationFlow.value) ...[
                                    _buildTripTypeSelection(),
                                    const SizedBox(height: 12),
                                  ],
                                  if (!controller.isAirportFlow.value) ...[
                                    _buildPackageSelection(),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              );
                            }),
                            Obx(() {
                              final double maxRange = controller.isOutstationFlow.value 
                                  ? controller.outstationMaxRange.value 
                                  : controller.rideRequestRadius.value;
                              final isOutOfRange = controller.isBothLocationsSelected &&
                                  controller.calculatedDistance.value > maxRange;
                              
                              if (isOutOfRange) {
                                return _buildNotServiceableCard();
                              }
                              
                              if (controller.isAirportFlow.value) {
                                return _buildAirportPricingList();
                              }
                              return _buildPriceSummaryCard();
                            }),
                            const SizedBox(height: 12),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                // Fixed Bottom Bar
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + widget.navBarHeight),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 10,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: _buildBottomBar(),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }



  Widget _buildCarSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vehicle Selection",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Obx(() => controller.hasProfileTransmission.value
            ? _buildDropdown(
                icon: Icons.directions_car,
                value: controller.selectedCarModel.value,
                items: controller.carModelsList,
                profileValue: controller.profileCarModel.value,
                onChanged: (val) => controller.selectedCarModel.value = val!,
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      icon: Icons.settings,
                      value: controller.selectedCar.value,
                      items: controller.carCategories,
                      onChanged: (val) => controller.selectedCar.value = val!,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDropdown(
                      icon: Icons.directions_car,
                      value: controller.selectedCarModel.value,
                      items: controller.carModelsList,
                      profileValue: controller.profileCarModel.value,
                      onChanged: (val) => controller.selectedCarModel.value = val!,
                    ),
                  ),
                ],
              )),
      ],
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? profileValue,
  }) {
    // Prevent dropdown crash if value is not in the items list
    final List<String> safeItems = List<String>.from(items);
    if (value.isNotEmpty && !safeItems.contains(value)) {
      safeItems.add(value);
    }
    if (profileValue != null && profileValue.isNotEmpty && !safeItems.contains(profileValue)) {
      safeItems.add(profileValue);
    }
    // Fallback: If value is empty or not in items after fallback, use the first item if available
    final String selectedValue = (value.isNotEmpty && safeItems.contains(value))
        ? value
        : (safeItems.isNotEmpty ? safeItems.first : "");

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue.isEmpty ? null : selectedValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          items: safeItems.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTripTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trip Type",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isLoadingTripTypes.value) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: CircularProgressIndicator(color: Colors.orange)),
            );
          }
          if (controller.tripTypesList.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("No trip types available"),
            );
          }

          final filteredList = controller.tripTypesList.where((type) {
            final name = type['name'].toString().trim().toLowerCase();
            if (controller.isOutstationFlow.value) {
              return name == 'one way' || name == 'round trip';
            } else {
              return name == 'local';
            }
          }).toList();

          return Row(
            children: filteredList.map((type) {
              final name = type['name'];
              final desc = type['description'] ?? "";

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildTripTypeCard(
                    title: name,
                    subtitle: desc,
                    isSelected: controller.tripType.value == name,
                    onTap: () => controller.tripType.value = name,
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildTripTypeCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.orange.shade900 : Colors.black,
                    ),
                    softWrap: true,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.orange, size: 18),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final bool useDays = controller.tripType.value == "Round Trip" && !controller.outstationRoundUseEstimatedHours.value;
          if (useDays) {
            return const Text(
              "Duration & Itinerary",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            );
          } else {
            return controller.shouldShowEstimatedHours
                ? const Text(
                    "Estimated Usage",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  )
                : const SizedBox.shrink();
          }
        }),
        Obx(() => controller.shouldShowEstimatedHours || (controller.tripType.value == "Round Trip" && !controller.outstationRoundUseEstimatedHours.value)
            ? const SizedBox(height: 8)
            : const SizedBox.shrink()),
        Obx(() {
          final bool useDays = controller.tripType.value == "Round Trip" && !controller.outstationRoundUseEstimatedHours.value;
          if (useDays) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF7EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Number of Days",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (controller.numberOfDays.value > 1) {
                                controller.numberOfDays.value--;
                              }
                            },
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                          ),
                          Text(
                            "${controller.numberOfDays.value} Day${controller.numberOfDays.value > 1 ? 's' : ''}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (controller.numberOfDays.value < 30) {
                                controller.numberOfDays.value++;
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Travel Plan Details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF7EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: controller.travelPlanController,
                    focusNode: controller.travelPlanFocusNode,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your travel plan (e.g. Chennai -> Pondy -> Chennai)",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            );
          }

          if (!controller.shouldShowEstimatedHours) {
            return const SizedBox.shrink();
          }

          final selectedType = controller.tripTypesList
              .firstWhereOrNull((t) => t['name'].toString().trim().toLowerCase() == controller.tripType.value.trim().toLowerCase());
          
          if (selectedType == null) {
            return const SizedBox(height: 10);
          }

          final List originalOptions = selectedType['hourOptions'] as List;
          
          // Filter options based directly on the physical distance limit
          int minHours = controller.requiredHours.value.toInt();
          List options = originalOptions.where((h) => h is num && h >= minHours).toList();

          if (controller.requiredHours.value > controller.maxAllowedHours) {
             return const Padding(
               padding: EdgeInsets.symmetric(vertical: 10),
               child: Text("Out of range of available time options.", 
                 style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
             );
          }

          if (options.isEmpty) {
            return const SizedBox(height: 10);
          }

          final packages = options.map((h) {
            if (h == 24 && controller.tripType.value == "Round Trip") return "1 Day";
            return "$h Hr${h > 1 ? 's' : ''}";
          }).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: packages.map((pkg) {
                bool isSelected = controller.selectedPackage.value == pkg;
                return GestureDetector(
                  onTap: () => controller.selectedPackage.value = pkg,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          pkg.split(" ")[0],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.orange : Colors.black,
                          ),
                        ),
                        Text(
                          pkg.split(" ")[1],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.orange : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }


  Widget _buildAirportPricingList() {
    return Obx(() {
      if (!controller.isBothLocationsSelected || controller.carCategories.isEmpty) {
        return const SizedBox.shrink();
      }

      final bool isBusy = controller.isCalculatingPrices.value || 
                         (Get.isRegistered<MapController>() && 
                          Get.find<MapController>().isLoadingCoordinates.value);
      
      // If we are fetching route but already have a basic distance estimate, don't show as 'busy' 
      // so the user sees the 'instant' Haversine price update.

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available Rides",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...controller.carCategories.map((carType) {
            final isSelected = controller.selectedCar.value == carType;
            
            // To simulate slightly different prices per car type based on distance
            // We use distanceCost as base, and add a small multiplier by fetching first model name
            final category = controller.carCategoriesRaw.firstWhereOrNull(
              (c) => c['name'].toString().trim().toLowerCase() == carType.trim().toLowerCase(),
            );
            String firstModel = "";
            if (category != null && category['cars'] != null && (category['cars'] as List).isNotEmpty) {
              firstModel = (category['cars'] as List).first['modelName'].toString();
            }

            double multiplier = 1.0;
            if (firstModel.toLowerCase().contains("sedan")) multiplier = 1.2;
            else if (firstModel.toLowerCase().contains("suv")) multiplier = 1.5;
            else if (firstModel.toLowerCase().contains("premium")) multiplier = 2.0;

            final baseDistCost = controller.distanceCost.value * multiplier;
            final gst = (baseDistCost + controller.platformCharge.value) * (controller.gstPercentage.value / 100.0);
            final total = (baseDistCost + controller.platformCharge.value + gst).roundToDouble();

            return GestureDetector(
              onTap: () {
                controller.selectedCar.value = carType;
                controller.updateModelsForSelectedCategory();
                // We update the controller's distance cost multiplier for this specific car type if needed, 
                // but since calculating logic is in controller, we just let it recalculate.
                // Wait, controller doesn't have multipliers. We'll just show the base price.
                // For simplicity, we just show controller.totalPrice.value if it's selected, 
                // otherwise an estimate.
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        carType.toLowerCase().contains("suv") ? Icons.airport_shuttle : Icons.directions_car,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${controller.estimatedTime.value.toInt()} mins",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isBusy) ...[
                          GestureDetector(
                            onTap: () {
                              _showFareDetailsDialog(
                                context,
                                categoryName: carType,
                                baseCost: baseDistCost,
                                platformCharge: controller.platformCharge.value,
                                gstPercentage: controller.gstPercentage.value,
                                gstAmount: gst,
                                carWashCharge: controller.requireCarWash.value
                                    ? controller.carWashCharge.value
                                    : 0.0,
                                totalAmount: total,
                                tripTypeName: "One Way",
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isBusy ? "..." : "₹${total.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      );
    });
  }

  Widget _buildNotServiceableCard() {
    final double maxRange = controller.isOutstationFlow.value 
        ? controller.outstationMaxRange.value 
        : controller.rideRequestRadius.value;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Not Serviceable Distance",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "The selected destination is beyond our maximum serviceable range of ${maxRange.toStringAsFixed(0)} km from your pickup location.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7F1D1D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    return Obx(() {
      if (!controller.isBothLocationsSelected) {
        return const SizedBox.shrink();
      }
      
      if (controller.selectedCarModel.value.isEmpty || 
          controller.selectedCarModel.value == "Any Model") {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.orange.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Selected Vehicle", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("${controller.selectedCar.value} - ${controller.selectedCarModel.value}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black), softWrap: true,),
                    ],
                  ),
                ),
                if (controller.selectedCarNumber.value.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
                    child: Text(controller.selectedCarNumber.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            const SizedBox(height: 16),
            
            // Billing Breakdown
            const Text(
              "Billing Details",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Distance Cost (One Way only)
            if (controller.calculatedDistance.value > 0 && controller.tripType.value != "Round Trip") ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      () {
                        int mins = controller.estimatedTime.value.toInt();
                        String timeStr = mins > 60
                            ? "${mins ~/ 60}:${(mins % 60).toString().padLeft(2, '0')} hr:min"
                            : "$mins mins";
                        return "Base Fare (Est. $timeStr)";
                      }(),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "₹${controller.distanceCost.value.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Hourly Package Cost
            if (controller.selectedPackage.value.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.tripType.value == "Round Trip"
                          ? "Round Trip Package (${controller.selectedPackage.value} @ ₹${(controller.selectedHourPrice.value * 24).toStringAsFixed(0)}/day)"
                          : "Time Package (${controller.selectedPackage.value} @ ₹${controller.selectedHourPrice.value.toStringAsFixed(0)}/hr)",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "₹${controller.hourlyCost.value.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Return Charges
            if (controller.returnCharge.value > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Return Charges (${controller.calculatedDistance.value.toStringAsFixed(1)} km @ ₹${(controller.isOutstationFlow.value ? (controller.tripType.value == "One Way" ? controller.outstationReturnChargeRate.value : controller.outstationRoundReturnChargeRate.value) : controller.localReturnChargeRate.value).toStringAsFixed(0)}/km)",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "₹${controller.returnCharge.value.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Car Wash
            if (controller.requireCarWash.value) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Car Wash Charges",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "₹${controller.carWashCharge.value.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ],

            // Platform Charge
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Platform Charge",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "₹${controller.platformCharge.value.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),

            // GST
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "GST (${controller.gstPercentage.value.toStringAsFixed(0)}%)",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "₹${controller.gstAmount.value.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Total Amount",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      softWrap: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  (() {
                    final bool isBusy = controller.isCalculatingPrices.value || 
                                       (Get.isRegistered<MapController>() && 
                                        Get.find<MapController>().isLoadingCoordinates.value);
                    
                    // Show price instantly if we have any distance estimate, even if still fetching route
                    final bool canShowPrice = controller.calculatedDistance.value > 0 || !isBusy;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canShowPrice) ...[
                          GestureDetector(
                            onTap: () {
                              _showFareDetailsDialog(
                                context,
                                categoryName: "${controller.selectedCar.value} - ${controller.selectedCarModel.value}",
                                baseCost: controller.tripType.value == "Round Trip"
                                    ? 0.0
                                    : controller.distanceCost.value,
                                hourlyCost: controller.hourlyCost.value,
                                platformCharge: controller.platformCharge.value,
                                gstPercentage: controller.gstPercentage.value,
                                gstAmount: controller.gstAmount.value,
                                carWashCharge: controller.requireCarWash.value
                                    ? controller.carWashCharge.value
                                    : 0.0,
                                totalAmount: controller.totalPrice.value,
                                tripTypeName: controller.tripType.value,
                                returnCharge: controller.returnCharge.value,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          !canShowPrice ? "Calculating..." : "₹${controller.totalPrice.value.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: !canShowPrice ? 14 : 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    );
                  })(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }


  Widget _buildBottomBar() {
    return Obx(() {
      final isBooked = controller.isRideBooked.value;
      final leftLabel = isBooked ? "Book Now" : "Schedule";
      final rightLabel = isBooked ? " Home" : "Book Now";

      final isOutOfRange = controller.isBothLocationsSelected &&
          controller.calculatedDistance.value > controller.rideRequestRadius.value;

      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: isOutOfRange
                    ? null
                    : () {
                        if (isBooked) {
                          controller.isRideBooked.value = false;
                        } else {
                          controller.openScheduleDialog();
                        }
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: isOutOfRange ? Colors.grey.shade300 : Colors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  leftLabel,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: isOutOfRange
                    ? null
                    : () {
                        final bool isBusy = controller.isCalculatingPrices.value || 
                                           (Get.isRegistered<MapController>() && 
                                            Get.find<MapController>().isLoadingCoordinates.value);
                        
                        // Allow booking if we have a price, even if still refining route
                        final bool canBook = controller.totalPrice.value > 0 && !isBusy;

                        if (!canBook && isBusy) return;

                        if (isBooked) {
                          Get.offAllNamed('/home');
                        } else {
                          controller.bookNow();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfRange
                      ? Colors.grey.shade200
                      : ((controller.isCalculatingPrices.value || 
                                         (Get.isRegistered<MapController>() && 
                                          Get.find<MapController>().isLoadingCoordinates.value)) 
                                       ? Colors.grey : Colors.orange),
                  foregroundColor: isOutOfRange ? Colors.grey.shade500 : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  isOutOfRange
                      ? "Unavailable"
                      : ((controller.isCalculatingPrices.value || 
                                         (Get.isRegistered<MapController>() && 
                                          Get.find<MapController>().isLoadingCoordinates.value)) 
                                       ? "Calculating..." : rightLabel),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCarWashSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Require Car Wash?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Obx(() => Text(
                  "+₹${controller.carWashPriceSetting.value.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: controller.requireCarWash.value
                        ? AppColors.primary
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() => Row(
              children: [
                Expanded(
                  child: _buildChoiceButton(
                    "No",
                    isSelected: !controller.requireCarWash.value,
                    onTap: () => controller.requireCarWash.value = false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildChoiceButton(
                    "Yes",
                    isSelected: controller.requireCarWash.value,
                    onTap: () => controller.requireCarWash.value = true,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildChoiceButton(String title,
      {required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showFareDetailsDialog(
    BuildContext context, {
    required String categoryName,
    required double baseCost,
    required double platformCharge,
    required double gstPercentage,
    required double gstAmount,
    required double carWashCharge,
    required double totalAmount,
    required String tripTypeName,
    double hourlyCost = 0.0,
    double returnCharge = 0.0,
  }) {
    final isOutstation = tripTypeName == "Outstation" || tripTypeName == "Round Trip" || controller.isOutstationFlow.value;
    final isOneWay = tripTypeName == "One Way";
    
    String subtitleText = "Here's a fare estimate for your trip";
    if (controller.selectedPackage.value.isNotEmpty) {
      if (controller.isOutstationFlow.value) {
        subtitleText = "Here's a fare estimate for your ${controller.selectedPackage.value} $tripTypeName Outstation Trip";
      } else {
        subtitleText = "Here's a fare estimate for your ${controller.selectedPackage.value} Local Trip";
      }
    } else if (isOneWay && controller.calculatedDistance.value > 0) {
      if (controller.isOutstationFlow.value) {
        subtitleText = "Here's a fare estimate for your One Way Outstation Trip";
      } else {
        subtitleText = "Here's a fare estimate for your Local Trip";
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Center(
          child: SingleChildScrollView(
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipPath(
                    clipper: ScallopTicketClipper(scallopRadius: 6, spacing: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              "Professional, background-verified,\ntrained and tested drivers",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFF1F1F1), height: 1),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Estimated Fare Details",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (baseCost > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Base Fare (Distance)",
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ),
                                Text(
                                  "₹${baseCost.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (hourlyCost > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Time Package (${controller.selectedPackage.value})",
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ),
                                Text(
                                  "₹${hourlyCost.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (returnCharge > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Return Charges",
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ),
                                Text(
                                  "₹${returnCharge.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (carWashCharge > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Car Wash Charges",
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ),
                                Text(
                                  "₹${carWashCharge.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Platform Fee",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ),
                              Text(
                                "₹${platformCharge.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "GST (${gstPercentage.toStringAsFixed(0)}%)",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ),
                              Text(
                                "₹${gstAmount.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Subtotal",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ),
                              Text(
                                "₹${(baseCost + carWashCharge + platformCharge + gstAmount + returnCharge).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Rounding",
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                              ),
                              Text(
                                "₹${(totalAmount - (baseCost + carWashCharge + platformCharge + gstAmount + returnCharge)).toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFF1F1F1), height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Estimated Total Fare",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "₹${totalAmount.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.orange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if ((isOutstation || controller.selectedPackage.value.isNotEmpty) && controller.selectedHourPrice.value > 0)
                                  Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "If the trip extends, extra charges as ₹${controller.selectedHourPrice.value.toStringAsFixed(0)} per extra hour applicable.",
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                    ),
                                  ),
                                Container(
                                  width: 140,
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Fares will be adjusted based on additional time and distance usage.",
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                  ),
                                ),
                                if (isOutstation)
                                  Container(
                                    width: 140,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "Please provide food & accommodation for the driver for multi-day outstation bookings.",
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                    ),
                                  ),
                                if (isOneWay)
                                  Container(
                                    width: 140,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "Tolls, parking, and state permit taxes extra if applicable.",
                                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: InkWell(
                              onTap: () {
                                Get.dialog(
                                  AlertDialog(
                                    title: const Text("Cancellation Policy"),
                                    content: const Text(
                                      "If you cancel after a driver is assigned and has arrived at your location, a cancellation fee will be charged to compensate the driver's time and effort.",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: const Text("Got It", style: TextStyle(color: Colors.orange)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "View Cancellation Policy",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.info_outline, size: 13, color: Colors.orange.shade800),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Got It",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

class ScallopTicketClipper extends CustomClipper<Path> {
  final double scallopRadius;
  final double spacing;
  ScallopTicketClipper({this.scallopRadius = 6.0, this.spacing = 6.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    double x = 0;
    double diameter = scallopRadius * 2;
    while (x < size.width) {
      x += spacing;
      if (x + diameter > size.width) {
        path.lineTo(size.width, 0);
        break;
      }
      path.lineTo(x, 0);
      path.arcToPoint(
        Offset(x + diameter, 0),
        radius: Radius.circular(scallopRadius),
        clockwise: false,
      );
      x += diameter;
    }
    path.lineTo(size.width, size.height);
    x = size.width;
    while (x > 0) {
      x -= spacing;
      if (x - diameter < 0) {
        path.lineTo(0, size.height);
        break;
      }
      path.lineTo(x, size.height);
      path.arcToPoint(
        Offset(x - diameter, size.height),
        radius: Radius.circular(scallopRadius),
        clockwise: false,
      );
      x -= diameter;
    }
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
