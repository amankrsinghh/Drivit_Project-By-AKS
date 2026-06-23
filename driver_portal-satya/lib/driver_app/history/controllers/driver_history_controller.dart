import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/driver_routes.dart';
import '../models/driver_trip_history_model.dart';
import '../../../services/api_service.dart';

class DriverHistoryController extends GetxController {
  late final PageController pageController;
  final tabIndex = 0.obs; // 0 Past Trips, 1 Scheduled Trips
  final isLoading = false.obs;
  final isMoreLoading = false.obs;
  
  // Pagination State
  int _currentPage = 1;
  final _limit = 100;
  bool _hasMore = true;


  // Actual data from API
  final allRides = <DriverTripHistoryModel>[].obs;
  final scheduledRides = <DriverTripHistoryModel>[].obs;

  // Filtered lists with de-duplication and sorting
  List<DriverTripHistoryModel> get pastTrips {
    final Map<String, DriverTripHistoryModel> unique = {};
    for (var r in allRides) {
      if (!r.isScheduled && r.rawId != null) {
        unique[r.rawId!] = r;
      }
    }
    final list = unique.values.toList();
    // Sort: most recent (booked or actual time) at the top
    list.sort((a, b) => (b.rawDate ?? DateTime(0)).compareTo(a.rawDate ?? DateTime(0)));
    return list;
  }

  List<DriverTripHistoryModel> get scheduledTrips {
    final Map<String, DriverTripHistoryModel> unique = {};
    for (var r in scheduledRides) {
      if (r.rawId != null) {
        unique[r.rawId!] = r;
      }
    }
    final list = unique.values.toList();
    // Sort: Chronological (ASC) for scheduled trips so soonest is first
    list.sort((a, b) => (a.rawDate ?? DateTime(0)).compareTo(b.rawDate ?? DateTime(0)));
    debugPrint("[History-Debug] Sorted ${list.length} scheduled trips in ASC order.");
    return list;
  }

  // --- Past Trip Grouping ---
  List<DriverTripHistoryModel> get pastToday {
    final now = DateTime.now();
    return pastTrips.where((r) {
      if (r.rawDate == null) return false;
      final d = r.rawDate!.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<DriverTripHistoryModel> get pastThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return pastTrips.where((r) {
      if (r.rawDate == null) return false;
      final d = r.rawDate!.toLocal();
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      return !isToday && d.isAfter(weekAgo);
    }).toList();
  }

  List<DriverTripHistoryModel> get pastThisMonth {
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    return pastTrips.where((r) {
      if (r.rawDate == null) return false;
      final d = r.rawDate!.toLocal();
      // This Month = anything older than a week (includes older than 30 days to show 'Complete history')
      return d.isBefore(weekAgo);
    }).toList();
  }

  List<DriverTripHistoryModel> get pastOlder => []; // Merged into This Month

  // --- Scheduled Trip Grouping ---
  List<DriverTripHistoryModel> get scheduledToday {
    final now = DateTime.now();
    return scheduledTrips.where((r) {
      if (r.rawDate == null) return false;
      final d = r.rawDate!.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<DriverTripHistoryModel> get scheduledThisWeek {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return scheduledTrips.where((r) {
      if (r.rawDate == null) return false;
      final d = r.rawDate!.toLocal();
      final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
      return !isToday && d.isAfter(weekAgo);
    }).toList();
  }

  List<DriverTripHistoryModel> get scheduledThisMonth {
    final now = DateTime.now();
    final weekAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    return scheduledTrips.where((r) {
      if (r.rawDate == null) return false;
      final d = r.rawDate!.toLocal();
      // This Month = anything older than a week
      return d.isBefore(weekAgo);
    }).toList();
  }

  List<DriverTripHistoryModel> get scheduledOlder => []; // Merged into This Month

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: tabIndex.value);
    fetchRides();
    fetchScheduledRides();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void setTab(int i) {
    tabIndex.value = i;
    if (pageController.hasClients) {
      pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    if (i == 1 && scheduledRides.isEmpty) {
      fetchScheduledRides();
    }
  }

  Future<void> fetchScheduledRides() async {
    try {
      // Fetch all scheduled rides without limit (handled by backend providing a large batch if isScheduled=true is passed)
      final res = await ApiService.getDriverRides(page: 1, limit: 1000, isScheduled: true);
      final List ridesData = res['rides'] ?? [];
      scheduledRides.assignAll(ridesData.map((r) => DriverTripHistoryModel.fromApi(r)).toList());
    } catch (e) {
      debugPrint("Error fetching scheduled rides: $e");
    }
  }

  Future<void> fetchRides({bool isLoadMore = false}) async {
    if (tabIndex.value == 1) {
      if (!isLoadMore) isLoading.value = true;
      try {
        await fetchScheduledRides();
      } finally {
        if (!isLoadMore) isLoading.value = false;
      }
      return;
    }

    if (isLoadMore) {
      if (!_hasMore || isMoreLoading.value) return;
      isMoreLoading.value = true;
    } else {
      isLoading.value = true;
      _currentPage = 1;
      _hasMore = true;
    }

    try {
      // For past trips, we filter by isScheduled=false in API if possible, or just fetch mixed and filter locally
      final res = await ApiService.getDriverRides(page: _currentPage, limit: _limit, isScheduled: false);
      final List ridesData = res['rides'] ?? [];
      final int totalPages = res['pages'] ?? 1;

      final mapped = 
          ridesData.map((r) => DriverTripHistoryModel.fromApi(r)).toList();
      
      if (isLoadMore) {
        allRides.addAll(mapped);
      } else {
        allRides.assignAll(mapped);
      }

      _hasMore = _currentPage < totalPages;
      if (_hasMore) _currentPage++;

      debugPrint("Fetched ${mapped.length} rides for history. Page: ${_currentPage - 1}");
    } catch (e) {
      debugPrint("Error fetching rides: $e");
      if (!isLoadMore) allRides.clear();
    } finally {
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }

  void openDetails(DriverTripHistoryModel trip) {
    Get.toNamed(DriverRoutes.tripDetails, arguments: trip);
  }

  void removeScheduledTrip(String rideId) {
    scheduledRides.removeWhere((r) => r.rawId == rideId);
    scheduledRides.refresh();
    allRides.removeWhere((r) => r.rawId == rideId);
    allRides.refresh();
    debugPrint("[History] Removed scheduled trip $rideId from local list.");
  }
}
