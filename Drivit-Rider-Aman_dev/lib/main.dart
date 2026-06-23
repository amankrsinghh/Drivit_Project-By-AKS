import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:rider/app/core/services/notification_service.dart';
import 'package:rider/app/core/middleware/auth_middleware.dart';
import 'package:rider/app/core/services/api_service.dart';
import 'package:rider/app/routes/app_pages.dart';
import 'package:rider/app/routes/app_routes.dart';
import 'package:rider/app/theme/app_theme.dart';
import 'package:rider/app/core/bindings/initial_binding.dart';
import 'package:rider/app/modules/splash/views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool loggedIn = false;
  bool isComplete = false;

  try {
    // Load token into in-memory store BEFORE the app renders
    final prefs = await SharedPreferences.getInstance();
    AuthStore.token = prefs.getString('customer_token');
    AuthStore.isComplete = prefs.getBool('profile_complete') ?? false;
    AuthStore.enableGeofenceBoundary =
        prefs.getBool('enable_geofence_boundary') ?? false;

    // Pre-load cached profile for synchronous access in controllers
    ApiService.cachedProfile = await ApiService.getCachedCustomerProfile();

    loggedIn = await ApiService.isLoggedIn();
    isComplete = await ApiService.isProfileComplete();
  } catch (e) {
    debugPrint('Auth initialization error: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize FCM Notification Service
    final notificationService = Get.put(NotificationService());
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Firebase/Notification initialization error: $e');
  }

  // Handle Google Maps API Key
  try {
    // 1. Load cached API Key for instant geocoding availability
    final cachedApiKey = await ApiService.getCachedGoogleMapsApiKey();
    if (cachedApiKey != null && cachedApiKey.isNotEmpty) {
      AuthStore.googleMapsApiKey = cachedApiKey;
      ApiService.googleMapsApiKey = cachedApiKey;
      debugPrint('Google Maps Key Loaded from Cache');

      // Set to native if already exists
      try {
        const channel = MethodChannel('com.example.rider/map_api');
        await channel.invokeMethod('setApiKey', {'apiKey': cachedApiKey});
      } catch (e) {
        debugPrint('Failed to set Cached API Key to Native: $e');
      }
    }

    // 2. Fetch fresh public settings for latest Google Maps API Key
    try {
      final settings = await ApiService.getPublicSettings();
      final freshApiKey = settings['google_maps_api_key'];
      final freshGeofence = settings['enable_geofence_boundary'];
      final prefs = await SharedPreferences.getInstance();

      if (freshGeofence != null) {
        final bool val =
            freshGeofence == true ||
            freshGeofence.toString().toLowerCase() == 'true';
        AuthStore.enableGeofenceBoundary = val;
        await prefs.setBool('enable_geofence_boundary', val);
        debugPrint('Geofence Setting Updated from Backend: $val');
      }

      if (freshApiKey != null && freshApiKey.isNotEmpty) {
        AuthStore.googleMapsApiKey = freshApiKey;
        ApiService.googleMapsApiKey = freshApiKey;
        await ApiService.saveGoogleMapsApiKey(freshApiKey); // Update cache
        debugPrint('Google Maps Key Updated from Backend');

        try {
          const channel = MethodChannel('com.example.rider/map_api');
          await channel.invokeMethod('setApiKey', {'apiKey': freshApiKey});
          debugPrint('Google Maps API Key synced to Native');
        } catch (e) {
          debugPrint('Failed to set Fresh API Key to Native: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading fresh settings: $e');
    }
  } catch (e) {
    debugPrint('Google Maps initialization error: $e');
  }

  String targetRoute = Routes.login;

  if (loggedIn && isComplete) {
    targetRoute = Routes.home;
  } else {
    targetRoute = Routes.login;
  }

  runApp(RiderApp(targetRoute: targetRoute));
}

class RiderApp extends StatelessWidget {
  final String targetRoute;
  const RiderApp({super.key, required this.targetRoute});

  @override
  Widget build(BuildContext context) {
    SplashView.targetRoute = targetRoute;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: Routes.splash,
        initialBinding: InitialBinding(), // Always initialize core dependencies
        getPages: AppPages.routes,
      ),
    );
  }
}
