import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/ride_items.dart';
import '../../../core/services/api_service.dart';
import '../../../widgets/dialogs/driver_rating_dialog.dart';

class MyRideController extends GetxController {
  final pageController = PageController();
  final segment = RideSegment.past.obs;
  final isLoading = false.obs;

  final pastTrips = <RideItem>[].obs;
  final scheduledTrips = <RideItem>[].obs;

  // Track trips already shown for rating in this session
  final _processedRatingTrips = <String>{};
  bool _isRatingDialogOpen = false;

  @override
  void onInit() {
    super.onInit();
    fetchMyRides();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> fetchMyRides({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final customerId = await ApiService.getCustomerId();
      if (customerId != null) {
        final rides = await ApiService.getCustomerRides(customerId);
        final mapped = rides.map((r) => RideItem.fromApi(r)).toList();
        
        // Client-side safety filter: only show rides for this customer
        final filtered = mapped.where((r) => r.rawCustomerId == customerId).toList();

        // ─── PAST TRIPS: completed rides OR cancelled rides where driver was assigned ───
        // These are non-scheduled normal rides that are done.
        final past = filtered.where((r) {
          if (r.isScheduled) return false; // Exclude scheduled rides from past tab entirely
          if (r.status == RideStatus.completed) return true;
          if (r.status == RideStatus.cancelled) {
            return r.rawDriverId != null && r.rawDriverId!.isNotEmpty;
          }
          return false;
        }).toList();

        // Sort past: newest first (by createdAt)
        past.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
        pastTrips.value = past;

        // ─── SCHEDULED TRIPS: ALL scheduled rides (upcoming, cancelled, completed) ────────
        // Keep scheduled rides exclusively in this tab as requested by user.
        final scheduled = filtered.where((r) {
          if (r.isScheduled != true) return false;
          // If cancelled, only show if driver was assigned (accepted first)
          if (r.status == RideStatus.cancelled) {
            return r.rawDriverId != null && r.rawDriverId!.isNotEmpty;
          }
          return true;
        }).toList();

        // Sort scheduled: soonest scheduled time first
        scheduled.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return da.compareTo(db); // ascending — soonest first
        });
        scheduledTrips.value = scheduled;
      }
    } catch (e) {
      print("Error fetching rides: $e");
    } finally {
      if (!silent) isLoading.value = false;
      _checkUnratedTrip();
    }
  }

  void _checkUnratedTrip() {
    // Only trigger for past (completed) trips
    final unrated = pastTrips.firstWhereOrNull((r) => 
        r.status == RideStatus.completed && 
        (r.paymentMode == "Paid" || r.paymentMode == "Online" || r.paymentMode == "Cash") && 
        !r.isDriverRated && 
        r.rawId != null && 
        !_processedRatingTrips.contains(r.rawId));

    if (unrated != null && !_isRatingDialogOpen) {
      _processedRatingTrips.add(unrated.rawId!);
      
      // Delay slightly to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isRatingDialogOpen) return;
        _isRatingDialogOpen = true;
        
        Get.dialog(
          DriverRatingDialog(
            ride: unrated,
            onComplete: () {
              _isRatingDialogOpen = false;
              fetchMyRides(); // Refresh to update isDriverRated flag
            },
          ),
          barrierDismissible: false,
        ).then((_) {
          _isRatingDialogOpen = false;
        });
      });
    }
  }

  void setSegment(RideSegment s) {
    segment.value = s;
    if (pageController.hasClients) {
      pageController.animateToPage(
        s == RideSegment.past ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<RideItem> get currentList =>
      segment.value == RideSegment.past ? pastTrips : scheduledTrips;
}