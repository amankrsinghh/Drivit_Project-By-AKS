import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'socket_service.dart';
import '../driver_app/home/controllers/driver_home_controller.dart';

class ApiService {
  // Live Railway URL for both Android and iOS
  static String get baseUrl {
    return 'https://driveit-app-backend-production.up.railway.app/api';
  }

  static String? googleMapsApiKey;
  static Map<String, dynamic>? cachedProfile;
  static bool enableGeofenceBoundary = false;
  static int freeRidesCount = 3;


  static Future<Map<String, dynamic>> getPublicSettings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/settings/public'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final Map<String, dynamic> settings = {};
        for (var item in data) {
          if (item is Map && item.containsKey('key') && item.containsKey('value')) {
            settings[item['key'].toString()] = item['value'];
          }
        }
        return settings;
      }
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return '${baseUrl.replaceAll('/api', '')}${path.startsWith('/') ? '' : '/'}$path';
  }

  // ─────────────── Token Management ───────────────

  static Future<void> saveToken(String token, String driverId) async {
    // ✅ NEW: Ensure no old data from previous session survives
    await logout();
    
    final prefs = await SharedPreferences.getInstance();
    
    // Ensure notifications are cleared (though logout() already clears everything)
    if (Get.isRegistered<DriverHomeController>()) {
      final home = Get.find<DriverHomeController>();
      home.notifications.clear();
      home.unreadNotificationsCount.value = 0;
      home.deletedNotificationIds.clear();
    }
    
    await prefs.setString('jwt_token', token);
    await prefs.setString('driver_id', driverId);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('driver_id');
  }

  static Future<void> saveDriverProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_driver_profile', jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> getCachedDriverProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_driver_profile');
    if (cached != null) {
      try {
        return jsonDecode(cached) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<void> logout() async {
    // 1. Clear In-Memory Cache
    cachedProfile = null;

    final prefs = await SharedPreferences.getInstance();

    // 2. Tell backend to remove FCM token association
    try {
      final token = prefs.getString('jwt_token');
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
      debugPrint("Driver App: Logout signal to backend failed: $e");
    }
    
    // 3. WIPE ALL LOCAL STORAGE
    await prefs.clear();

    // 4. FORCE DELETE all permanent controllers to clear session state from memory
    try {
      if (Get.isRegistered<DriverHomeController>()) {
        final home = Get.find<DriverHomeController>();
        home.notifications.clear();
        home.unreadNotificationsCount.value = 0;
        home.deletedNotificationIds.clear();
        Get.delete<DriverHomeController>(force: true);
      }
      _delete<NotificationService>();
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

  static Future<void> saveOnlineStatus(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_online', isOnline);
  }

  static Future<bool> getOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_online') ?? false;
  }

  /// Track cancelled ride IDs so we don't re-show them on socket reconnect
  static Future<void> addCancelledRideId(String rideId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('cancelled_ride_ids') ?? [];
    if (!ids.contains(rideId)) {
      ids.add(rideId);
      // Keep only last 50 to avoid unbounded growth
      if (ids.length > 50) ids.removeAt(0);
      await prefs.setStringList('cancelled_ride_ids', ids);
    }
  }

  static Future<List<String>> getCancelledRideIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('cancelled_ride_ids') ?? [];
  }

  static Future<Map<String, dynamic>> toggleOnline(bool isOnline, {double? lat, double? lng}) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'isOnline': isOnline,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
      final response = await http.patch(
        Uri.parse('$baseUrl/drivers/online'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────── Response Processing ───────────────

  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body);

      // ✅ GLOBAL SECURITY CHECK: If driver is deleted or token invalid, force logout
      if (response.statusCode == 401 || response.statusCode == 404) {
        final message = (json is Map ? (json['message'] ?? json['error']) : '').toString().toLowerCase();
        if (message.contains('not authorized') || message.contains('not found') || message.contains('user not found')) {
          debugPrint("ApiService [DRIVER]: Global Auth Failure (${response.statusCode}). Triggering logout.");
          logout();
          return {'error': 'Session expired or account deleted'};
        }
      }

      if (response.statusCode >= 400) {
        final String? errMsg = json['error'] ?? json['message'];
        json['error'] = errMsg ?? 'Error ${response.statusCode}';
      }
      return json;
    } catch (e) {
      if (response.statusCode >= 500) {
        return {'error': 'Server under maintenance. Please try again later.'};
      }
      return {'error': 'Invalid server response: ${e.toString()}'};
    }
  }

  static Future<Map<String, String>> _authHeaders() async {
    String? token = await getToken();
    // Small retry delay if token is null - useful after a very fast login/redirect
    if (token == null || token.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      token = await getToken();
    }
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

  // ─────────────── Auth Endpoints ───────────────

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      // 🔔 Fetch FCM token to include in request for push notification
      String? fcmToken;
      try {
        // Use the registered singleton — NOT a bare new instance
        if (Get.isRegistered<NotificationService>()) {
          fcmToken = await NotificationService.to.getFcmToken();
        } else {
          // Fallback: get token directly from FirebaseMessaging
          final messaging = FirebaseMessaging.instance;
          fcmToken = await messaging.getToken();
        }
        debugPrint("ApiService Driver: FCM token for OTP: ${fcmToken != null ? '${fcmToken.substring(0, 10)}...' : 'NULL'}");
      } catch (e) {
        debugPrint("ApiService Driver: Could not fetch FCM token for OTP: $e");
      }

      // Build body — only include fcmToken if non-null
      final Map<String, dynamic> body = {
        'phone': phone,
        'role': 'driver',
      };
      if (fcmToken != null && fcmToken.isNotEmpty) {
        body['fcmToken'] = fcmToken;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/driver/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout. Please check your internet.'};
    } catch (e) {
      return {'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> loginDriver(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/driver/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/driver/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp, 'role': 'driver'}),
      ).timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } on TimeoutException {
      return {'error': 'Connection timeout. Please try again.'};
    } catch (e) {
      return {'error': 'Network error: ${e.toString()}'};
    }
  }

  // ─────────────── Driver Registration ───────────────

  static Future<Map<String, dynamic>> registerDriver({
    required Map<String, String> fields,
    String? aadharFrontPath,
    String? aadharBackPath,
    String? licensePath,
    String? expProofPath,
    String? policeVerificationPath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/drivers/register'),
      );
      request.fields.addAll(fields);

      if (aadharFrontPath != null && aadharFrontPath.isNotEmpty) {
        final mt = lookupMimeType(aadharFrontPath) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'aadharFrontFile',
            aadharFrontPath,
            filename: 'aadhar_front${path.extension(aadharFrontPath)}',
            contentType: MediaType.parse(mt),
          ),
        );
      }
      if (aadharBackPath != null && aadharBackPath.isNotEmpty) {
        final mt = lookupMimeType(aadharBackPath) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'aadharBackFile',
            aadharBackPath,
            filename: 'aadhar_back${path.extension(aadharBackPath)}',
            contentType: MediaType.parse(mt),
          ),
        );
      }
      if (licensePath != null && licensePath.isNotEmpty) {
        final mt = lookupMimeType(licensePath) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'licenseFile',
            licensePath,
            filename: 'license${path.extension(licensePath)}',
            contentType: MediaType.parse(mt),
          ),
        );
      }
      if (expProofPath != null && expProofPath.isNotEmpty) {
        final mt = lookupMimeType(expProofPath) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'expProofFile',
            expProofPath,
            filename: 'exp_proof${path.extension(expProofPath)}',
            contentType: MediaType.parse(mt),
          ),
        );
      }
      if (policeVerificationPath != null && policeVerificationPath.isNotEmpty) {
        final mt = lookupMimeType(policeVerificationPath) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'policeVerificationFile',
            policeVerificationPath,
            filename: 'police_verification${path.extension(policeVerificationPath)}',
            contentType: MediaType.parse(mt),
          ),
        );
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerDriverMinimal({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────── Driver Profile ───────────────

  static Future<Map<String, dynamic>?> getDriverProfile() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/profile'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateDriverProfile({
    String? name,
    String? phone,
    String? email,
    String? vehicleModel,
    String? vehicleNumber,
    String? city,
    String? address,
    String? pincode,
    String? transmissionType,
    String? profileImagePath,
  }) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/drivers/profile'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (name != null) request.fields['name'] = name;
      if (phone != null) request.fields['phone'] = phone;
      if (email != null) request.fields['email'] = email;
      if (vehicleModel != null) request.fields['vehicleModel'] = vehicleModel;
      if (vehicleNumber != null) {
        request.fields['vehicleNumber'] = vehicleNumber;
      }
      if (city != null) request.fields['city'] = city;
      if (address != null) request.fields['address'] = address;
      if (pincode != null) request.fields['pincode'] = pincode;
      if (transmissionType != null) {
        request.fields['transmissionType'] = transmissionType;
      }

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final mimeType = lookupMimeType(profileImagePath) ?? 'image/jpeg';
        final extension = path.extension(profileImagePath);
        final fileName = 'profile_image_${DateTime.now().millisecondsSinceEpoch}$extension';

        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            profileImagePath,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> rechargeWallet(double amount) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/recharge'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────── Rides ───────────────

  static Future<Map<String, dynamic>> getRide(String rideId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getDriverRides({int page = 1, int limit = 10, bool? isScheduled}) async {
    try {
      final headers = await _authHeaders();
      String url = '$baseUrl/rides/my?page=$page&limit=$limit';
      if (isScheduled != null) {
        url += '&isScheduled=$isScheduled';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/my-stats'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Inform backend of driver's rejection for suppression logic
  static Future<void> rejectRide(String rideId) async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('$baseUrl/rides/$rideId/reject'),
        headers: headers,
      );
      // We don't necessarily handle failure here (fire and forget for suppression)
      debugPrint("ApiService: Notified backend of ride rejection ($rideId)");
    } catch (e) {
      debugPrint("ApiService: Rejection notify failed: $e");
    }
  }

  /// Get the driver's active trip (Accepted/Ongoing) — for state recovery on app restart
  static Future<Map<String, dynamic>?> getActiveTrip() async {
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


  static Future<Map<String, dynamic>> saveTripCheck({
    required String rideId,
    required bool isClean,
    required bool hasDamage,
    required bool customerConfirmed,
    List<String>? damageImagePaths,
  }) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/rides/$rideId/check'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['isClean'] = isClean.toString();
      request.fields['hasDamage'] = hasDamage.toString();
      request.fields['customerConfirmed'] = customerConfirmed.toString();

      if (damageImagePaths != null && damageImagePaths.isNotEmpty) {
        for (String p in damageImagePaths) {
          if (p.isNotEmpty) {
            final mt = lookupMimeType(p) ?? 'image/jpeg';
            request.files.add(
              await http.MultipartFile.fromPath(
                'damageImage',
                p,
                filename: 'damage_${DateTime.now().millisecondsSinceEpoch}_${path.basename(p)}',
                contentType: MediaType.parse(mt),
              ),
            );
          }
        }
      }

      var streamResponse = await request.send();
      var response = await http.Response.fromStream(streamResponse);
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTripCheck(String rideId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId/check'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateRideStatus(
    String rideId,
    String status, {
    String? otp,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {'status': status};
      if (otp != null) {
        body['otp'] = otp;
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/rides/$rideId/status'),
        headers: headers,
        body: jsonEncode(body),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> confirmCashPayment(String rideId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/confirm-cash'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> raisePaymentDispute(
    String rideId, {
    required String issueType,
    required String description,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/raise-dispute'),
        headers: headers,
        body: jsonEncode({
          'issueType': issueType,
          'description': description,
        }),
      );
      return _processResponse(response);
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

  // ─────────────── Dashboard Stats ───────────────

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rides/stats'));
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

  // ─────────────── Policies & Queries ───────────────

  static Future<Map<String, dynamic>> getPolicy(String type) async {
    try {
      final response = await http.get(
        // Assuming audience is "Driver Base" or "All"
        Uri.parse('$baseUrl/policies/filter?type=$type&audience=Driver Base'),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitContactQuery({
    required String name,
    required String email,
    required String phone,
    required String message,
  }) async {
    try {
      final driverId = await getDriverId();
      final body = {
        'name': name,
        'email': email,
        'phone': phone,
        'userType': 'Driver',
        'message': message,
      };
      if (driverId != null) {
        body['userId'] = driverId;
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

  // ─────────────── Payments (Razorpay) ───────────────

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
  // ─────────────── Driver Packages ───────────────

  static Future<List<dynamic>> getDriverPackages() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/driver-packages'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> buyDriverPackage(String packageId, String paymentId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/driver-packages/buy'),
        headers: headers,
        body: jsonEncode({'packageId': packageId, 'paymentId': paymentId}),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getCurrentDriverPackage() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/driver-packages/current'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────── Disputes ───────────────

  static Future<List<dynamic>> getDisputeTypes() async {
    final url = '$baseUrl/disputes/types';
    debugPrint("DEBUG DISPUTE: Fetching from $url");
    try {
      final headers = await _authHeaders();
      debugPrint("DEBUG DISPUTE: Headers: $headers");
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      debugPrint("DEBUG DISPUTE: Status Code: ${response.statusCode}");
      debugPrint("DEBUG DISPUTE: Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("DEBUG DISPUTE: Parsed Data: $data");
        if (data is List) {
           debugPrint("DEBUG DISPUTE: Successfully found ${data.length} types");
           return data;
        } else {
           debugPrint("DEBUG DISPUTE: Data is NOT a List! It is ${data.runtimeType}");
        }
      }
      return [];
    } catch (e) {
      debugPrint("DEBUG DISPUTE: EXCEPTION: $e");
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

  static Future<Map<String, dynamic>> informAdminUnavailable(String rideId, String reason) async {
    try {
      final headers = await _authHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rides/$rideId/driver-unavailable'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─────────────── Ratings ───────────────
  static Future<Map<String, dynamic>> submitCustomerRating({
    required String tripId,
    required String customerId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ratings/customer'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'tripId': tripId,
          'customerId': customerId,
          'rating': rating,
          'comment': comment,
        }),
      );
      return _processResponse(response);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> skipCustomerRating(String tripId) async {
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
}

