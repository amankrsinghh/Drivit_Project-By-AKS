

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../services/api_service.dart';
import '../../theme/driver_colors.dart';
import '../models/driver_trip_history_model.dart';
import '../controllers/driver_history_controller.dart';

class DriverTripDetailsView extends StatefulWidget {
  const DriverTripDetailsView({super.key});

  @override
  State<DriverTripDetailsView> createState() => _DriverTripDetailsViewState();
}

class _DriverTripDetailsViewState extends State<DriverTripDetailsView> {
  DriverTripHistoryModel? _trip;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    try {
      if (Get.arguments is DriverTripHistoryModel) {
        _trip = Get.arguments;
      } else if (Get.arguments is Map) {
        _trip = DriverTripHistoryModel.fromApi(Map<String, dynamic>.from(Get.arguments as Map));
      } else {
        _errorMessage = "No trip details provided";
      }
    } catch (e, stack) {
      debugPrint("Error parsing trip details in DriverTripDetailsView: $e\n$stack");
      _errorMessage = "Failed to parse trip details: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trip == null && Get.arguments is DriverTripHistoryModel) {
      _trip = Get.arguments;
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: DriverColors.primary,
          title: const Text(
            "Trip Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ),
      );
    }

    if (_trip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final trip = _trip!;
    final top = MediaQuery.of(context).padding.top;

    final isCanceled = trip.status == TripStatus.canceled;

    Color statusColor;
    String statusText;
    if (trip.status == TripStatus.completed) {
      statusColor = const Color(0xFF2DBE60);
      statusText = "Completed";
     
    } else if (trip.status == TripStatus.canceled) {
      statusColor = const Color(0xFFFF3B30);
      statusText = "Canceled";
      


    } else if (trip.status == TripStatus.expired) {
      statusColor = Colors.grey;
      statusText = "Expired";
    } else {
      statusColor = const Color(0xFFFF9500);
      statusText = "Upcoming";
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: DriverColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // header
            Container(
              color: DriverColors.primary,
              padding: EdgeInsets.only(top: top),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(99),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.arrow_back, color: Colors.white,size: 30,),
                      
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Trip Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                           
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (trip.rawId != null) {
                          Get.toNamed(
                            '/chat', // DriverRoutes.chat
                            arguments: {
                              'rideId': trip.rawId,
                              'name': trip.passenger,
                              'otherId': trip.rawCustomerId ?? 'customer_fallback',
                              'profileImage': trip.passengerImage,
                            },
                          );
                        } else {
                          // Snackbar removed: Only FCM should be used
                        }
                      },
                      child: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 25),
                      onSelected: (val) {
                        if (val == 'dispute') {
                          _showDisputeDialog(context, trip);
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
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),


            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 19, 18, 19),
                child: Column(
                  children: [
                    // top info row
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECECEC),
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: trip.passengerImage != null && trip.passengerImage!.isNotEmpty
                              ? Image.network(
                                  ApiService.getImageUrl(trip.passengerImage),
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => Image.asset("assets/images/user.png", fit: BoxFit.cover),
                                )
                              : Image.asset("assets/images/user.png", fit: BoxFit.cover),
                        ),

                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.passenger,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                 
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                trip.dateLine,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 18,
                                 
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // trip start/end
                    _timeRow("Trip Start",
              
                        "${trip.tripStartTime}  •  ${trip.tripStartAddress}"),
            
                    const SizedBox(height: 18),
                    _timeRow(
                      isCanceled
                          ? "Trip End (Canceled)"
                          : (trip.status == TripStatus.completed ? "Actual Trip End" : "Estimated End Time"),

                      isCanceled
                          ? "—"
                          : "${trip.tripEndTime}  •  ${trip.tripEndAddress}",
                  

                    ),

                    const SizedBox(height: 18),

                    // OTP start card for scheduled upcoming trips
                    if (trip.status == TripStatus.upcoming) ...[
                      _otpStartCard(trip),
                      const SizedBox(height: 18),
                    ],

                    _bookingDetailsCard(trip),
                    const SizedBox(height: 18),

