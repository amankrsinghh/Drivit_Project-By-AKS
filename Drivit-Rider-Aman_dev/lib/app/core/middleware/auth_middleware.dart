import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

/// A simple in-memory auth store. Set `token` when user logs in / app loads.
/// This is populated in `main()` before the app launches.
class AuthStore {
  static String? token;
  static bool isComplete = false;
  static String? googleMapsApiKey;
  static bool enableGeofenceBoundary = false;
}

/// GetX route middleware.
/// Runs before every protected route. Redirects to /login if not authenticated.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final token = AuthStore.token;
    final isComplete = AuthStore.isComplete;

    if (token == null || token.isEmpty) {
      if (route == Routes.register || route == Routes.login || route == Routes.mapConfirm) {
        return null;
      }
      return const RouteSettings(name: Routes.login);
    }

    // Incomplete profile – must complete it
    if (!isComplete) {
      if (route == Routes.carDetails || 
          route == Routes.register || 
          route == Routes.mapConfirm || 
          route == Routes.login || 
          route == "${Routes.login}/otp") {
        return null; // allow these routes
      }
      // If we are anywhere else, and starting the app, main.dart will push Login.
      // But if we are in the app, we should go back to completing profile.
      // Wait! The user says: "Do NOT navigate to any registration step on fresh start".
      // So let's NOT redirect to carDetails if we are at the home/protected route either?
      // No, they said "On fresh app open ... always open login".
      // Let's just allow login/register/mapConfirm/carDetails.
      return const RouteSettings(name: Routes.login);
    }

    return null; // authenticated and complete – proceed
  }
}
