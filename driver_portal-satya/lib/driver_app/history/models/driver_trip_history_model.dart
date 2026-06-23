enum TripStatus { completed, canceled, upcoming, expired }

class DriverTripHistoryModel {
  final String bookingId;
  final String driverName;
  final String? rawId;
  final String? rawCustomerId;
  final String? rawDriverId;

  final String dateLine; // "Tue, 18 Feb  •  6:45 PM"
  final String pickupShort; // "Adyar, 4th Main Road..."
  final String passenger; // "Pradeep Kumar"
  final String? passengerImage;
  final int amount; // 480

  final TripStatus status;

  // Details fields
  final String tripStartTime; // "10:00 AM"
  final String tripStartAddress; // "123 Vashali nagar , Jaipur"
  final String tripEndTime; // "11:00 PM"
  final String tripEndAddress; // "123 Malviya nagar , Jaipur"

  final int finalFare; // 640 or 80
  final String paymentMode; // "Cash"

  final int hourlyPackageHours;
  final int extraTimeUsedMin;
  final int estimatedTimeMin;
  final int hourlyRate;
  final int distanceCost;

  final String distance;
  final String actualDuration;
  final String bookingTimeText; // Real booking time (createdAt)
  final String scheduledTimeText; // Scheduled time (scheduledAt)
  final String completionTimeText; // Completion time (completedAt)
  final int platformCharge;
  final int gst;

  // for canceled screen note
  final String? cancelNote;

  // Raw date for filtering
  final DateTime? rawDate;
  
  // Mandatory booking fields
  final String carType;
  final String carBrand;
  final String tripType;
  final String carUsage;
  final String transmission;
  final bool isScheduled;
  final bool requireCarWash;
  final int carWashPrice;

