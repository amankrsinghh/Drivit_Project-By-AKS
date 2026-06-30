enum RideSegment { past, scheduled }

enum RideStatus { completed, cancelled, upcoming, expired, unassigned }

enum CancellationType {
  none,
  afterDriverArrival, // "Canceled after ride start" screen
  beforeDriverArrival, // "Canceled before arrival" screen
  freeCancelBeforeXMinute, // "Canceled" (₹0) screen
}

class RideItem {
  final String section;         // For past trips: Today / This Week / This Month
  final String scheduledSection; // For scheduled trips: Today / This Week / This Month (based on scheduledAt)
  final String dateText;
  final String timeText;
  final String address;
  final String driverName; // list me use hota hai
  final String? driverProfileImage; 
  final double amount;
  final RideStatus status;
  final String? rawId;
  final String? rawDriverId;
  final String? rawCustomerId;
  final DateTime? createdAt;
  final bool isDriverRated;
  final String otp;
  final String driverPhone;
  final String vehicleInfo;
  final String carType;
  final String carModel;
  final String carPackage;
  final String tripType;
  final String transmission;
  final bool requireCarWash;
  final bool isScheduled;
  final double carWashPrice;

  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  // ----- Details page (image) -----
  final String rideTitle; // "Book Driver" (top line)

  final String tripStartTime; // 10:00 AM
  final String tripStartAddress; // 123 Vaishali nagar, Jaipur

  final String tripEndTime; // 11:00 AM (completed only)
  final String tripEndAddress; // 123 Malviya nagar, Jaipur (completed only)

  final String paymentMode; // "Cash" or "-"
  final String bookingId; // 54698BA45
  final String tripDurationText; // 2 hours 10 min / "-"
  final String distanceText; // 22.4 km / "-"

  // Completed fare breakdown
  final int hourlyPackageHours; // 2
  final int extraTimeUsedMin; // 10
  final int estimatedTimeMin; // 120
  final double hourlyRate; // 150
  final double distanceCost;  //
  final double platformCharge;
  final double gst;
  final double returnCharge;
  final String bookingTimeText; // Real booking time (createdAt)
  final String scheduledTimeText; // Scheduled time (scheduledAt)
  final String completionTimeText; // Completion time (completedAt)

  final CancellationType cancellationType;

