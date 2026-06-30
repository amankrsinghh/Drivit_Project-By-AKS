import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/finding_driver_controller.dart';
import '../../../routes/app_routes.dart';

class DriverBottomSheet extends StatefulWidget {
  const DriverBottomSheet({super.key});

  @override
  State<DriverBottomSheet> createState() => _DriverBottomSheetState();
}

class _DriverBottomSheetState extends State<DriverBottomSheet> {
  final FindingDriverController controller =
      Get.find<FindingDriverController>();
  final DraggableScrollableController sheetController =
      DraggableScrollableController();

  final extentRx = 0.30.obs;
  Worker? _worker;

  @override
  void initState() {
    super.initState();

    _worker = ever(controller.stage, (stage) async {
      if (!mounted) return;
      if (controller.isClosing.value) return;
      if (!sheetController.isAttached) return;

      try {
        await sheetController.animateTo(
          _target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    });
  }

  double get _target => switch (controller.stage.value) {
    BookingStage.finding => 0.30,
    BookingStage.accepted => 0.60,
    BookingStage.arrived => 0.60,
    BookingStage.tripStarted => 0.60,
    BookingStage.tripCompleted => 0.65,
  };

  @override
  void dispose() {
    _worker?.dispose();
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stage = controller.stage.value;

      // ── FINDING stage: transparent floating overlay, no bottom sheet ──
      if (stage == BookingStage.finding) {
        return _FindingUI(controller: controller);
      }

      // ── All other stages: draggable bottom sheet ──
      const double minSize = 0.15;
      const double maxSize = 0.85;

      return DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: _target,
          minChildSize: minSize,
          maxChildSize: maxSize,
          snap: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      width: 65,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Obx(() {
                    if (controller.stage.value == BookingStage.finding)
                      return const SizedBox.shrink();
                    Widget textWidget = const SizedBox.shrink();
                    if (controller.stage.value == BookingStage.accepted ||
                        controller.stage.value == BookingStage.arrived) {
                      textWidget = Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          controller.stage.value == BookingStage.arrived
                              ? "Driver has arrived at your location"
                              : (controller.etaToPickup.value.isNotEmpty
                                    ? (controller.etaToPickup.value == "0 min"
                                        ? "Driver is nearby..."
                                        : "Driver will arrive in ${controller.etaToPickup.value}")
                                    : "Driver is coming..."),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (controller.stage.value ==
                        BookingStage.tripStarted) {
                      textWidget = Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          (controller.tripType.value == 'Round Trip')
                              ? "Trip Ongoing (Round Trip)"
                              : (controller.etaToDropoff.value.isNotEmpty
                                  ? (controller.etaToDropoff.value == "0 min"
                                      ? "Arriving at destination..."
                                      : "Arriving at destination in ${controller.etaToDropoff.value}")
                                  : "On the way..."),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (controller.stage.value ==
                        BookingStage.tripCompleted) {
                      textWidget = Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Text(
                              controller.isCancellationPaymentFlow.value
                                  ? "Trip Cancelled"
                                  : "Trip Completed",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.isCancellationPaymentFlow.value
                                  ? "Review and pay the cancellation charge to the driver"
                                  : (controller.hourlyCost.value > 0 || (controller.hourlyPackage.value.isNotEmpty && controller.hourlyPackage.value != "-")
                                      ? (controller.tripType.value == "Round Trip"
                                          ? "Review your round trip fare and make\npayment to the driver"
                                          : "Review your distance + hourly package fare and make\npayment to the driver")
                                      : "Review your distance/time based fare and make\npayment to the driver"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return textWidget;
                  }),

                  Obx(() {
                    switch (controller.stage.value) {
                      case BookingStage.finding:
                        return const SizedBox.shrink(); // handled above
                      case BookingStage.accepted:
                      case BookingStage.arrived:
                        return _AcceptedUI(controller: controller);
                      case BookingStage.tripStarted:
                        return _TripStartedUI(controller: controller);
                      case BookingStage.tripCompleted:
                        return _TripCompletedUI(controller: controller);
                    }
                  }),
                ],
              ),
            );
          },
        );
    });
  }
}

