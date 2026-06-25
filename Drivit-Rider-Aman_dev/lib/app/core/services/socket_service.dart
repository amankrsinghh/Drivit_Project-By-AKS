import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'api_service.dart';
import '../middleware/auth_middleware.dart';
import '../utils/geofence_util.dart';
import '../../modules/map/controllers/map_controller.dart';
import '../../modules/my_ride/controllers/my_ride_controller.dart';
import '../../modules/finding_drivers/controllers/finding_driver_controller.dart';
import '../../modules/my_ride/models/ride_items.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../routes/app_routes.dart'; // import for Get.toNamed(Routes.findingDriver)
import '../../modules/home/controllers/home_controller.dart';

class SocketService extends GetxService {
  IO.Socket? socket;
  final isConnected = false.obs;
  final settingsUpdateTrigger = 0.obs;

  static SocketService get to => Get.find();

  static const String socketUrl =
      'https://backend-production-e76e.up.railway.app';

  @override
  void onInit() {
    super.onInit();
    initSocket();
  }

  void initSocket() async {
    final customerId = await ApiService.getCustomerId();
    if (customerId == null) return;

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket?.connect();

    socket?.onConnect((_) {
      print('Rider Socket connected');
      isConnected.value = true;
      socket?.emit('customer:join', customerId);
    });

    socket?.onDisconnect((_) {
      print('Rider Socket disconnected');
      isConnected.value = false;
    });

    socket?.onConnectError((err) => print('Socket Connect Error: $err'));

    // Global Chat Notifications
    socket?.on('chat:notification', (data) {
      final title = "New Message from ${data['senderName']}";
      final body = data['text'];

      // FCM handles the persistent notification and banner. 
      // Sockets are used for real-time state updates if needed.
      debugPrint("Socket: Chat notification received for $title");
    });

    // Customer specific notifications
    socket?.on('customer:notification', (data) {
      if (data != null && data is Map) {
          final title = data['title'] ?? 'Notification';
          final body = data['body'] ?? '';

          debugPrint("Socket: Customer notification received: $title");
          // FCM notification handles the UI feedback via status bar
      }
    });

    socket?.on('ride:status_changed', (data) {
      if (data != null && data is Map) {
        final status = data['status'];
        final isCancelled = status?.toString().toLowerCase() == 'cancelled' || status?.toString().toLowerCase() == 'cancelled_by_driver';
        
        final title = "Ride Update";
        String body = "Your ride is now $status";

        if (status == 'Completed') {
          final fare = data['fare'] ?? '0';
          body = "Ride complete, please make payment to the driver: ₹$fare";
        }

        // Provide clear cancellation message
        if (isCancelled) {
          bool callerIsUser = false;
          
          if (Get.isRegistered<FindingDriverController>() && Get.find<FindingDriverController>().isCancelling.value) {
            callerIsUser = true;
          }
          
          if (data['cancelledBy']?.toString().toLowerCase() == 'customer' || 
              data['cancelledBy']?.toString().toLowerCase() == 'rider' ||
              data['canceledBy']?.toString().toLowerCase() == 'customer' || 
              data['canceledBy']?.toString().toLowerCase() == 'rider' ||
              status?.toString().toLowerCase() == 'cancelled_by_customer' ||
              status?.toString().toLowerCase() == 'customer_cancelled') {
             callerIsUser = true;
          }

          if (callerIsUser) {
             body = "Ride canceled by user";
          } else {
             String dName = "Driver";
             if (data['driverId'] != null && data['driverId'] is Map && data['driverId']['name'] != null) {
               dName = data['driverId']['name'] ?? "Driver";
             }
             body = "Canceled by $dName";
          }
        }

        // FCM notification handles the persistent list and system banner.
        // We only keep the real-time list refresh and redirection logic here.
        debugPrint("Socket: Ride status changed to $status");

        // Refresh My Ride list if open
        if (Get.isRegistered<MyRideController>()) {
          Get.find<MyRideController>().fetchMyRides(silent: true);
        }

        // Refresh Home active ride if HomeController is registered
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refreshActiveRideState();
        }

        // ✅ HANDLE SCHEDULED RIDE UNASSIGNMENT
        // When a driver unassigns, status becomes 'Unassigned' for a scheduled ride
        if (status == 'Unassigned' && data['isScheduled'] == true) {
            // If user is NOT on Home tab (likely on Detail View or Chat), redirect them to Scheduled Trips list
            if (Get.currentRoute != Routes.home && Get.currentRoute != Routes.findingDriver) {
                Get.offAllNamed(Routes.home, arguments: { 'tab': 1, 'segment': RideSegment.scheduled });
                
                Get.snackbar(
                    "Ride Update",
                    "A driver has unassigned from your scheduled ride. We are looking for a new driver.",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 5),
                );
            }
        }

        // ✅ AUTO-REDIRECT for Scheduled/Background Rides:
        // If a ride becomes Ongoing (Start Trip) or driver Arrives/Accepts, and rider is NOT on the live tracking screen,
        // force them into the live tracking screen so they can see the riding flow and payment page!
        if (status == 'Ongoing' || status == 'Accepted' || status == 'Completed' || status == 'Arrived') {
          if (!Get.isRegistered<FindingDriverController>() || Get.currentRoute != '/finding-driver') {
             // Avoid redirecting if it's a future scheduled ride that was just accepted
             bool isFutureSchedule = false;
             if (status == 'Accepted' && data['isScheduled'] == true && data['scheduledAt'] != null) {
                try {
                  final sDate = DateTime.parse(data['scheduledAt'].toString());
                  if (sDate.difference(DateTime.now()).inMinutes > 30) {
                     isFutureSchedule = true;
                  }
                } catch(e) {}
             }
             
             if (!isFutureSchedule) {
                 final rideIdStr = (data['_id'] ?? data['id'] ?? data['bookingId'])?.toString();
                 if (rideIdStr != null && rideIdStr.isNotEmpty) {
                    Get.toNamed(Routes.findingDriver, arguments: { 'rideId': rideIdStr });
                 }
             }
          }
        }
      }
    });

    socket?.on('settings:updated', (data) async {
      print('Settings updated from admin: $data');
      settingsUpdateTrigger.value++;

      if (data != null && data is Map) {
        final key = data['key'];
        final val = data['value'];
        if (key == 'enable_geofence_boundary') {
          final bool isEnabled = val == true || val.toString().toLowerCase() == 'true';
          AuthStore.enableGeofenceBoundary = isEnabled;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('enable_geofence_boundary', isEnabled);
          
          debugPrint("Rider Socket: enable_geofence_boundary updated to $isEnabled");
          
          if (isEnabled) {
            final currentRoute = Get.currentRoute;
            if (currentRoute == Routes.selectRide || currentRoute == Routes.selectRideMap) {
              LatLng? pos;
              if (Get.isRegistered<MapController>()) {
                pos = Get.find<MapController>().userPosition.value;
              }
              
              if (pos != null && !GeofenceUtil.isInsideChennai(pos.latitude, pos.longitude)) {
                debugPrint("Rider Socket: Rider is outside Chennai while geofencing was just enabled! Redirecting to home.");
                Get.offAllNamed(Routes.home);
                
                Get.dialog(
                  AlertDialog(
                    title: const Text("Service Unavailable"),
                    content: const Text("Chennai city boundary enforcement has been enabled, and you are outside the service area. You have been redirected to the home screen."),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text("OK", style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                );
              }
            }
          }
        }
      }
    });

    socket?.on('rating:updated', (data) {
      print('Rating updated: $data');
      if (Get.isRegistered<MyRideController>()) {
        Get.find<MyRideController>().fetchMyRides(silent: true);
      }
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().fetchProfile();
      }
      // If we are on finding driver screen, we might want to refresh details
      if (Get.isRegistered<FindingDriverController>()) {
        final fdc = Get.find<FindingDriverController>();
        if (fdc.rideDatabaseId.value.isNotEmpty) {
           fdc.fetchRideDetails(fdc.rideDatabaseId.value);
        }
      }
    });

    socket?.on('account_deleted', (data) async {
      if (data != null && data is Map && data['role'] != null) {
        if (data['role'] != 'customer') return;
      }
      debugPrint("SocketService: 🔴 Rider Account Deleted by admin! Instant logout.");
      await ApiService.logout();
      Get.offAllNamed(Routes.login);
    });
  }

  void joinRide(String rideId) {
    socket?.emit('ride:join', rideId);
  }

  @override
  void onClose() {
    socket?.dispose();
    super.onClose();
  }
}