  const RideItem({
    required this.section,
    this.scheduledSection = "This Month",
    required this.dateText,
    required this.timeText,
    required this.address,
    required this.driverName,
    this.driverProfileImage,
    required this.amount,
    required this.status,
    this.rideTitle = "Book Driver",

    this.tripStartTime = "-",
    this.tripStartAddress = "-",
    this.tripEndTime = "-",
    this.tripEndAddress = "-",

    this.paymentMode = "-",
    this.bookingId = "-",
    this.tripDurationText = "-",
    this.distanceText = "-",

    this.hourlyPackageHours = 0,
    this.extraTimeUsedMin = 0,
    this.estimatedTimeMin = 0,
    this.hourlyRate = 0,
    this.distanceCost = 0,
    this.platformCharge = 0,
    this.gst = 0,
    this.returnCharge = 0,


    this.rawId,
    this.rawDriverId,
    this.rawCustomerId,
    this.createdAt,
    this.isDriverRated = false,
    this.bookingTimeText = "-",
    this.scheduledTimeText = "-",
    this.completionTimeText = "-",
    this.cancellationType = CancellationType.none,
    this.otp = "-",
    this.driverPhone = "-",
    this.vehicleInfo = "-",
    this.carType = "-",
    this.carModel = "-",
    this.carPackage = "-",
    this.tripType = "-",
    this.transmission = "-",
    this.requireCarWash = false,
    this.isScheduled = false,
    this.carWashPrice = 0.0,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  factory RideItem.fromApi(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'Pending').toLowerCase();
    RideStatus rStatus;
    if (statusStr == 'completed') {
      rStatus = RideStatus.completed;
    } else if (statusStr == 'unassigned') {
      rStatus = RideStatus.unassigned;
    } else if (statusStr.contains('cancel')) {
      rStatus = RideStatus.cancelled;
    } else if (statusStr == 'expired') {
      rStatus = RideStatus.expired;
    } else {
      rStatus = RideStatus.upcoming;
    }

    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'])?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final scheduledAtStr = json['scheduledAt']?.toString();
    final isScheduled = json['isScheduled'] == true;
    final completedAtStr = json['completedAt']?.toString();

    final DateTime? scheduledDate = scheduledAtStr != null ? DateTime.tryParse(scheduledAtStr)?.toLocal() : null;
    final DateTime? completedDate = completedAtStr != null ? DateTime.tryParse(completedAtStr)?.toLocal() : null;
    
    // ✅ User specifies that cards must show booking time exactly as entered
    // For normal rides: this is createdAt. For scheduled rides: this is scheduledAt.
    DateTime? relevantDate = isScheduled ? (scheduledDate ?? createdAt) : createdAt;
    
    // ✅ Section grouping:
    // - Past rides (completed/cancelled): always group by createdAt (past dates only)
    //   → Today / This Week / This Month
    // - Upcoming/Scheduled rides: group by scheduledAt (can be future)
    //   → Today / This Week / This Month (based on upcoming date)

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // --- Past section (for completed/cancelled rides, always past-based) ---
    final DateTime pastSectionDate = createdAt;
    final rDatePast = DateTime(pastSectionDate.year, pastSectionDate.month, pastSectionDate.day);
    final diffDaysPast = today.difference(rDatePast).inDays;
    String sectionStr;
    if (diffDaysPast == 0) {
      sectionStr = "Today";
    } else if (diffDaysPast > 0 && diffDaysPast <= 7) {
      sectionStr = "This Week";
    } else {
      sectionStr = "This Month"; // anything older goes to This Month
    }

    // --- Scheduled section (for upcoming rides, future-aware grouping) ---
    final DateTime scheduledSectionDate = isScheduled
        ? (scheduledDate ?? createdAt)
        : createdAt;
    final rDateSched = DateTime(scheduledSectionDate.year, scheduledSectionDate.month, scheduledSectionDate.day);
    final diffDaysSched = rDateSched.difference(today).inDays; // positive = future
    String scheduledSectionStr;
    if (diffDaysSched == 0) {
      scheduledSectionStr = "Today";
    } else if (diffDaysSched > 0 && diffDaysSched <= 7) {
      scheduledSectionStr = "This Week";
    } else if (diffDaysSched < 0 && diffDaysSched >= -7) {
      // Scheduled in the past but within a week (shouldn't normally appear in scheduled section)
      scheduledSectionStr = "This Week";
    } else if (diffDaysSched < 0) {
      scheduledSectionStr = "This Month";
    } else {
      scheduledSectionStr = "This Month"; // > 7 days in future
    }

    final dateText = "${relevantDate.day}/${relevantDate.month}/${relevantDate.year}";
    
    final hour = relevantDate.hour > 12 ? relevantDate.hour - 12 : (relevantDate.hour == 0 ? 12 : relevantDate.hour);
    final minute = relevantDate.minute.toString().padLeft(2, '0');
    final ampm = relevantDate.hour >= 12 ? 'PM' : 'AM';
    final String finalTimeText = "$hour:$minute $ampm";

    final driver = json['driverId'];
    String dName = (driver is Map) ? (driver['name'] ?? "Driver") : "Driver";
    
    bool callerIsUser = false;
    final cancelledBy = json['cancelledBy']?.toString().toLowerCase() ?? json['canceledBy']?.toString().toLowerCase();
    
    if (cancelledBy == 'customer' || cancelledBy == 'rider' || 
        statusStr == 'cancelled_by_customer' || statusStr == 'customer_cancelled') {
      callerIsUser = true;
    } else if (rStatus == RideStatus.cancelled && driver == null) {
      callerIsUser = true;
    }
    
    final driverName = callerIsUser ? "User" : dName;
    final driverProfileImage = (driver is Map) ? driver['profileImage']?.toString() : null;
    final driverId = (driver is Map) ? driver['_id']?.toString() : (driver?.toString());
    final dPhone = (driver is Map) ? (driver['phone']?.toString() ?? driver['mobile']?.toString() ?? "-") : "-";
    final vNum = (driver is Map) ? (driver['vehicleNumber'] ?? "") : "";
    final vMod = (driver is Map) ? (driver['vehicleModel'] ?? "") : "";
    final vInfo = "$vMod $vNum".trim();
    
    final customer = json['customerId'];
    final customerId = (customer is Map) ? customer['_id']?.toString() : (customer?.toString());

    final startedAtStr = json['startedAt']?.toString();
    
    String finalStartTime = finalTimeText; // fallback to scheduled/created time
    if (startedAtStr != null) {
      final sdt = DateTime.tryParse(startedAtStr)?.toLocal();
      if (sdt != null) {
         final h = sdt.hour > 12 ? sdt.hour - 12 : (sdt.hour == 0 ? 12 : sdt.hour);
         final m = sdt.minute.toString().padLeft(2, '0');
         final a = sdt.hour >= 12 ? 'PM' : 'AM';
         finalStartTime = "$h:$m $a";
      }
    }

    String finalEndTime = "-";
    if (completedDate != null) {
       final edt = completedDate;
       final h = edt.hour > 12 ? edt.hour - 12 : (edt.hour == 0 ? 12 : edt.hour);
       final m = edt.minute.toString().padLeft(2, '0');
       final a = edt.hour >= 12 ? 'PM' : 'AM';
       finalEndTime = "$h:$m $a";
    } else if (rStatus == RideStatus.completed) {
       // fallback for old completed rides
       finalEndTime = finalTimeText; 
    }

    String finalBookingTime = "-";
    final bookingTimeRaw = json['booking_time'] ?? json['createdAt'];
    if (bookingTimeRaw != null) {
      final bdt = DateTime.tryParse(bookingTimeRaw.toString())?.toLocal();
      if (bdt != null) {
        final h = bdt.hour > 12 ? bdt.hour - 12 : (bdt.hour == 0 ? 12 : bdt.hour);
        final m = bdt.minute.toString().padLeft(2, '0');
        final a = bdt.hour >= 12 ? 'PM' : 'AM';
        finalBookingTime = "${bdt.day}/${bdt.month}/${bdt.year} $h:$m $a";
      }
    }

    String finalScheduledTime = "-";
    final scheduleTimeRaw = json['schedule_time'] ?? json['scheduledAt'];
    if (isScheduled && scheduleTimeRaw != null) {
      final sdt = DateTime.tryParse(scheduleTimeRaw.toString())?.toLocal();
      if (sdt != null) {
        final h = sdt.hour > 12 ? sdt.hour - 12 : (sdt.hour == 0 ? 12 : sdt.hour);
        final m = sdt.minute.toString().padLeft(2, '0');
        final a = sdt.hour >= 12 ? 'PM' : 'AM';
        finalScheduledTime = "${sdt.day}/${sdt.month}/${sdt.year} $h:$m $a";
      }
    }

    String finalCompletionTime = "-";
    if (completedAtStr != null) {
      final edt = DateTime.tryParse(completedAtStr)?.toLocal();
      if (edt != null) {
        final h = edt.hour > 12 ? edt.hour - 12 : (edt.hour == 0 ? 12 : edt.hour);
        final m = edt.minute.toString().padLeft(2, '0');
        final a = edt.hour >= 12 ? 'PM' : 'AM';
        finalCompletionTime = "${edt.day}/${edt.month}/${edt.year} $h:$m $a";
      }
    }

    // Identical booking ID logic: prioritize booking_id field from backend
    String bId = json['booking_id']?.toString() ?? "";
    if (bId.isEmpty) {
      // Fallback to same logic as other side if missing
      final idStr = json['_id']?.toString() ?? "";
      final last8 = idStr.substring((idStr.length - 8).clamp(0, idStr.length)).toUpperCase();
      bId = "RID$last8";
    }

    return RideItem(
      section: sectionStr,
      scheduledSection: scheduledSectionStr,
      dateText: dateText,
      timeText: finalTimeText,
      address: json['pickupLocation'] ?? "-",
      driverName: driverName,
      driverProfileImage: driverProfileImage,
      amount: (json['fare'] ?? 0.0).toDouble(),
      status: rStatus,
      rawId: json['_id']?.toString(),
      rawDriverId: driverId,
      rawCustomerId: customerId,
      bookingId: bId,
      tripStartTime: finalStartTime,
      tripEndTime: finalEndTime,
      tripStartAddress: json['pickupLocation'] ?? "-",
      tripEndAddress: json['dropoffLocation'] ?? "-",
      tripDurationText: json['actualDuration'] != null 
          ? _formatDurationText(json['actualDuration']) 
          : (rStatus == RideStatus.completed ? "30 min" : "-"),
      distanceText: "${json['distance'] ?? '-'} km",
      paymentMode: json['paymentMethod']?.toString() ?? 'Online',
      hourlyPackageHours: (json['packageHours'] ?? 0).toInt(),
      extraTimeUsedMin: (json['extraTimeUsed'] ?? 0).toInt(),
      estimatedTimeMin: (json['estimatedTime'] ?? 0).toInt(),
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      distanceCost: (json['distanceCost'] ?? 0.0).toDouble(),
      platformCharge: (json['platformCharge'] ?? 0.0).toDouble(),
      gst: (json['gst'] ?? 0.0).toDouble(),
      returnCharge: (json['returnCharge'] ?? 0.0).toDouble(),

      createdAt: relevantDate,
      isDriverRated: json['is_driver_rated'] ?? false,
      otp: json['otp']?.toString() ?? "-",
      driverPhone: dPhone,
      vehicleInfo: vInfo.isEmpty ? "-" : vInfo,
      carType: json['carType']?.toString() ?? "-",
      carModel: json['carModel']?.toString() ?? "-",
      carPackage: (json['carPackage'] ?? json['package'])?.toString() ?? "-",
      tripType: json['tripType']?.toString() ?? "-",
      transmission: json['transmission']?.toString() ?? "-",
      requireCarWash: json['requireCarWash'] == true,
      carWashPrice: (json['carWashPrice'] ?? 0.0).toDouble(),
      bookingTimeText: finalBookingTime,
      scheduledTimeText: finalScheduledTime,
      completionTimeText: finalCompletionTime,
      isScheduled: isScheduled,
      pickupLat: (json['pickupCoords']?['lat'] as num?)?.toDouble(),
      pickupLng: (json['pickupCoords']?['lng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoffCoords']?['lat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoffCoords']?['lng'] as num?)?.toDouble(),
    );

  }

  static String _formatDurationText(dynamic min) {
    if (min == null) return "-";
    final int m = (min is int) ? min : (int.tryParse(min.toString()) ?? 0);
    if (m <= 0) return "0 min";
    if (m < 60) return "$m min";
    final int h = m ~/ 60;
    final int remainingM = m % 60;
    if (remainingM == 0) return "$h hr";
    return "$h hr $remainingM min";
  }
}
