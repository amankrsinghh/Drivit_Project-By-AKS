import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

import 'driver_app/routes/driver_pages.dart';
import 'driver_app/routes/driver_routes.dart';
import 'services/socket_service.dart';
import 'services/api_service.dart';
import 'services/network_service.dart';
import 'driver_app/splash/views/driver_splash_view.dart';

/// hi my name is aman kumar singh
void main() async {
  /// hi its me aman
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final ns = Get.put(NotificationService(), permanent: true);
  try {
    await ns.initialize();
  } catch (e) {
    debugPrint("Failed to initialize NotificationService: $e");
  }

  // We previously forced SurfaceView here, but SurfaceView punches a hole in the
  // window, causing the "transparent ghosting" bug during zoom.
  // We revert to the default Texture Layer Hybrid Composition (TLHC), which
  // safely composits the map within Flutter. Since our `IndexedStack` cleanly
  // keeps the map at full size, TLHC will no longer throw a white screen.

  final prefs = await SharedPreferences.getInstance();
  ApiService.enableGeofenceBoundary =
      prefs.getBool('enable_geofence_boundary') ?? false;
  ApiService.freeRidesCount = prefs.getInt('free_rides_count') ?? 3;
  ApiService.initialOnlineStatus = prefs.getBool('is_online') ?? false;

  // Fetch settings in background to avoid blocking app launch
  ApiService.getPublicSettings()
      .then((settings) async {
        if (settings.containsKey('enable_geofence_boundary')) {
          final freshGeofence = settings['enable_geofence_boundary'];
          final bool val =
              freshGeofence == true ||
              freshGeofence.toString().toLowerCase() == 'true';
          ApiService.enableGeofenceBoundary = val;
          await prefs.setBool('enable_geofence_boundary', val);
          debugPrint("Driver Geofence Setting Loaded from Backend: $val");
        }

        if (settings.containsKey('free_rides_count')) {
          final int val =
              int.tryParse(settings['free_rides_count'].toString()) ?? 3;
          ApiService.freeRidesCount = val;
          await prefs.setInt('free_rides_count', val);
          debugPrint("Driver Free Rides Limit Loaded from Backend: $val");
        }

        if (settings.containsKey('google_maps_api_key')) {
          final key = settings['google_maps_api_key'];
          ApiService.googleMapsApiKey = key;

          // Pass to native for iOS (GMSServices) - can be called multiple times safely
          const channel = MethodChannel('com.example.driver/map_api');
          channel.invokeMethod('setApiKey', {'apiKey': key}).catchError((e) {
            debugPrint("iOS setApiKey error: $e");
            return null;
          });
        }
      })
      .catchError((e) {
        debugPrint("Error fetching public settings: $e");
        return null;
      });
  final token = prefs.getString('jwt_token');
  String initialRoute = DriverRoutes.login;

  if (token != null && token.isNotEmpty) {
    Get.put(SocketService(), permanent: true);

    // CRITICAL: We no longer 'await' a network profile fetch here.
    // Instead, we use the CACHED status for instant routing.
    // The ProfileController will do a fresh background fetch anyway.

    final cachedProfile = await ApiService.getCachedDriverProfile();
    ApiService.cachedProfile = cachedProfile; // Store for synchronous access
    if (cachedProfile != null) {
      final status = cachedProfile['status'] ?? 'Pending';
      if (status == 'Approved' || status == 'Active') {
        initialRoute = DriverRoutes.home;
      } else {
        initialRoute = DriverRoutes.verificationPending;
      }
    } else {
      // If no cache, we can either block (one time) or assume login
      // Let's do a very fast attempt or default to home if token exists
      // Home will redirect to verification if needed after its own fetch.
      initialRoute = DriverRoutes.home;
    }
  }

  runApp(MyApp(targetRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String targetRoute;
  const MyApp({super.key, required this.targetRoute});

  @override
  Widget build(BuildContext context) {
    DriverSplashView.targetRoute = targetRoute;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Driver App",

      //  Starting page
      initialRoute: DriverRoutes.splash,
      initialBinding: BindingsBuilder(() {
        Get.put(NetworkService(), permanent: true);
      }),

      // All routing here
      getPages: DriverPages.pages,

      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        );
      },
    );
  }
}
