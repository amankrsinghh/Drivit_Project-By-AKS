import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/driver_colors.dart';
import '../../routes/driver_routes.dart';
import '../controllers/driver_trip_controller.dart';

class DriverTripEarningView extends StatelessWidget {
  const DriverTripEarningView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DriverTripController>()) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final controller = Get.find<DriverTripController>();
    final top = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            // Header
            Container(
              color: DriverColors.primary,
              padding: EdgeInsets.only(top: top),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => controller.goHomeTab(),
                      borderRadius: BorderRadius.circular(99),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Obx(() => Text(
                          controller.status.value == 'Cancelled' ? "Trip Cancelled" : "Total Fare",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Earnings Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Obx(() => Text(
                            controller.status.value == 'Cancelled' ? "Cancellation Charge" : "Total Fare Amount",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                          const SizedBox(height: 8),
                          Obx(() => Text(
                                "₹ ${controller.finalFare.value.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 42,
                                ),
                              )),
                          const SizedBox(height: 12),
                          
                          // Payment Recognition Badge
                          Obx(() {
                            final isCollected = controller.isPaymentCollected.value;
                            final isCash = controller.paymentMode.value == 'Cash';
                            
                            String badgeText = "Payment to be Collected";
                            Color badgeColor = const Color(0xFFFFF3E6);
                            Color badgeTextColor = DriverColors.primary;
                            IconData badgeIcon = Icons.payments_outlined;
                            
                            if (isCollected) {
                              badgeText = "Payment Received";
                              badgeColor = const Color(0xFFE8F5E9);
                              badgeTextColor = Colors.green;
                              badgeIcon = Icons.check_circle;
                            } else if (isCash) {
                              badgeText = "Cash Payment Selected";
                              badgeColor = const Color(0xFFFFF3E0);
                              badgeTextColor = Colors.orange;
                              badgeIcon = Icons.payments;
                            }
                            
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey("$isCollected-$isCash"),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: badgeTextColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(badgeIcon, color: badgeTextColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      badgeText,
                                      style: TextStyle(
                                        color: badgeTextColor,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Fare Breakdown
                    const Text(
                      "Fare Breakdown",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard([
                      // Round Trip → hourly billing only; One Way → distance billing only
                      Obx(() {
                        return Column(children: [
                          if (controller.distanceCost.value > 0)
                            _row("Base Fare", "₹ ${controller.distanceCost.value.toStringAsFixed(0)}"),
                          if (controller.returnCharge.value > 0)
                            _row("Return Charges", "₹ ${controller.returnCharge.value.toStringAsFixed(0)}"),
                          if (controller.hourlyCost.value > 0 || (controller.hourlyPackage.value.isNotEmpty && controller.hourlyPackage.value != "-")) ...[
                            if (controller.tripType.value == "Round Trip") ...[
                              _row("Round Trip Duration", () {
                                final packageVal = controller.hourlyPackage.value;
                                final hrs = int.tryParse(packageVal.split(" ")[0]) ?? 24;
                                final days = hrs ~/ 24;
                                return "$days Day${days > 1 ? 's' : ''}";
                              }()),
                              _row("Daily Rate", () {
                                final rawRate = double.tryParse(controller.hourlyRate.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 150.0;
                                return "₹ ${(rawRate * 24).toStringAsFixed(0)}/day";
                              }()),
                              _row("Round Trip Cost", "₹ ${controller.hourlyCost.value.toStringAsFixed(0)}"),
                            ] else ...[
                              _row("Hourly Package", controller.hourlyPackage.value),
                              _row("Hourly Rate", controller.hourlyRate.value),
                              if (controller.hourlyCost.value > 0)
                                _row("Package Cost", "₹ ${controller.hourlyCost.value.toStringAsFixed(0)}"),
                              if (controller.extraTimeUsed.value.isNotEmpty && controller.extraTimeUsed.value != "-" && controller.extraTimeUsed.value != "0 min")
                                _row("Extra Time Used", controller.extraTimeUsed.value),
                            ],
                          ],
                        ]);
                      }),
                      Obx(() => controller.requireCarWash.value
                        ? _row("Car Wash Service", "₹ ${controller.carWashPrice.value.toStringAsFixed(0)}")
                        : const SizedBox.shrink()),
                      const Divider(height: 16),
                      Obx(() => _row("Total Paid by Rider", "₹ ${controller.finalFare.value.toStringAsFixed(0)}", isHighlight: true)),
                      Obx(() => _row("Platform Charge", "-₹ ${controller.platformCharge.value.toStringAsFixed(0)}")),
                      Obx(() => _row("GST", "-₹ ${controller.gst.value.toStringAsFixed(0)}")),
                      const Divider(height: 24),
                      Obx(() => _row("Net Earnings", "₹ ${(controller.finalFare.value - controller.platformCharge.value - controller.gst.value).toStringAsFixed(0)}", isHighlight: true)),
                    ]),

                    const SizedBox(height: 24),

                    // Trip Summary
                    const Text(
                      "Trip Summary",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard([
                      Obx(() => _row("Booking ID", controller.bookingId.value)),
                      // Round Trip: hide trip duration & distance; One Way: show both
                      Obx(() => controller.tripType.value != 'Round Trip'
                        ? Column(children: [
                            _row("Trip Duration", controller.tripDuration.value),
                          ])
                        : const SizedBox.shrink()),
                      Obx(() => controller.isScheduled.value 
                        ? _row("Scheduled For", controller.scheduledAt.value) 
                        : const SizedBox.shrink()),
                      Obx(() => controller.tripStartTime.value.isNotEmpty
                        ? _row("Trip Start Time", controller.tripStartTime.value)
                        : const SizedBox.shrink()),
                      Obx(() => controller.tripEndTime.value.isNotEmpty
                        ? _row("Trip End Time", controller.tripEndTime.value)
                        : const SizedBox.shrink()),
                    ]),

                    const SizedBox(height: 24),

                    // Support
                    InkWell(
                      onTap: () {
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
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E6),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: DriverColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.help_outline, color: DriverColors.primary, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "Need help with this trip?",
                              style: TextStyle(
                                color: DriverColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Navigation Buttons (Always Visible)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Obx(() {
                  final isCash = controller.paymentMode.value == 'Cash';
                  final isCollected = controller.isPaymentCollected.value;
                  
                  if (isCash && !isCollected) {
                    return Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => _showDisputeModal(context, controller),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text(
                                "Raise Dispute",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.dialog(
                                  AlertDialog(
                                    title: const Text("Confirm Payment"),
                                    content: Text("Did you collect cash ₹${controller.finalFare.value.toStringAsFixed(0)} from the rider?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Get.back(),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Get.back();
                                          controller.confirmCashCollected();
                                        },
                                        child: const Text("Yes, Collected"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text(
                                "Cash Collected",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // Default Online / Completed view (Home / Next Ride)
                  return Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: controller.goHomeTab,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: DriverColors.primary, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text(
                              "Home",
                              style: TextStyle(
                                color: DriverColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: controller.continueFinding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DriverColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text(
                              "Next Ride",
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDisputeModal(BuildContext context, DriverTripController controller) {
    String selectedIssue = "Rider refused to pay";
    final descC = TextEditingController();
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Raise Payment Dispute",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Select Issue Type:",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedIssue,
                items: [
                  "Rider refused to pay",
                  "Paid incorrect amount",
                  "Rider left without paying",
                  "Other issue",
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) selectedIssue = val;
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Dispute Description:",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descC,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter explanation here...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    controller.raiseDispute(
                      issueType: selectedIssue,
                      description: descC.text.trim().isNotEmpty
                          ? descC.text.trim()
                          : "Driver raised dispute: $selectedIssue",
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Submit Dispute",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _row(String k, String v, {bool isHighlight = false}) {
    if (v.isEmpty || v == "const SizedBox.shrink()") return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              k,
              softWrap: true,
              style: TextStyle(
                color: isHighlight ? Colors.black : Colors.black54,
                fontSize: isHighlight ? 15 : 13,
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              v,
              softWrap: true,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isHighlight ? DriverColors.primary : Colors.black87,
                fontSize: isHighlight ? 18 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}