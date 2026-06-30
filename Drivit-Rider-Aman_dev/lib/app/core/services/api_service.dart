import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../middleware/auth_middleware.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/profile/controllers/profile_controller.dart';
import '../../modules/my_ride/controllers/my_ride_controller.dart';
import '../../modules/packages/controllers/package_controller.dart';
import 'notification_service.dart';
import 'socket_service.dart';

class ApiService {
  static const String baseUrl =
      'https://backend-production-e76e.up.railway.app/api';

  static String? googleMapsApiKey;
  static Map<String, dynamic>? cachedProfile;

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    const serverUrl = 'https://backend-production-e76e.up.railway.app';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$serverUrl/$cleanPath';
  }

  static Future<List<dynamic>> getCarCategories() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/car-categories?t=$timestamp'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }


  static Future<Map<String, dynamic>> getPublicSettings() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/settings/public'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final Map<String, dynamic> settings = {};
        for (var item in data) {
          settings[item['key']] = item['value'];
        }
        return settings;
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching public settings: $e');
      return {};
    }
  }

  static Future<List<dynamic>> getTripTypes() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/trip-types?t=$timestamp'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching trip types: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getAllPackages() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/packages?t=$timestamp'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching packages: $e');
      return [];
    }
  }


  // ─── Token Management ───────────────────────────────────────────────────────

  static Future<void> saveSession(String token, String customerId) async {
    // ✅ NEW: Ensure no old data from previous session survives
    await logout();
    
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ NEW: Ensure notifications are cleared for the new account
    if (Get.isRegistered<NotificationService>()) {
      await Get.find<NotificationService>().reset();
    }
    
    await prefs.setString('customer_token', token);
    await prefs.setString('customer_id', customerId);
    AuthStore.token = token; 
    AuthStore.isComplete = false; // Reset by default until confirmed
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customer_token');
  }

  static Future<String?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customer_id');
  }

  static Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('profile_complete') ?? false;
  }

  static Future<void> setProfileComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_complete', complete);
    if (complete) {
      await prefs.setInt('registration_step', 4);
    }
    AuthStore.isComplete = complete; // Sync in-memory store
  }

  static Future<void> setRegistrationStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('registration_step', step);
  }

  static Future<int> getRegistrationStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('registration_step') ?? 0;
  }

  static Future<void> saveRegistrationData({String? name, String? email, String? address}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('reg_name', name);
    if (email != null) await prefs.setString('reg_email', email);
    if (address != null) await prefs.setString('reg_address', address);
  }

  static Future<Map<String, String?>> getRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('reg_name'),
      'email': prefs.getString('reg_email'),
      'address': prefs.getString('reg_address'),
    };
  }

  static Future<String?> getPendingPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_phone');
  }

  static Future<void> saveCustomerProfile(Map<String, dynamic> profile) async {
    cachedProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_profile', jsonEncode(profile));
    
    // Also save individual fields for quick access if needed elsewhere
    if (profile['name'] != null) await prefs.setString('customer_name', profile['name']);
    if (profile['phone'] != null) await prefs.setString('customer_phone', profile['phone']);
    if (profile['email'] != null) await prefs.setString('customer_email', profile['email']);
    if (profile['profile_complete'] != null) {
      await prefs.setBool('profile_complete', profile['profile_complete'] == true);
      AuthStore.isComplete = profile['profile_complete'] == true;
    }
  }

  static Future<Map<String, dynamic>?> getCachedCustomerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_profile');
    if (cached != null) {
      return jsonDecode(cached) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> saveGoogleMapsApiKey(String key) async {
    // Save Google Maps API Key to local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_maps_api_key', key);
  }

  static Future<String?> getCachedGoogleMapsApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_maps_api_key');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    // 1. Clear In-Memory Cache
    cachedProfile = null;
    AuthStore.token = null; 
    AuthStore.isComplete = false;

    final prefs = await SharedPreferences.getInstance();
    
    // 2. Tell backend to remove FCM token from this user's record
    try {
      final token = prefs.getString('customer_token');
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint("ApiService: Logout signal to backend failed (ignoring): $e");
    }

    // 3. WIPE ALL LOCAL STORAGE
    await prefs.clear();

    // 4. FORCE DELETE all permanent controllers to clear session state from memory
    try {
      if (Get.isRegistered<NotificationService>()) {
        await Get.find<NotificationService>().reset();
      }
      _delete<ProfileController>();
      _delete<MyRideController>();
      _delete<PackagesController>();
      _delete<HomeController>();
      _delete<SocketService>();
    } catch (e) {
      debugPrint("Error clearing controllers: $e");
    }
  }

  static void _delete<T>() {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>(force: true);
      }
    } catch (e) {}
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-fcm-token'),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
      return false;
    }
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      
      // ✅ GLOBAL SECURITY CHECK: If user is deleted or token invalid, force logout
      if (response.statusCode == 401 || response.statusCode == 404) {
        final message = (data is Map ? (data['message'] ?? data['error']) : '').toString().toLowerCase();
        if (message.contains('not authorized') || message.contains('not found') || message.contains('user not found')) {
          debugPrint("ApiService: Global Auth Failure (${response.statusCode}). Triggering logout.");
          logout(); 
          // Do not return data, as we are navigating away
          return {'error': 'Session expired or account deleted'};
        }
      }

      if (response.statusCode >= 400) {
        if (data is Map) {
          data['error'] = data['message'] ?? 'Error ${response.statusCode}';
          return Map<String, dynamic>.from(data);
        }
        return {'error': 'Error ${response.statusCode}'};
      }
      if (data is Map) return Map<String, dynamic>.from(data);
      return {'data': data};
    } catch (e) {
      if (response.statusCode >= 500) {
        return {'error': 'Server under maintenance. Please try again later.'};
      }
      return {'error': 'Invalid server response: $e'};
    }
  }

  // ─── Customer Auth ───────────────────────────────────────────────────────────

  /// Send OTP to phone (Generic)
  static Future<Map<String, dynamic>> sendOtp(
    String phone, {
    String role = 'customer',
  }) async {
    try {
      // 🔔 Fetch FCM token to include in request for push notification
      String? fcmToken;
      try {
        if (Get.isRegistered<NotificationService>()) {
          fcmToken = await Get.find<NotificationService>().getFcmToken();
        }
      } catch (e) {
        debugPrint("ApiService: Could not fetch FCM token for OTP: $e");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone, 
          'role': role,
          if (fcmToken != null) 'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout. Please check your internet.'};
    } catch (e) {
      return {'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify OTP and login if exists
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp, 'role': role}),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout. Please try again.'};
    } catch (e) {
      return {'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Register a new customer with car details
  static Future<Map<String, dynamic>> registerCustomer({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? carModel,
    String? carNumber,
    String? carType,
    String? transmission,
    String? fuelType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/customer/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'carModel': carModel,
          'carNumber': carNumber,
          'carType': carType,
          'transmission': transmission,
          'fuelType': fuelType,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Check if email or phone exists
  static Future<Map<String, dynamic>> checkAvailability({String? email, String? phone}) async {
    try {
      String query = "";
      if (email != null) query += "email=$email";
      if (phone != null) query += "${query.isEmpty ? '' : '&'}phone=$phone";
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-availability?$query'),
        headers: {'Content-Type': 'application/json'},
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Original login kept for compatibility but preferred is verifyOtp
  static Future<Map<String, dynamic>> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/customer/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get customer profile
  static Future<Map<String, dynamic>> getCustomerProfile(
    String customerId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$customerId'),
        headers: await _authHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get ride by ID
  static Future<Map<String, dynamic>> getRideById(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout. Please try again.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Update customer profile (Supports image upload)
  static Future<Map<String, dynamic>> updateCustomerProfile(
    Map<String, dynamic> data, {
    String? profileImagePath,
  }) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/customers/profile'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      data.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('profileImage', profileImagePath),
        );
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Rides (Customer) ────────────────────────────────────────────────────────

  /// Create a new ride request
  static Future<Map<String, dynamic>> createRide({
    required String pickupLocation,
    required String dropoffLocation,
    required double fare,
    required double distance,
    String? carType,
    String? carModel,
    String? package,
    String? tripType,
    String? transmission,
    bool requireCarWash = false,
    double carWashPrice = 0,

    Map<String, double>? pickupCoords,
    Map<String, double>? dropoffCoords,
    String? paymentStatus,
    String? paymentId,
    bool isScheduled = false,
    String? scheduledAt,
    double? hourlyRate,
    double? extraTimeUsed,
    double? packageHours,
    double? estimatedTime,
    double? subtotal,
    double? platformCharge,
    double? gst,
  }) async {
    try {
      final customerId = await getCustomerId();
      if (customerId == null) return {'error': 'User not logged in'};

      final response = await http.post(
        Uri.parse('$baseUrl/rides'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'customerId': customerId,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'pickupCoords': pickupCoords,
          'dropoffCoords': dropoffCoords,
          'fare': fare,
          'distance': distance,
          'carType': carType,
          'carModel': carModel,
          'carPackage': package,
          'tripType': tripType,
          'transmission': transmission,
          'requireCarWash': requireCarWash,
          'carWashPrice': carWashPrice,

          'paymentStatus': paymentStatus,
          'paymentId': paymentId,
          'isScheduled': isScheduled,
          'scheduledAt': scheduledAt,
          'hourlyRate': hourlyRate,
          'extraTimeUsed': extraTimeUsed,
          'packageHours': packageHours,
          'estimatedTime': estimatedTime,
          'subtotal': subtotal,
          'platformCharge': platformCharge,
          'gst': gst,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get all rides for this customer
  static Future<List<dynamic>> getCustomerRides(String customerId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides?customerId=$customerId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
        if (data is Map && data.containsKey('rides')) {
          return data['rides'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  /// Get the current customer's active ride (Pending/Accepted/Ongoing) — for state recovery on app restart
  static Future<Map<String, dynamic>?> getActiveRide() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/active'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['active'] == true) {
          return data['ride'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  static Future<Map<String, dynamic>> updateRideStatus(
    String rideId,
    String status, {
    String? reason,
  }) async {
    try {
      final body = {'status': status};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/rides/$rideId/status'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout while updating status.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> cancelRide(String rideId) async {
    return await updateRideStatus(rideId, 'Cancelled', reason: 'User cancelled');
  }

  static Future<Map<String, dynamic>> updateRideDetails(String rideId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout while updating ride details.'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<dynamic> getMyPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/package-bookings/my'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to fetch packages'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateRideLocation(
    String rideId,
    String type,
    double lat,
    double lng,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/rides/$rideId/location'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'type': type,
          'lat': lat,
          'lng': lng,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> sendRideNotification({
    required String rideId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/notify'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'title': title,
          'body': body,
          'type': type ?? 'status_update',
          'data': data ?? {},
        }),
      );
      return _processResponse(response);
    } catch (e) {
      debugPrint("Error triggering FCM: $e");
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateRidePayment(
    String rideId, {
    required String paymentId,
    required String paymentStatus,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/rides/$rideId/payment'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'paymentId': paymentId,
          'paymentStatus': paymentStatus,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateRidePaymentMethod(
    String rideId, {
    required String paymentMethod,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/rides/$rideId/payment-method'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'paymentMethod': paymentMethod,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getMessages(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$rideId'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── Ratings ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> submitDriverRating({
    required String tripId,
    required String driverId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/driver'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'tripId': tripId,
          'driverId': driverId,
          'rating': rating,
          'comment': comment,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> skipDriverRating(String tripId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/skip/$tripId'),
        headers: await _authHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Policies & Queries ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPolicy(String type) async {
    try {
      final response = await http.get(
        // Assuming audience is "User Base" or "All"
        Uri.parse('$baseUrl/policies/filter?type=$type&audience=User Base'),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitContactQuery({
    required String name,
    required String email,
    required String message,
  }) async {
    try {
      final customerId = await getCustomerId();
      final body = {
        'name': name,
        'email': email,
        'userType': 'User',
        'message': message,
      };
      if (customerId != null) {
        body['userId'] = customerId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/queries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getPackages({String? type}) async {
    try {
      final queryParams = type != null ? '?type=$type' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/packages$queryParams'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> buyPackage({
    required String packageId,
    required String packageName,
    required String packageType,
    required String duration,
    required double amount,
    String? paymentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/package/buy'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'packageId': packageId,
          'packageName': packageName,
          'packageType': packageType,
          'duration': duration,
          'amount': amount,
          'paymentId': paymentId,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get currently active package for the user
  static Future<Map<String, dynamic>> getActivePackage() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/package'),
        headers: await _authHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Calculate fare based on package benefits
  static Future<Map<String, dynamic>> calculateRideFare({
    required String carType,
    String? packageDuration,
    String? tripType,
    double? distance,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ride/calculate'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'carType': carType,
          'packageDuration': packageDuration,
          'tripType': tripType,
          'distance': distance,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Book a ride using the new package-validated endpoint
  static Future<Map<String, dynamic>> bookRide({
    required String pickupLocation,
    required String dropoffLocation,
    required double fare,
    required double distance,
    String? carType,
    String? carModel,
    String? package,
    String? tripType,
    String? transmission,
    String? travelPlanDetails,
    bool requireCarWash = false,
    double carWashPrice = 0,
    Map<String, double>? pickupCoords,
    Map<String, double>? dropoffCoords,
    bool isScheduled = false,
    String? scheduledAt,
    double? hourlyRate,
    double? extraTimeUsed,
    double? packageHours,
    double? estimatedTime,
    double? distanceCost,
    double? hourlyCost,
    double? subtotal,
    double? platformCharge,
    double? gst,
    bool isOutstation = false,
  }) async {
    try {
      final customerId = await getCustomerId();
      if (customerId == null) return {'error': 'User not logged in'};

      final response = await http.post(
        Uri.parse('$baseUrl/ride/book'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'customerId': customerId,
          'pickupLocation': pickupLocation,
          'dropoffLocation': dropoffLocation,
          'pickupCoords': pickupCoords,
          'dropoffCoords': dropoffCoords,
          'fare': fare,
          'distance': distance,
          'carType': carType,
          'carModel': carModel,
          'carPackage': package,
          'tripType': tripType,
          'transmission': transmission,
          'travelPlanDetails': travelPlanDetails,
          'requireCarWash': requireCarWash,
          'carWashPrice': carWashPrice,
          'isScheduled': isScheduled,
          'scheduledAt': scheduledAt,
          'hourlyRate': hourlyRate,
          'extraTimeUsed': extraTimeUsed,
          'packageHours': packageHours,
          'estimatedTime': estimatedTime,
          'distanceCost': distanceCost,
          'hourlyCost': hourlyCost,
          'subtotal': subtotal,
          'platformCharge': platformCharge,
          'gst': gst,
          'isOutstation': isOutstation,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Car Clinic ──────────────────────────────────────────────────────────
  static Future<List<dynamic>> getClinicServices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/car-clinic/services'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching clinic services: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> bookClinicService({
    required String serviceId,
    required String pickupLocation,
    required Map<String, double> pickupCoords,
    required String scheduledAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/car-clinic/bookings'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'serviceId': serviceId,
          'pickupLocation': pickupLocation,
          'pickupCoords': pickupCoords,
          'scheduledAt': scheduledAt,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<List<dynamic>> getMyClinicBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/car-clinic/bookings/my'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching clinic bookings: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelClinicBooking(String bookingId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/car-clinic/bookings/$bookingId/cancel'),
        headers: await _authHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Payments (Razorpay) ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getRazorpayKey() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment/key'),
        headers: await _authHeaders(),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required double amount,
    String? receipt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/order'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'amount': amount,
          'receipt': receipt,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment/verify'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Disputes ──────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getDisputeTypes() async {
    final url = '$baseUrl/disputes/types';
    debugPrint("DEBUG DISPUTE RIDER: Fetching from $url");
    try {
      final headers = await _authHeaders();
      debugPrint("DEBUG DISPUTE RIDER: Headers: $headers");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      debugPrint("DEBUG DISPUTE RIDER: Status Code: ${response.statusCode}");
      debugPrint("DEBUG DISPUTE RIDER: Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("DEBUG DISPUTE RIDER: Parsed Data: $data");
        if (data is List) {
          debugPrint("DEBUG DISPUTE RIDER: Successfully found ${data.length} types");
          return data;
        } else {
          debugPrint("DEBUG DISPUTE RIDER: Data is NOT a List! It is ${data.runtimeType}");
        }
      }
      return [];
    } catch (e) {
      debugPrint("DEBUG DISPUTE RIDER: EXCEPTION: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitDispute({
    required String rideId,
    required String raisedBy,
    required String issueType,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/disputes'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'rideId': rideId,
          'raisedBy': raisedBy,
          'issueType': issueType,
          'description': description,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}

