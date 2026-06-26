import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../driver_app/home/controllers/driver_home_controller.dart';
import '../driver_app/trip/controllers/driver_trip_controller.dart';
import '../driver_app/auth/controllers/driver_otp_controller.dart';
import '../driver_app/routes/driver_routes.dart';
import 'api_service.dart';
import 'socket_service.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  try {
    final data = Map<String, dynamic>.from(message.data);
    data['messageId'] = message.messageId;
    if (message.notification != null) {
      data['title'] = message.notification!.title;
      data['body'] = message.notification!.body;
    }

    final type = data['type']?.toString();
    if (type == 'ride_cancelled' || type == 'ride_accepted') {
      debugPrint("Background FCM: Skipping storing cancellation/acceptance notification ($type).");
      final rideId = data['rideId']?.toString();
      if (rideId != null && rideId.isNotEmpty) {
        try {
          final localNotifs = FlutterLocalNotificationsPlugin();
          localNotifs.cancel(rideId.hashCode);
          debugPrint("Background FCM: Dismissed/Cancelled status bar notification for rideId $rideId (ID: ${rideId.hashCode})");
        } catch (err) {
          debugPrint("Background FCM: Error cancelling status bar notification: $err");
        }
      }
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('stored_notifications') ?? [];
    
    final rawTitle = data['title']?.toString();
    final rawBody = data['body']?.toString();
    String title = (rawTitle == 'null' ? null : rawTitle) ?? (data['type'] == 'new_ride' ? 'New Ride Request' : 'Notification');
    String body = (rawBody == 'null' ? null : rawBody) ?? '';
    
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) {
      debugPrint("Background FCM: Ignoring empty notification.");
      return;
    }
    if ((cleanTitle == 'Notification' || cleanTitle == 'New Message') && cleanBody.isEmpty) {
      debugPrint("Background FCM: Ignoring generic notification with empty body.");
      return;
    }
    
    String? rideId = data['rideId']?.toString();
    String id = (data['_id'] ?? data['id'] ?? data['messageId'] ?? '').toString();
    if (title == 'New Ride Request' && rideId != null && rideId.isNotEmpty) {
      id = 'request_$rideId';
    }
    if (id.isEmpty) {
      id = "${title}_$body".hashCode.toString();
    }

    final parsed = <Map<String, dynamic>>[];
    for (final item in list) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) {
          parsed.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    if (!parsed.any((element) => element['id'] == id)) {
      parsed.insert(0, {
        'id': id,
        'title': title,
        'body': body,
        'time': DateTime.now().toString(),
        'payload': data,
      });
      final newList = parsed.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('stored_notifications', newList);
      
      final unread = prefs.getInt('unread_notifications_count') ?? 0;
      await prefs.setInt('unread_notifications_count', unread + 1);
      debugPrint("Background FCM: Saved notification directly to SharedPreferences: $id");
    }
  } catch (e) {
    debugPrint("Background FCM: Error saving notification directly to SharedPreferences: $e");
  }
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static final Map<String, DateTime> _processedFcmKeys = {};

  // Queued ride request ID from notifications tapped while app was terminated or loading
  String? pendingRideId;

  Future<void> initialize() async {
    // 1. Request Permission (iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ NEW: Disable FCM heads-up in foreground to prevent duplicate banners
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    // 3. Setup Local Notifications (Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap or action button clicks
        debugPrint('Notification tapped: ${response.payload}, ActionId: ${response.actionId}');
        try {
          if (response.payload != null && response.payload!.isNotEmpty) {
            final data = jsonDecode(response.payload!);
            
            // ✅ Ensure the tapped notification is saved to list
            _addNotificationToController(data);

            final rideId = (data['rideId'] ?? data['trip_id'])?.toString();

            if (response.actionId == 'accept_ride') {
              if (rideId != null && rideId.isNotEmpty) {
                _acceptRideFromNotification(rideId, data);
              }
            } else if (response.actionId == 'reject_ride') {
              if (rideId != null && rideId.isNotEmpty) {
                _rejectRideFromNotification(rideId);
              }
            } else {
              // Standard body tap
              if (data['type'] == 'chat_message') {
                final chatRideId = data['rideId'];
                if (chatRideId != null) {
                  Get.toNamed('/chat', arguments: {
                    'rideId': chatRideId,
                    'name': data['senderName'],
                    'profileImage': data['senderImage'],
                    'otherId': data['senderId'],
                  });
                }
              } else if (data['type'] == 'new_ride' || data['type'] == 'ride_cancelled' || data['type'] == 'ride_accepted') {
                if (rideId != null && rideId.isNotEmpty) {
                  if (Get.isRegistered<DriverHomeController>()) {
                    _handleNewRideTap(rideId);
                  } else {
                    pendingRideId = rideId;
                    debugPrint("[SOCKET DEBUG] LocalNotif click: Queued pendingRideId: $pendingRideId");
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint("Error parsing notification payload: $e");
        }
      },
    );

      // 4. Create Notification Channel (Android 8.0+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max, // Increased importance
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Listen for messages in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint("🔔 🟢 [DRIVER] FCM Foreground Message! type=${message.data['type']}");
        
        final type = message.data['type']?.toString();
        if (type == 'ride_cancelled' || type == 'ride_accepted') {
          debugPrint("🔔 [DRIVER] Skipping foreground FCM notification storage/banner for $type");
          final rideId = message.data['rideId']?.toString();
          if (rideId != null && rideId.isNotEmpty) {
            _localNotifications.cancel(rideId.hashCode);
            if (Get.isRegistered<SocketService>()) {
              Get.find<SocketService>().cancelRideRequest(rideId);
            }
          }
          return;
        }

        // Deduplicate by rideId + type, or notification ID, or messageId
        final rideId = message.data['rideId'];
        final notificationId = message.data['id'] ?? message.data['_id'];
        final messageId = message.messageId;
        
        String? dedupKey;
        if (rideId != null && type != null) {
          dedupKey = "${rideId}_$type";
        } else if (notificationId != null) {
          dedupKey = "notif_$notificationId";
        } else if (messageId != null) {
          dedupKey = "msg_$messageId";
        }

        if (dedupKey != null) {
          final now = DateTime.now();
          if (_processedFcmKeys.containsKey(dedupKey)) {
             if (now.difference(_processedFcmKeys[dedupKey]!).inSeconds < 15) {
                debugPrint("🔔 [DRIVER] Duplicate FCM ignored: $dedupKey");
                return;
             }
          }
          _processedFcmKeys[dedupKey] = now;
        }
        
        // ✅ NEW: Verify recipient to prevent cross-account leakage
        final prefs = await SharedPreferences.getInstance();
        final currentId = prefs.getString('driver_id');
        final targetId = message.data['targetUserId'];
        
        // OTP notifications are allowed for everyone (pre-login)
        bool isOtp = message.data['type'] == 'otp';
        
        if (!isOtp && currentId != null && targetId != null && currentId != targetId) {
          debugPrint("🔔 🛑 [DRIVER] RECIPIENT MISMATCH: Current Driver ($currentId) != Target ($targetId). Ignoring.");
          return;
        }

        debugPrint("🔔 Data: ${message.data}");

        // Force Logout if account is deleted
        if (message.data['action'] == 'account_deleted') {
          debugPrint("🔔 [DRIVER] ACCOUNT DELETED SIGNAL RECEIVED! Force logout triggered.");
          await ApiService.logout();
          Get.offAllNamed('/driver/login');
          Get.snackbar(
            "Account Deleted", 
            "Your account has been deleted by the admin.",
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            snackPosition: SnackPosition.TOP,
          );
          return; // Skip standard processing
        }
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // ✅ OTP NOTIFICATION — Show immediately, no controller needed
        // This fires at login/registration before DriverHomeController exists
        if (message.data['type'] == 'otp') {
          debugPrint("🔔 [DRIVER] OTP notification received! Showing immediately.");
          try {
            final otpCode = message.data['code'] ?? '';
            final notifTitle = notification?.title ?? 'Your Verification Code';
            final notifBody = notification?.body ?? (otpCode.isNotEmpty ? 'Your OTP is: $otpCode' : 'Check your OTP');
            await _localNotifications.show(
              9999, // Fixed ID for OTP notifications
              notifTitle,
              notifBody,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/launcher_icon',
                  playSound: true,
                  enableVibration: true,
                  ticker: 'OTP',
                ),
              ),
              payload: 'otp:$otpCode',
            );
            debugPrint("🔔 [DRIVER] OTP local notification shown successfully.");

            // Auto-fill OTP on the OTP screen if it's open
            if (otpCode.isNotEmpty && Get.isRegistered<DriverOtpController>()) {
              Get.find<DriverOtpController>().onOtpReceived(otpCode);
            }
          } catch (e) {
            debugPrint("🔔 [DRIVER] ❌ OTP notification show error: $e");
          }
          return; // Don't process further
        }

        // ✅ STORE IN HOME CONTROLLER NOTIFICATIONS LIST
        try {
          if (Get.isRegistered<DriverHomeController>()) {
            Get.find<DriverHomeController>().addNotification({
              'id': message.messageId ?? (message.data['rideId'] != null ? '${message.data['rideId']}_${message.data['type']}' : DateTime.now().millisecondsSinceEpoch.toString()),
              'title': notification?.title ?? (message.data['title'] == 'null' ? null : message.data['title']) ?? (message.data['type'] == 'new_ride' ? 'New Ride Request' : 'New Message'),
              'body': notification?.body ?? (message.data['body'] == 'null' ? null : message.data['body']) ?? '',
              'type': message.data['type'],
              'data': message.data,
            });

            // Auto-update payment state in TripEarning screen
            if (message.data['type'] == 'payment_received' || 
                (notification?.title ?? '').toLowerCase().contains('payment received')) {
               if (Get.isRegistered<DriverTripController>()) {
                 Get.find<DriverTripController>().confirmPayment();
               }
               if (Get.isRegistered<DriverHomeController>()) {
                 Get.find<DriverHomeController>().fetchStats();
               }
            }
          }
        } catch (e) {
          debugPrint("Error updating home controller notification list: $e");
        }

        // ✅ NEW RIDE REQUEST — Always handle regardless of HomeController state
        // Both normal rides (status=Pending) and scheduled rides arrive as type='new_ride'
        if (message.data['type'] == 'new_ride') {
          final rideId = message.data['rideId']?.toString();
          debugPrint("🔔 [DRIVER] New ride FCM received! rideId=$rideId");
          if (rideId != null && rideId.isNotEmpty && Get.isRegistered<SocketService>()) {
            final socketSvc = Get.find<SocketService>();
            // Fetch the full ride data from backend, then show dialog
            ApiService.getRide(rideId).then((rideRes) async {
              if (!rideRes.containsKey('error')) {
                final rideData = rideRes['data'] ?? rideRes;
                final status = (rideData['status'] ?? '').toString().toLowerCase();
                
                // Verify transmission type
                final profile = await ApiService.getCachedDriverProfile();
                final driverTransmission = (profile?['transmissionType'] ?? 'Both').toString().toLowerCase();
                final rideTransmission = (rideData['transmission'] ?? 'manual').toString().toLowerCase();
                
                bool isAllowed = driverTransmission == 'both' || driverTransmission == rideTransmission;
                
                // Show dialog for pending, upcoming, or scheduled rides
                if (isAllowed && (status == 'pending' || status == 'upcoming' || 
                    rideData['isScheduled'] == true || rideData['isScheduled'] == 'true')) {
                  debugPrint("🔔 [DRIVER] Showing ride request dialog for $rideId (status=$status)");
                  socketSvc.showRideRequestDialog(rideData);
                } else {
                  debugPrint("🔔 [DRIVER] Ride $rideId status '$status' or transmission '$rideTransmission' vs '$driverTransmission' not eligible for dialog.");
                }
              } else {
                debugPrint("🔔 [DRIVER] Failed to fetch ride $rideId: $rideRes");
              }
            }).catchError((e) {
              debugPrint("🔔 [DRIVER] Error fetching ride for dialog: $e");
            });
          }
        }

        // ✅ RIDE CANCELLED/ACCEPTED BY OTHER — Automatically close request popup
        if (message.data['type'] == 'ride_cancelled' || message.data['type'] == 'ride_accepted') {
          final rideId = message.data['rideId']?.toString();
          debugPrint("🔔 [DRIVER] Ride cancelled/accepted FCM received! rideId=$rideId");
          if (rideId != null && rideId.isNotEmpty && Get.isRegistered<SocketService>()) {
            Get.find<SocketService>().cancelRideRequest(rideId);
          }
          if (rideId != null && rideId.isNotEmpty && Get.isRegistered<DriverHomeController>()) {
            final hc = Get.find<DriverHomeController>();
            if (hc.activeTrip.value != null && hc.activeTrip.value!['_id']?.toString() == rideId) {
              hc.activeTrip.value = null;
            }
          }
        }

        if (notification != null && !kIsWeb) {
          try {
            debugPrint("🔔 Attempting to show status bar notification...");
            final rideId = message.data['rideId']?.toString();
            final notifId = (rideId != null && rideId.isNotEmpty) ? rideId.hashCode : notification.hashCode;
            await _localNotifications.show(
              notifId,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: android?.smallIcon ?? '@mipmap/launcher_icon',
                  importance: Importance.max,
                  priority: Priority.high,
                  ticker: 'ticker',
                  playSound: true,
                  enableVibration: true,
                  autoCancel: false,
                ),
              ),
              payload: jsonEncode(message.data),
            );
            debugPrint("🔔 _localNotifications.show SUCCESS");
          } catch (e) {
            debugPrint("🔔 ❌ ERROR showing notification: $e");
          }
        } else {
           debugPrint("🔔 ⚠️ Notification object is NULL or Platform is Web");
        }
      });

    // 6. Handle app launch from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint("App opened from notification: ${message.notification?.title}");
      
      final payload = Map<String, dynamic>.from(message.data);
      payload['messageId'] = message.messageId;
      if (message.notification != null) {
        payload['title'] = message.notification!.title;
        payload['body'] = message.notification!.body;
      }
      _addNotificationToController(payload);

      if (message.data['action'] == 'account_deleted') {
        debugPrint("🔔 [DRIVER] App opened from ACCOUNT DELETED notification.");
        await ApiService.logout();
        Get.offAllNamed('/driver/login');
      } else if (message.data['type'] == 'chat_message') {
        final rideId = message.data['rideId'];
        if (rideId != null) {
          Get.toNamed('/chat', arguments: {
            'rideId': rideId,
            'name': message.data['senderName'],
            'profileImage': message.data['senderImage'],
            'otherId': message.data['senderId'],
          });
        }
      } else if (message.data['type'] == 'new_ride' || message.data['type'] == 'ride_cancelled' || message.data['type'] == 'ride_accepted') {
        final rideId = (message.data['rideId'] ?? message.data['trip_id'])?.toString();
        if (rideId != null && rideId.isNotEmpty) {
          if (Get.isRegistered<DriverHomeController>()) {
            _handleNewRideTap(rideId);
          } else {
            pendingRideId = rideId;
            debugPrint("[SOCKET DEBUG] FCM onMessageOpenedApp: Queued pendingRideId: $pendingRideId");
          }
        }
      }
    });

    // Handle App Opened from Terminated State
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("App opened from terminated state via notification: ${initialMessage.notification?.title}");
      
      final payload = Map<String, dynamic>.from(initialMessage.data);
      payload['messageId'] = initialMessage.messageId;
      if (initialMessage.notification != null) {
        payload['title'] = initialMessage.notification!.title;
        payload['body'] = initialMessage.notification!.body;
      }
      _addNotificationToController(payload);

      if (initialMessage.data['type'] == 'chat_message') {
        final rideId = initialMessage.data['rideId'];
        if (rideId != null) {
          Future.delayed(const Duration(seconds: 2), () {
            Get.toNamed('/chat', arguments: {
              'rideId': rideId,
              'name': initialMessage.data['senderName'],
              'profileImage': initialMessage.data['senderImage'],
              'otherId': initialMessage.data['senderId'],
            });
          });
        }
      } else if (initialMessage.data['type'] == 'new_ride' || initialMessage.data['type'] == 'ride_cancelled' || initialMessage.data['type'] == 'ride_accepted') {
        final rideId = (initialMessage.data['rideId'] ?? initialMessage.data['trip_id'])?.toString();
        if (rideId != null && rideId.isNotEmpty) {
          pendingRideId = rideId;
          debugPrint("[SOCKET DEBUG] FCM getInitialMessage: Queued pendingRideId from terminated state: $pendingRideId");
        }
      }
    }

    // 7. Get and save token
    await getTokenAndSave();

    // 8. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      _saveTokenToBackend(newToken);
    });
  }

  void _addNotificationToController(Map<String, dynamic> data) {
    try {
      String? type;
      if (data['type'] != null) {
        type = data['type'].toString();
      } else if (data['data'] != null && data['data'] is Map && data['data']['type'] != null) {
        type = data['data']['type'].toString();
      } else if (data['payload'] != null && data['payload'] is Map && data['payload']['type'] != null) {
        type = data['payload']['type'].toString();
      }

      if (type == 'ride_cancelled' || type == 'ride_accepted') {
        debugPrint("_addNotificationToController: Skipping cancellation/acceptance notification ($type).");
        return;
      }

      if (Get.isRegistered<DriverHomeController>()) {
        final hc = Get.find<DriverHomeController>();
        hc.addNotification(data);
      } else {
        _saveNotificationToPrefsDirectly(data);
      }
    } catch (e) {
      debugPrint("Error adding notification to controller: $e");
    }
  }

  Future<void> _saveNotificationToPrefsDirectly(Map<String, dynamic> data) async {
    try {
      String? type;
      if (data['type'] != null) {
        type = data['type'].toString();
      } else if (data['data'] != null && data['data'] is Map && data['data']['type'] != null) {
        type = data['data']['type'].toString();
      } else if (data['payload'] != null && data['payload'] is Map && data['payload']['type'] != null) {
        type = data['payload']['type'].toString();
      }

      if (type == 'ride_cancelled' || type == 'ride_accepted') {
        debugPrint("NotificationService: Skipping saving cancellation/acceptance notification ($type) to SharedPreferences.");
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('stored_notifications') ?? [];
      
      final rawTitle = data['title']?.toString();
      final rawBody = data['body']?.toString();
      String title = (rawTitle == 'null' ? null : rawTitle) ?? 'Notification';
      String body = (rawBody == 'null' ? null : rawBody) ?? '';
      
      final cleanTitle = title.trim();
      final cleanBody = body.trim();
      if (cleanTitle.isEmpty && cleanBody.isEmpty) {
        debugPrint("NotificationService: Ignoring empty notification.");
        return;
      }
      if ((cleanTitle == 'Notification' || cleanTitle == 'New Message') && cleanBody.isEmpty) {
        debugPrint("NotificationService: Ignoring generic notification with empty body.");
        return;
      }
      
      String? rideId;
      if (data['rideId'] != null) {
        rideId = data['rideId'].toString();
      } else if (data['data'] != null && data['data'] is Map && data['data']['rideId'] != null) {
        rideId = data['data']['rideId'].toString();
      }

      String id = (data['_id'] ?? data['id'] ?? data['messageId'] ?? '').toString();
      if (title == 'New Ride Request' && rideId != null && rideId.isNotEmpty) {
        id = 'request_$rideId';
      }
      if (id.isEmpty) {
        id = "${title}_$body".hashCode.toString();
      }

      final parsed = <Map<String, dynamic>>[];
      for (final item in list) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            parsed.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      if (parsed.any((element) => element['id'] == id)) {
        return;
      }

      parsed.insert(0, {
        'id': id,
        'title': title,
        'body': body,
        'time': DateTime.now().toString(),
        'payload': data['data'] ?? data,
      });

      final newList = parsed.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('stored_notifications', newList);
      
      final unread = prefs.getInt('unread_notifications_count') ?? 0;
      await prefs.setInt('unread_notifications_count', unread + 1);
      
      debugPrint("Saved notification directly to SharedPreferences: $id");
    } catch (e) {
      debugPrint("Error saving notification directly to SharedPreferences: $e");
    }
  }

  Future<void> showLocalNotification({required String title, required String body, String? payload}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotifications.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<String?> getFcmToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("FCM [DRIVER]: ❌ Error getting token indirectly: $e");
      return null;
    }
  }

  Future<String?> getTokenAndSave() async {
    try {
      debugPrint("FCM [DRIVER]: 🔍 Fetching token...");
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint("FCM [DRIVER]: ✅ Token: ${token.substring(0, 10)}...");
        await _saveTokenToBackend(token);
      } else {
        debugPrint("FCM [DRIVER]: ⚠️ Token is NULL");
      }
      return token;
    } catch (e) {
      debugPrint("FCM [DRIVER]: ❌ Error fetching token: $e");
      return null;
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      debugPrint("FCM [DRIVER]: 📤 Transmitting token to backend...");
      bool success = await ApiService.updateFcmToken(token);
      if (success) {
        debugPrint("FCM [DRIVER]: ✅ Token successfully synced");
      } else {
        debugPrint("FCM [DRIVER]: ❌ Sync failed (Response False)");
      }
    } catch (e) {
      debugPrint("FCM [DRIVER]: ❌ Error saving token: $e");
    }
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  Future<void> _handleNewRideTap(String rideId) async {
    try {
      if (!Get.isRegistered<SocketService>()) return;
      final socketSvc = Get.find<SocketService>();
      
      final rideRes = await ApiService.getRide(rideId);
      if (rideRes.containsKey('error')) {
        debugPrint("🔔 [DRIVER] Tap: Failed to fetch ride $rideId: $rideRes");
        return;
      }
      
      final rideData = rideRes['data'] ?? rideRes;
      final String status = (rideData['status'] ?? '').toString().toLowerCase().trim();
      final String assignedDriverId = (rideData['driverId'] ?? '').toString().trim();
      
      final prefs = await SharedPreferences.getInstance();
      final String currentDriverId = (prefs.getString('driver_id') ?? '').trim();
      
      // Verify transmission type
      final profile = await ApiService.getCachedDriverProfile();
      final driverTransmission = (profile?['transmissionType'] ?? 'Both').toString().toLowerCase();
      final rideTransmission = (rideData['transmission'] ?? 'manual').toString().toLowerCase();
      
      bool isAllowed = driverTransmission == 'both' || driverTransmission == rideTransmission;
      if (!isAllowed) {
        debugPrint("🔔 [DRIVER] Tap: Ride $rideId transmission mismatch ($rideTransmission vs $driverTransmission)");
        return;
      }
      
      // 1. Check if the ride has already been accepted by the CURRENT driver
      if (assignedDriverId.isNotEmpty && assignedDriverId == currentDriverId) {
        if (['accepted', 'arrived'].contains(status)) {
          debugPrint("🔔 [DRIVER] Tap: Already accepted. Navigating to after-accept for $rideId");
          Get.toNamed('/driver/trip/after-accept-location', parameters: {'rideId': rideId});
        } else if (['ongoing', 'started', 'reach destination'].contains(status)) {
          debugPrint("🔔 [DRIVER] Tap: Already ongoing. Navigating to reach-destination for $rideId");
          Get.toNamed('/driver/trip/reach-destination', parameters: {'rideId': rideId});
        } else {
          debugPrint("🔔 [DRIVER] Tap: Ride is already in state '$status' by this driver.");
        }
        return;
      }
      
      // 2. Check if the ride has been accepted by a DIFFERENT driver, or is cancelled/completed
      if (status == 'accepted' || status == 'ongoing' || status == 'started' || status == 'completed') {
        Get.snackbar(
          "Request Expired",
          "This ride request has already been accepted by another driver. Opening details.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF303030),
          colorText: Colors.white,
        );
        Get.toNamed('/driver/history/trip-details', arguments: rideData);
        return;
      }
      
      if (status == 'cancelled') {
        Get.snackbar(
          "Request Cancelled",
          "This ride request was cancelled by the rider. Opening details.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF303030),
          colorText: Colors.white,
        );
        Get.toNamed('/driver/history/trip-details', arguments: rideData);
        return;
      }
      
      // 3. If it's still open to be accepted (pending/upcoming/searching)
      if (status == 'pending' || status == 'upcoming' || status == 'searching') {
        debugPrint("🔔 [DRIVER] Tap: Showing request dialog for $rideId");
        socketSvc.showRideRequestDialog(rideData, fromFcmClick: true);
      } else {
        debugPrint("🔔 [DRIVER] Tap: Ride $rideId in unhandled state '$status'. Opening details.");
        Get.toNamed('/driver/history/trip-details', arguments: rideData);
      }
    } catch (e) {
      debugPrint("🔔 [DRIVER] Error in _handleNewRideTap: $e");
    }
  }

  Future<void> _acceptRideFromNotification(String rideId, Map<String, dynamic> data) async {
    try {
      debugPrint("🔔 [NotificationService] Automatically accepting ride $rideId from notification action button");
      if (Get.isRegistered<SocketService>()) {
        final socketSvc = Get.find<SocketService>();
        socketSvc.isInActiveTrip = true;
        socketSvc.currentRideRequestId = rideId;
      }
      
      // Make sure any dialog is closed if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Fetch the latest ride details first to ensure we have the complete data
      final rideRes = await ApiService.getRide(rideId);
      final rideData = (!rideRes.containsKey('error')) ? (rideRes['data'] ?? rideRes) : data;

      final ctrl = Get.put(DriverTripController(), permanent: true);
      ctrl.loadRide(rideData);
      ctrl.acceptRide(rideId);
      Get.toNamed(DriverRoutes.afterAcceptLocation);
    } catch (e) {
      debugPrint("Error accepting ride from notification: $e");
    }
  }

  Future<void> _rejectRideFromNotification(String rideId) async {
    try {
      debugPrint("🔔 [NotificationService] Rejecting ride $rideId from notification action button");
      await ApiService.rejectRide(rideId);
      await ApiService.addCancelledRideId(rideId);
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().cancelRideRequest(rideId);
      }
    } catch (e) {
      debugPrint("Error rejecting ride from notification: $e");
    }
  }

  void processPendingRideTap(String rideId) {
    _handleNewRideTap(rideId);
  }
}