// ---------- FINDING ----------
class _FindingUI extends StatelessWidget {
  final FindingDriverController controller;
  const _FindingUI({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFB74D), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.search, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.showRetryOption.value
                            ? "Time is over, please try again."
                            : "Finding Best Driver nearby...",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "We are checking availability, rating to match you with a professional driver.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // TIMER
                    Obx(() {
                      if (controller.showRetryOption.value) {
                        return const SizedBox.shrink();
                      }
                      final seconds = controller.searchCountdown.value;
                      final min = (seconds ~/ 60).toString().padLeft(1, '0');
                      final sec = (seconds % 60).toString().padLeft(2, '0');
                      return Text(
                        "Search expiring in $min:$sec",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.showRetryOption.value) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.retrySearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Retry Search",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isCancelling.value
                        ? null
                        : controller.openCancelReasonDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: controller.isCancelling.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Cancel Ride",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            );
          }

          return SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: controller.isCancelling.value
                  ? null
                  : controller.openCancelReasonDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: controller.isCancelling.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Cancelling...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      "Cancel Request",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          );
        }),
      ],
    );
  }
}

// ---------- ACCEPTED ----------
class _AcceptedUI extends StatelessWidget {
  final FindingDriverController controller;
  const _AcceptedUI({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CarWashBadge(controller: controller),
        Obx(() {
          if (controller.stage.value == BookingStage.arrived &&
              controller.arrivalTime.value.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Driver Arrived at: ${controller.arrivalTime.value}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        _DriverCard(controller: controller),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    final rideId = controller.rideDatabaseId.value;
                    final driverName = controller.driverName.value;
                    final driverId = controller.driverId.value;
                    Get.toNamed(
                      Routes.chat,
                      arguments: {
                        'rideId': rideId,
                        'name': driverName,
                        'otherId': driverId.isNotEmpty
                            ? driverId
                            : 'driver_fallback',
                        'image': controller.driverImage.value,
                        'rating': controller.driverRating.value,
                        'exp': controller.driverExp.value,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        "Send a message",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Square(icon: Icons.call, onTap: controller.callDriver),
            const SizedBox(width: 12),
            _Square(icon: Icons.share, onTap: controller.shareTrip),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12, width: 1.5),
          ),
          child: Row(
            children: [
              const Text(
                "OTP",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Obx(() {
                if (controller.otp.value.isEmpty) {
                  return const Text(
                    "Generating...",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }
                return Row(
                  children: controller.otp.value
                      .split('')
                      .map(
                        (digit) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            digit,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              }),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Please sure you share your OTP before start a ride.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),

        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isCancelling.value
                  ? null
                  : controller.openCancelReasonDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isCancelling.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Cancelling...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      "Cancel Request",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- TRIP STARTED ----------
class _TripStartedUI extends StatelessWidget {
  final FindingDriverController controller;
  const _TripStartedUI({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CarWashBadge(controller: controller),
        _DriverCard(controller: controller),
        const SizedBox(height: 14),

        // Contact Buttons
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    final rideId = controller.rideDatabaseId.value;
                    final driverName = controller.driverName.value;
                    final driverId = controller.driverId.value;
                    Get.toNamed(
                      Routes.chat,
                      arguments: {
                        'rideId': rideId,
                        'name': driverName,
                        'otherId': driverId.isNotEmpty
                            ? driverId
                            : 'driver_fallback',
                        'image': controller.driverImage.value,
                        'rating': controller.driverRating.value,
                        'exp': controller.driverExp.value,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, color: Colors.orange),
                      SizedBox(width: 10),
                      Text(
                        "Send a message",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _Square(icon: Icons.call, onTap: controller.callDriver),
            const SizedBox(width: 12),
            _Square(icon: Icons.share, onTap: controller.shareTrip),
          ],
        ),
        const SizedBox(height: 14),

        Obx(
          () =>
              _TripTile(title: "Trip Start", subtitle: controller.pickup.value),
        ),
        const SizedBox(height: 10),
        Obx(
          () => _TripTile(
            title: controller.estimatedTime.value.isNotEmpty
                ? "Trip End (${controller.estimatedTime.value})"
                : "Trip End (Estimated Time)",
            subtitle: controller.destination.value,
          ),
        ),
        const SizedBox(height: 16),

        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isCancelling.value
                  ? null
                  : controller.openCancelReasonDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isCancelling.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Cancelling...",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      "End Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- TRIP COMPLETED ----------
class _TripCompletedUI extends StatelessWidget {
  final FindingDriverController controller;
  const _TripCompletedUI({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              "Final Fare",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Obx(
              () => Text(
                "₹ ${controller.finalFare.value.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Obx(
          () => controller.isCancellationPaymentFlow.value
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Cancellation charge (Cancel after driver arrival)",
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              : (controller.tripType.value == "Round Trip"
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Base on ${() {
                          final packageVal = controller.hourlyPackage.value;
                          final hrs = int.tryParse(packageVal.split(" ")[0]) ?? 24;
                          final days = hrs ~/ 24;
                          return "$days Day${days > 1 ? 's' : ''}";
                        }()} trip",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
        const Divider(height: 26),

        Row(
          children: [
            const Text("Payment mode", style: TextStyle(color: Colors.grey)),
            const Spacer(),
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  controller.paymentMode.value,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 20),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Select Payment Method",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final isCash = controller.paymentMode.value == 'Cash';
          return Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => controller.selectOnlinePayment(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isCash ? const Color(0xFFFFF3E0) : const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isCash ? Colors.orange : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.credit_card,
                          color: !isCash ? Colors.orange : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Online Payment",
                          style: TextStyle(
                            color: !isCash ? Colors.orange : Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => controller.selectCashPayment(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isCash ? const Color(0xFFFFF3E0) : const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCash ? Colors.orange : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments,
                          color: isCash ? Colors.orange : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Cash to Driver",
                          style: TextStyle(
                            color: isCash ? Colors.orange : Colors.grey,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 12),
        // If waiting for cash confirmation
        Obx(() {
          if (controller.isWaitingForCashConfirmation.value) {
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.orange,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Waiting for driver to confirm Cash payment...",
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        const Divider(height: 26),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Booking Details",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        _KV("Car Type", () => controller.carType.value),
        _KV("Car Model", () => controller.carModelRequested.value),
        _KV("Trip Type", () => controller.tripType.value),
        Obx(
          () => controller.isScheduled.value
              ? _KV("Scheduled Time", () => controller.scheduledTime.value)
              : const SizedBox.shrink(),
        ),
        _KV("Booking Time", () => controller.bookingTime.value),
        Obx(() => controller.tripStartTime.value.isNotEmpty
            ? _KV("Trip Start Time", () => controller.tripStartTime.value)
            : const SizedBox.shrink()),
        Obx(() => controller.completionTime.value.isNotEmpty
            ? _KV("Trip End Time", () => controller.completionTime.value)
            : const SizedBox.shrink()),

        const Divider(height: 26),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Fare breakdown",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),

        // Round Trip → show hourly package fields; hide estimated time
        // One Way → show distance cost only; hide all hourly fields
        Obx(() {
          if (controller.isCancellationPaymentFlow.value) {
            return Column(
              children: [
                _KV(
                  "Cancellation Fee (${controller.cancellationFeePercent.value.toStringAsFixed(0)}%)",
                  () => "₹ ${controller.finalFare.value.toStringAsFixed(0)}",
                ),
              ],
            );
          } else {
            return Column(
              children: [
                if (controller.distanceCost.value > 0)
                  _KV(
                    "Base Fare",
                    () => "₹ ${controller.distanceCost.value.toStringAsFixed(0)}",
                  ),
                if (controller.returnCharge.value > 0)
                  _KV(
                    "Return Charges",
                    () => "₹ ${controller.returnCharge.value.toStringAsFixed(0)}",
                  ),
                if (controller.hourlyCost.value > 0 || (controller.hourlyPackage.value.isNotEmpty && controller.hourlyPackage.value != "-")) ...[
                  if (controller.tripType.value == "Round Trip") ...[
                    _KV("Round Trip Duration", () {
                      final packageVal = controller.hourlyPackage.value;
                      final hrs = int.tryParse(packageVal.split(" ")[0]) ?? 24;
                      final days = hrs ~/ 24;
                      return "$days Day${days > 1 ? 's' : ''}";
                    }),
                    _KV("Daily Rate", () {
                      final rawRate = double.tryParse(controller.hourlyRate.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 150.0;
                      return "₹ ${(rawRate * 24).toStringAsFixed(0)}/day";
                    }),
                    _KV(
                      "Round Trip Cost",
                      () => "₹ ${controller.hourlyCost.value.toStringAsFixed(0)}",
                    ),
                  ] else ...[
                    _KV("Hourly package", () => controller.hourlyPackage.value),
                    if (controller.extraTimeUsed.value.isNotEmpty && controller.extraTimeUsed.value != "-" && controller.extraTimeUsed.value != "0 min")
                      _KV("Extra time used", () => controller.extraTimeUsed.value),
                    _KV("Hourly rate", () => controller.hourlyRate.value),
                    _KV(
                      "Hourly Package Cost",
                      () => "₹ ${controller.hourlyCost.value.toStringAsFixed(0)}",
                    ),
                  ],
                ],
                if (controller.requireCarWash.value)
                  _KV(
                    "Car Wash",
                    () => "₹ ${controller.carWashPrice.value.toStringAsFixed(0)}",
                  ),
                if (controller.platformCharge.value > 0)
                  _KV(
                    "Platform Charge",
                    () => "₹ ${controller.platformCharge.value.toStringAsFixed(0)}",
                  ),
                if (controller.gst.value > 0)
                  _KV(
                    "GST",
                    () => "₹ ${controller.gst.value.toStringAsFixed(0)}",
                  ),
              ],
            );
          }
        }),

        const Divider(height: 26),

        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Trip Summary",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),

        _KV("Booking ID", () => controller.bookingId.value),
        // Round Trip: hide trip duration; One Way: show trip duration & distance
        Obx(
          () => controller.tripType.value != "Round Trip"
              ? Column(
                  children: [
                    _KV("Trip duration", () => controller.tripDuration.value),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            final rideId = controller.rideDatabaseId.value;
            final driverName = controller.driverName.value;
            final driverId = controller.driverId.value;
            Get.toNamed(
              Routes.chat,
              arguments: {
                'rideId': rideId,
                'name': driverName,
                'otherId': driverId.isNotEmpty ? driverId : 'driver_fallback',
                'image': controller.driverImage.value,
                'rating': controller.driverRating.value,
                'exp': controller.driverExp.value,
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Text(
                  "Support: Chat with Driver",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isPaying.value || controller.isWaitingForCashConfirmation.value
                  ? null
                  : controller.makePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: controller.isPaying.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      controller.isCancellationPaymentFlow.value &&
                              controller.finalFare.value <= 0
                          ? "Confirm Cancellation"
                          : (controller.isWaitingForCashConfirmation.value
                              ? "Waiting for Driver Confirmation..."
                              : (controller.paymentMode.value == "Cash"
                                  ? "Confirm Cash Payment"
                                  : "Make Payment to the Driver")),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String Function() v;
  const _KV(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Obx(() => Text(v(), style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

// shared
class _DriverCard extends StatelessWidget {
  final FindingDriverController controller;
  const _DriverCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Obx(() {
            final url = controller.driverImage.value;
            return Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEFEF),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 28,
                            ),
                      )
                    : const Icon(Icons.person, color: Colors.grey, size: 28),
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
                    Obx(
                      () => Text(
                        controller.driverName.value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.green, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Obx(
                      () => Text(
                        controller.driverExp.value,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Obx(
                            () => Text(
                              controller.driverRating.value,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    "${controller.carType.value} / ${controller.carModelRequested.value}",
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => Text(
                  controller.bookingId.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Booking ID",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Square extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Square({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.orange),
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _TripTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarWashBadge extends StatelessWidget {
  final FindingDriverController controller;
  const _CarWashBadge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.requireCarWash.value) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[100]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.cleaning_services, size: 18, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Car Wash Requested",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "Additional ₹${controller.carWashPrice.value.toStringAsFixed(0)} included in total",
                    style: TextStyle(color: Colors.green[700], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