                    // detail card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // final fare row
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Final Fare",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 24,
                                   
                                  ),
                                ),
                              ),
                              Text(
                                "₹ ${trip.finalFare}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  
                                ),
                              ),
                            ],
                          ),

                          if (isCanceled && trip.cancelNote != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              trip.cancelNote!,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                height: 1.20,
                              ),
                            ),
                          ],

                          const SizedBox(height: 15),
                          const Divider(height: 3),
                          const SizedBox(height: 12),

                          // payment mode
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Payment mode",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 17,
                                  
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  trip.paymentMode,
                                  style: const TextStyle(
                                    color: DriverColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          if (!isCanceled) ...[
                            const Text(
                              "Fare breakdown",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Round Trip → hourly billing (no estimated time, no distance)
                            // One Way → distance billing (no hourly fields)
                            if (trip.tripType == 'Round Trip') ...[
                              _kv("Hourly package", "${trip.hourlyPackageHours} hours"),
                              _kv("Hourly rate", "₹ ${trip.hourlyRate}/hour"),
                              _kv("Extra time used", "${trip.extraTimeUsedMin} min"),
                            ],

                            if (trip.requireCarWash)
                              _kv("Car Wash Service", "₹ ${trip.carWashPrice}"),
                            const SizedBox(height: 12),
                            const Divider(height: 2),
                            const SizedBox(height: 12),
                            _kv("Platform Charge", "-₹ ${trip.platformCharge}"),
                            _kv("GST", "-₹ ${trip.gst}"),
                            const SizedBox(height: 8),
                            _kv("Net Earnings", "₹ ${trip.finalFare - trip.platformCharge - trip.gst}", isHighlight: true),
                            const SizedBox(height: 12),
                            const Divider(height: 2),
                            const SizedBox(height: 12),
                          ],

                          const Text(
                            "Trip Summary",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _kv("Booking ID", trip.bookingId),
                          // Round Trip: hide trip duration; One Way: show duration
                          if (trip.tripType != 'Round Trip') ...[
                            _kv("Trip duration", isCanceled ? "-" : trip.actualDuration),
                          ],
                          

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _otpStartCard(DriverTripHistoryModel trip) {
    if (trip.status != TripStatus.upcoming || trip.rawId == null) return const SizedBox.shrink();

    final now = DateTime.now();
    bool canStart = true;
    String buttonText = "Start Trip";

    if (trip.isScheduled && trip.rawDate != null) {
      final diff = trip.rawDate!.difference(now);
      if (diff.inMinutes > 45) {
        canStart = false;
        // Simple human readable time remaining
        if (diff.inHours > 0) {
          buttonText = "Start Trip (Too Early)";
        } else {
          buttonText = "Starts in ${diff.inMinutes - 45} min";
        }
      }
    }
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canStart ? () {
              // Skip OTP here, directly start normal booking flow
              Get.offAllNamed('/driver/trip/after-accept-location', parameters: {'rideId': trip.rawId!});
            } : () {
              Get.snackbar(
                "Too Early", 
                "You can start this trip 45 minutes before the scheduled time.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: canStart ? DriverColors.primary : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: canStart ? 4 : 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ),
        if (trip.isScheduled) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _informAdmin(context, trip),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Inform Admin (Unavailable)",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _informAdmin(BuildContext context, DriverTripHistoryModel trip) async {
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
              const Text("Inform Admin",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black)),
              const SizedBox(height: 4),
              const Text("Please tell us why you are unavailable for this scheduled ride. Admin will reassign this trip.",
                  style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 24),
              const Text("Reason",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter reason...",
                  fillColor: const Color(0xFFF9FAFB),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (descController.text.trim().isEmpty) {
                      Get.snackbar("Error", "Please provide a reason",
                          backgroundColor: Colors.red, colorText: Colors.white);
                      return;
                    }

                    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.orange)), barrierDismissible: false);
                    final res = await ApiService.informAdminUnavailable(
                      trip.rawId ?? "",
                      descController.text.trim(),
                    );
                    Get.back(); // close loader

                    if (res.containsKey('error')) {
                      Get.snackbar("Error", res['error'], backgroundColor: Colors.red, colorText: Colors.white);
                    } else {
                      Get.back(); // close bottomsheet
                      Get.back(); // close detail view
                      if (Get.isRegistered<DriverHistoryController>()) {
                        Get.find<DriverHistoryController>().removeScheduledTrip(trip.rawId ?? "");
                      }
                      // Snackbar removed per user request. FCM notification handles this.
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Notify Admin", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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


  static Widget _timeRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.access_time, size: 18, color: Colors.black45),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  height: 1.20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _bookingDetailsCard(DriverTripHistoryModel trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Booking Details", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 16),
          _kv("Car Type", trip.carType),
          _kv("Car Model", trip.carBrand),
          _kv("Trip Type", trip.tripType),
          // Only show package for non-One-Way trips
          if (trip.tripType != 'One Way') _kv("Usage Package", trip.carUsage),
          _kv("Car Wash Required", trip.requireCarWash ? "Yes" : "No"),
          if (trip.scheduledTimeText != "-") _kv("Scheduled Time", trip.scheduledTimeText),
          _kv("Booking Time", trip.bookingTimeText),
          _kv("Completion Time", trip.completionTimeText),
        ],
      ),
    );
  }

  static Widget _kv(String k, String v, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              k,
              style: TextStyle(
                color: isHighlight ? Colors.black : Colors.black54, 
                fontSize: 16,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: isHighlight ? 18 : 16,
                color: isHighlight ? Colors.green.shade700 : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, DriverTripHistoryModel trip) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.white)), barrierDismissible: false);
    final types = await ApiService.getDisputeTypes();
    Get.back(); // close loader

    if (types.isEmpty) {
      Get.snackbar("Info", "Dispute types not configured by admin",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white, colorText: Colors.black);
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
                      rideId: trip.rawId ?? "",
                      raisedBy: "Driver",
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






