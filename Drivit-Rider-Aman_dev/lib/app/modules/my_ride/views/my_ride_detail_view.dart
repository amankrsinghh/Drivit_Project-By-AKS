
import 'package:flutter/material.dart';
import '../models/ride_items.dart';
import '../../../routes/app_routes.dart';
import 'package:get/get.dart';
import '../controllers/my_ride_controller.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notification_service.dart';

class MyRideDetailView extends StatelessWidget {
  final RideItem item;
  const MyRideDetailView({super.key, required this.item});

  static const _bg = Color(0xFFF5F5F5);
  static const _cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10)),
  ];
  static const _divider = Color(0xFFEDEDED);

  bool get isCompleted => item.status == RideStatus.completed;


  Color get statusColor {
    if (item.status == RideStatus.completed) return Colors.green;
    if (item.status == RideStatus.upcoming) return Colors.orange;
    if (item.status == RideStatus.unassigned) return Colors.red;
    if (item.status == RideStatus.expired) return Colors.grey;
    return Colors.red;
  }

  String get statusText {
    if (item.status == RideStatus.completed) return "Completed";
    if (item.status == RideStatus.upcoming) return "Upcoming";
    if (item.status == RideStatus.unassigned) return "Unassigned";
    if (item.status == RideStatus.expired) return "Expired";
    return "Canceled";
  }

  String _finalFareHint() {
    if (isCompleted) {
      // Only show hourly package hint for Round Trip
      if (item.tripType == 'Round Trip') {
        return "Base on ${item.hourlyPackageHours} hour package";
      }
      return "Distance/time based fare";
    }
    // cancelled
    switch (item.cancellationType) {
      case CancellationType.afterDriverArrival:
        return "Include Cancelation charger\n(Cancel after driver arrival)";
      case CancellationType.beforeDriverArrival:
        return "Include Cancelation charger\n(Cancel before driver arrival)";
      case CancellationType.freeCancelBeforeXMinute:
        return "No Cancelation charge\n(Cancel before X minute)";
      case CancellationType.none:
        return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Trip Details",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 25),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (item.rawId != null) {
                Get.toNamed(
                  Routes.chat,
                  arguments: {
                    'rideId': item.rawId,
                    'name': item.driverName,
                    'otherId': item.rawDriverId ?? 'driver_fallback',
                    'image': item.driverProfileImage,
                  },
                );
              } else {
                NotificationService.to.showLocalNotification(
                  title: "Error",
                  body: "Chat not available for this ride",
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.orange),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.orange),
            onSelected: (value) {
              if (value == 'dispute') {
                _showDisputeDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'dispute',
                child: Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text("Report Dispute"),
                  ],
                ),
              ),
            ],
          ),
        ],

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topHeader(context),

            if (item.tripStartAddress != "-") ...[
              const SizedBox(height: 14),
              _tripRow(
                title: "Trip Start",
                subtitle: "${item.tripStartTime}  •  ${item.tripStartAddress}",
                icon: Icons.trip_origin,
                iconColor: Colors.green,
              ),
            ],

            if (item.tripEndAddress != "-") ...[
              const SizedBox(height: 10),
              _tripRow(
                title: item.status == RideStatus.cancelled
                    ? "Trip End (Canceled)"
                    : "Trip End",
                subtitle: item.tripEndTime != "-" && item.tripEndTime.isNotEmpty
                    ? "${item.tripEndTime}  •  ${item.tripEndAddress}"
                    : item.tripEndAddress,
                icon: Icons.location_on,
                iconColor: Colors.red,
              ),
            ],

            if (item.status == RideStatus.upcoming) ...[
              _driverDetailsCard(),
              const SizedBox(height: 14),
            ],
            
            if (item.status == RideStatus.unassigned) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "The driver has unassigned this trip. Admin is currently reassigning a new driver.",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _bookingDetailsCard(),
            const SizedBox(height: 14),
            _fareCard(),
            if (item.status == RideStatus.upcoming || item.status == RideStatus.unassigned) ...[
              const SizedBox(height: 24),
              _actionButtons(context),
            ]
          ],
        ),
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _cancelRide(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Cancel Ride", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _modifyRide(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Modify Schedule", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _cancelRide(BuildContext context) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Cancel Ride"),
        content: const Text("Are you sure you want to cancel this scheduled ride?"),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text("No")),
          TextButton(onPressed: () => Get.back(result: true), child: const Text("Yes, Cancel")),
        ],
      ),
    );

    if (confirm == true) {
      Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.orange)), barrierDismissible: false);
      final res = await ApiService.cancelRide(item.rawId!);
      Get.back(); // close loader

      if (res.containsKey('error')) {
        Get.snackbar("Error", res['error'], backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.back(); // close detail view
        Get.find<MyRideController>().fetchMyRides();
        Get.snackbar("Success", "Ride cancelled successfully", backgroundColor: Colors.green, colorText: Colors.white);
      }
    }
  }

  void _modifyRide(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final newScheduledAt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (newScheduledAt.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
          Get.snackbar("Error", "Scheduled time must be at least 30 minutes in the future",
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }

        Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.orange)), barrierDismissible: false);
        final res = await ApiService.updateRideDetails(item.rawId!, {
          'scheduledAt': newScheduledAt.toIso8601String(),
        });
        Get.back(); // close loader

        if (res.containsKey('error')) {
          Get.snackbar("Error", res['error'], backgroundColor: Colors.red, colorText: Colors.white);
        } else {
          Get.back(); // close detail view
          Get.find<MyRideController>().fetchMyRides();
          Get.snackbar("Success", "Schedule updated successfully", backgroundColor: Colors.green, colorText: Colors.white);
        }
      }
    }
  }


  Widget _bookingDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Booking Details", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _kv("Car Type", item.carType),
          _kv("Car Model", item.carModel),
          _kv("Trip Type", item.tripType),
          // Only show package for non-One-Way trips
          if (item.tripType != 'One Way') _kv("Usage Package", item.carPackage),
          _kv("Car Wash Required", item.requireCarWash ? "Yes" : "No"),
          if (item.scheduledTimeText != "-") _kv("Scheduled Time", item.scheduledTimeText),
          _kv("Booking Time", item.bookingTimeText),
        ],
      ),
    );
  }

  Widget _driverDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Driver & Vehicle", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _kv("Driver Phone", item.driverPhone),
          _kv("Vehicle", item.vehicleInfo),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ride OTP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(item.otp, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text("Share this OTP with driver to start the ride.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // square icon like image
        InkWell(
          onTap: () {
            if (item.driverProfileImage != null && item.driverProfileImage!.isNotEmpty) {
              final url = ApiService.getImageUrl(item.driverProfileImage);
              _showImagePreview(context, url);
            }
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFECECEC),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: item.driverProfileImage != null && item.driverProfileImage!.isNotEmpty
                ? Image.network(
                    ApiService.getImageUrl(item.driverProfileImage),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Image.asset("assets/images/user.png", fit: BoxFit.cover),
                  )
                : Image.asset("assets/images/user.png", fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.rideTitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                "${item.dateText}  •  ${item.timeText}",
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Text(
          statusText,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ],
    );
  }

  void _showImagePreview(BuildContext context, String url) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Container(
            width: Get.width * 0.8,
            height: Get.width * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (ctx, err, stack) => const Icon(Icons.person, size: 100, color: Colors.black26),
              ),
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.85),
    );
  }

  Widget _tripRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fareCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Final Fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text("Final Fare", 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text("₹ ${item.amount.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            _finalFareHint(),
            style: const TextStyle(color: Colors.black45, fontSize: 11, height: 1.25),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: _divider),

          // Payment mode
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text("Payment mode", style: TextStyle(color: Colors.black54), softWrap: true,),
              ),
              const SizedBox(width: 8),
              _paymentWidget(item.paymentMode),
            ],
          ),

          if (isCompleted) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: _divider),
            const SizedBox(height: 12),

            const Text("Fare breakdown", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            // Round Trip → hourly package billing (no estimated time, no distance cost)
            // One Way → distance/time fare only (no hourly fields)
            if (item.tripType == 'Round Trip') ...[
              _kv("Hourly package", "${item.hourlyPackageHours} hours"),
              _kv("Extra time used", "${item.extraTimeUsedMin} min"),
              _kv("Hourly rate", "₹ ${item.hourlyRate.toStringAsFixed(0)}/hour"),
              _kv("Hourly Package Cost", "₹ ${(item.hourlyPackageHours * item.hourlyRate).toStringAsFixed(0)}"),
            ],
            if (item.requireCarWash)
              _kv("Car wash service", "₹ ${item.carWashPrice.toStringAsFixed(0)}"),
            _kv("Platform charge", "₹ ${item.platformCharge.toStringAsFixed(0)}"),
            _kv("GST", "₹ ${item.gst.toStringAsFixed(0)}"),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 12),

          const Text("Trip Summary", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _kv("Booking ID", item.bookingId),
          // Round Trip: hide trip duration; One Way: show duration & distance
          if (item.tripType != 'Round Trip') ...[
            _kv("Trip duration", item.tripDurationText),
          ],
        ],
      ),
    );
  }

  Widget _paymentWidget(String mode) {
    if (mode.trim().isEmpty || mode == "-") {
      return const Text("-", style: TextStyle(color: Colors.black45));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        mode,
        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(BuildContext context) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.white)), barrierDismissible: false);
    final types = await ApiService.getDisputeTypes();
    Get.back(); // close loader

    if (types.isEmpty) {
      Get.snackbar("Info", "Dispute types not configured by admin", 
        backgroundColor: Colors.white, colorText: Colors.black);
      return;
    }

    String? selectedType;
    final descController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Report a Dispute",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 4),
              const Text("Select the issue you faced during this ride.",
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 24),
              const Text("Category",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              StatefulBuilder(builder: (context, setState) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Select dispute type"),
                      value: selectedType,
                      items: types.map((t) => DropdownMenuItem<String>(
                        value: t['name'].toString(),
                        child: Text(t['name'].toString()),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedType = val),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Text("Description",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Explain what happened...",
                  fillColor: const Color(0xFFF9FAFB),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedType == null) {
                      Get.snackbar("Error", "Please select a dispute type",
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }
                    if (descController.text.trim().isEmpty) {
                      Get.snackbar("Error", "Please provide a description",
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }

                    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.orange)), barrierDismissible: false);
                    final res = await ApiService.submitDispute(
                      rideId: item.rawId ?? "",
                      raisedBy: "Customer",
                      issueType: selectedType!,
                      description: descController.text.trim(),
                    );
                    Get.back(); // close loader

                    if (res.containsKey('error')) {
                      Get.snackbar("Error", res['error'],
                          backgroundColor: Colors.red, colorText: Colors.white);
                    } else {
                      Get.back(); // close bottomsheet
                      Get.snackbar("Success", "Dispute submitted successfully. Admin will review it.",
                          backgroundColor: Colors.green, colorText: Colors.white);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Submit Dispute",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}