  const DriverTripHistoryModel({
    required this.bookingId,
    required this.driverName,
    required this.dateLine,
    required this.pickupShort,
    required this.passenger,
    required this.amount,
    required this.status,
    required this.tripStartTime,
    required this.tripStartAddress,
    required this.tripEndTime,
    required this.tripEndAddress,
    required this.finalFare,
    required this.paymentMode,
    this.hourlyPackageHours = 0,
    this.extraTimeUsedMin = 0,
    this.estimatedTimeMin = 0,
    this.hourlyRate = 0,
    this.distanceCost = 0,

    this.distance = "-",
    this.actualDuration = "-",
    this.rawId,
    this.rawCustomerId,
    this.rawDriverId,
    this.passengerImage,
    this.cancelNote,
    this.rawDate,
    this.bookingTimeText = "-",
    this.scheduledTimeText = "-",
    this.completionTimeText = "-",
    this.carType = "-",
    this.carBrand = "-",
    this.tripType = "-",
    this.carUsage = "-",
    this.transmission = "-",
    this.isScheduled = false,
    this.requireCarWash = false,
    this.carWashPrice = 0,
    this.platformCharge = 0,
    this.gst = 0,
  });

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.round().toInt();
    if (val is num) return val.toInt();
    final parsed = double.tryParse(val.toString());
    return parsed?.round().toInt() ?? 0;
  }

  /// Parse from backend API response
  factory DriverTripHistoryModel.fromApi(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final scheduledAtStr = json['scheduledAt']?.toString();
    final isScheduled = json['isScheduled'] == true;
    final completedAtStr = json['completedAt']?.toString();
    
    final DateTime? scheduledDate = scheduledAtStr != null ? DateTime.tryParse(scheduledAtStr)?.toLocal() : null;
    final DateTime? completedDate = completedAtStr != null ? DateTime.tryParse(completedAtStr)?.toLocal() : null;

    // ✅ User specifies that cards must show booking time exactly as entered
    // Display date for the card: booking time for past, scheduled time for scheduled
    final displayDate = isScheduled ? (scheduledDate ?? createdAt) : createdAt;
    final dateStr = _formatDate(displayDate);

    // Sorting/Grouping date: actual completion time for past, scheduled time for scheduled
    DateTime relevantDate = isScheduled ? (scheduledDate ?? createdAt) : (completedDate ?? createdAt);

    final rideStatus = (json['status'] as String? ?? 'Pending').toLowerCase().trim();
    TripStatus tripStatus;

    if (rideStatus == 'completed') {
      tripStatus = TripStatus.completed;
    } else if (rideStatus == 'cancelled' ||
        rideStatus == 'canceled' ||
        rideStatus == 'rejected' ||
        rideStatus == 'cancelled_by_driver') {
      tripStatus = TripStatus.canceled;
    } else if (rideStatus == 'expired') {
      tripStatus = TripStatus.expired;
    } else if (['accepted', 'arrived', 'ongoing', 'started'].contains(rideStatus)) {
      tripStatus = TripStatus.upcoming;
    } else {
      // For all other statuses (Pending, etc.), check the date
      if (isScheduled && rideStatus != 'completed') {
        tripStatus = TripStatus.upcoming;
      } else if (relevantDate.isAfter(DateTime.now())) {
        tripStatus = TripStatus.upcoming;
      } else {
        // If the trip is in the past but not completed/cancelled, 
        // treat it as canceled/missed in the history view for clarity.
        tripStatus = TripStatus.canceled;
      }
    }

    final customer = json['customerId'];
    final customerName = customer is Map
        ? (customer['name'] ?? 'Unknown Passenger')
        : 'Unknown Passenger';
    final customerImage = customer is Map ? customer['profileImage']?.toString() : null;

    final fare = _parseInt(json['fare']);

    final startedAtStr = json['startedAt']?.toString();
    
    String finalStartTime = _formatTime(relevantDate); 
    if (startedAtStr != null) {
      final sdt = DateTime.tryParse(startedAtStr)?.toLocal();
      if (sdt != null) finalStartTime = _formatTime(sdt);
    }

    String finalEndTime = 'N/A';
    if (completedDate != null) {
       finalEndTime = _formatTime(completedDate);
    } else if (tripStatus == TripStatus.completed) {
      // Fallback for old ones where we didn't have completedAt but they are marked completed
      finalEndTime = _formatTime(relevantDate.add(const Duration(minutes: 30))); // estimated fudge
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
    final scheduledTimeRaw = json['schedule_time'] ?? json['scheduledAt'];
    if (isScheduled && scheduledTimeRaw != null) {
      final sdtTime = DateTime.tryParse(scheduledTimeRaw.toString())?.toLocal();
      if (sdtTime != null) {
        final h = sdtTime.hour > 12 ? sdtTime.hour - 12 : (sdtTime.hour == 0 ? 12 : sdtTime.hour);
        final m = sdtTime.minute.toString().padLeft(2, '0');
        final a = sdtTime.hour >= 12 ? 'PM' : 'AM';
        finalScheduledTime = "${sdtTime.day}/${sdtTime.month}/${sdtTime.year} $h:$m $a";
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

    return DriverTripHistoryModel(
      bookingId: bId,
      driverName: 'Me',
      dateLine: dateStr,
      pickupShort: (json['pickupLocation'] as String? ?? 'N/A').length > 25
          ? '${(json['pickupLocation'] as String).substring(0, 25)}...'
          : (json['pickupLocation'] as String? ?? 'N/A'),
      passenger: customerName.toString(),
      amount: fare,
      status: tripStatus,
      tripStartTime: finalStartTime,
      tripStartAddress: json['pickupLocation'] as String? ?? 'N/A',
      tripEndTime: finalEndTime,
      tripEndAddress: json['dropoffLocation'] as String? ?? 'N/A',
      finalFare: fare,
      paymentMode: json['paymentMethod']?.toString() ?? 'Online',
      hourlyPackageHours: _parseInt(json['packageHours']),
      extraTimeUsedMin: _parseInt(json['extraTimeUsed']),
      estimatedTimeMin: _parseInt(json['estimatedTime']),
      hourlyRate: _parseInt(json['hourlyRate']),
      distanceCost: _parseInt(json['distanceCost']),

      distance: "${json['distance'] ?? '-'} km",
      actualDuration: json['actualDuration'] != null ? _formatDurationText(json['actualDuration']) : (tripStatus == TripStatus.completed ? "30 min" : "-"),
      rawId: json['_id']?.toString(),
      rawCustomerId: (customer is Map) ? customer['_id']?.toString() : null,
      rawDriverId: json['driverId'] is Map ? json['driverId']['_id']?.toString() : json['driverId']?.toString(),
      passengerImage: customerImage,
      cancelNote:
          (rideStatus == 'cancelled' ||
              rideStatus == 'canceled' ||
              rideStatus == 'rejected' ||
              rideStatus == 'cancelled_by_driver')
          ? 'Ride was ${json['status']}'
          : null,
      rawDate: relevantDate,
      carType: json['carType']?.toString() ?? "-",
      carBrand: json['carModel']?.toString() ?? "-",
      tripType: json['tripType']?.toString() ?? "-",
      carUsage: (json['carPackage'] ?? json['package'])?.toString() ?? "-",
      transmission: json['transmission']?.toString() ?? "-",
      isScheduled: isScheduled,
      requireCarWash: json['requireCarWash'] == true,
      carWashPrice: _parseInt(json['carWashPrice']),
      bookingTimeText: finalBookingTime,
      scheduledTimeText: finalScheduledTime, // populate correctly
      completionTimeText: finalCompletionTime,
      platformCharge: _parseInt(json['platformCharge']),
      gst: _parseInt(json['gst']),
    );
  }


  static String _formatDurationText(dynamic min) {
    if (min == null) return "-";
    final int m = (min is int) ? min : (int.tryParse(min.toString()) ?? 0);
    if (m <= 0) return "0 min";
    if (m < 60) return "$m min";
    final int h = m ~/ 60;
    final int remainingM = m % 60;
    if (remainingM == 0) return "$h hours";
    return "$h hours $remainingM min";
  }

  static String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = days[d.weekday - 1];
    final month = months[d.month - 1];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$day, ${d.day} $month  •  $hour:$minute $ampm';
  }

  static String _formatTime(DateTime d) {
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
