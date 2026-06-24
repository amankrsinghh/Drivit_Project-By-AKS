import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'package:rider/app/modules/finding_drivers/controllers/finding_driver_controller.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final unreadCount = 0.obs;
  final notifications = <Map<String, dynamic>>[].obs;
  final deletedNotificationIds = <String>[].obs;
  static const String _storageKey = 'rider_notifications';
  static const String _tombstoneKey = 'rider_deleted_notification_ids';

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  Future<void> initialize() async {
    try {
      // 1. Request Permission
      try {
        await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint("FCM: ⚠️ Permission request failed: $e");
      }

      // 2. Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // ✅ NEW: Disable FCM heads-up in foreground to prevent duplicate banners
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

      // 3. Setup Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(),
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
          try {
            if (response.payload != null && response.payload!.isNotEmpty) {
              final data = jsonDecode(response.payload!);
              if (data['type'] == 'chat_message') {
                final rideId = data['rideId'];
                if (rideId != null) {
                  Get.toNamed('/chat', arguments: {
                    'rideId': rideId,
                    'name': data['senderName'],
                    'image': data['senderImage'],
                    'otherId': data['senderId'],
                  });
                }
              }
            }
          } catch (e) {
            debugPrint("Error handling notification tap: $e");
          }
        },
      );

      // 4. Create Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Foreground Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint("🔔 🟢 FCM Foreground Message Received!");
        
        // ✅ NEW: Verify recipient to prevent cross-account leakage
        final prefs = await SharedPreferences.getInstance();
        final currentId = prefs.getString('customer_id');
        final targetId = message.data['targetUserId'];
        
        if (currentId != null && targetId != null && currentId != targetId) {
          debugPrint("🔔 🛑 RECIPIENT MISMATCH: Current User ($currentId) != Target ($targetId). Ignoring.");
          return;
        }

        debugPrint("🔔 Title: ${message.notification?.title}");
        debugPrint("🔔 Body: ${message.notification?.body}");
        debugPrint("🔔 Data: ${message.data}");
        
        // Force Logout if account is deleted
        if (message.data['action'] == 'account_deleted') {
          debugPrint("🔔 ACCOUNT DELETED SIGNAL RECEIVED! Force logout triggered.");
          await ApiService.logout();
          Get.offAllNamed('/login'); 
          return; 
        }

        // ✅ NEW: Handle Ride Acceptance & OTP Delivery via FCM
        if (message.data['type'] == 'ride_accepted') {
            final otpValue = message.data['otp']?.toString();
            final rideId = message.data['rideId']?.toString();
            debugPrint("🔔 [FCM OTP] Received OTP: $otpValue for Ride: $rideId");

            if (Get.isRegistered<FindingDriverController>()) {
                final controller = Get.find<FindingDriverController>();
                if (otpValue != null) controller.otp.value = otpValue;
                if (rideId != null) {
                    // Force a full state refresh to sync driver details
                    controller.fetchRideDetails(rideId);
                }
            }
        }

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        debugPrint("🔔 Notification exists: ${notification != null}");
        debugPrint("🔔 Is Web: $kIsWeb");

        if (notification != null && !kIsWeb) {
          debugPrint("🔔 Adding to local list...");
          bool added = addNotification(
            title: notification.title ?? '',
            body: notification.body ?? '',
            id: message.messageId,
            payload: message.data,
          );
          debugPrint("🔔 Notification added to state: $added");

          if (added) {
            try {
              debugPrint("🔔 Attempting to show status bar notification...");
              await _localNotifications.show(
                notification.hashCode,
                notification.title,
                notification.body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    channelDescription: channel.description,
                    icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                    importance: Importance.max,
                    priority: Priority.high,
                    ticker: 'ticker',
                    autoCancel: false,
                  ),
                ),
                payload: jsonEncode(message.data),
              );
              debugPrint("🔔 _localNotifications.show command SUCCESSFUL");
            } catch (e) {
              debugPrint("🔔 ❌ ERROR showing notification: $e");
            }
          } else {
            debugPrint("🔔 ⚠️ Notification skipped (duplicate or app logic)");
          }
        } else {
          debugPrint("🔔 ⚠️ Notification object is NULL or Platform is Web");
        }
      });

      // 6. App Opened from Notification (Background State)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint("App opened from notification: ${message.notification?.title}");
        if (message.data['action'] == 'account_deleted') {
          debugPrint("🔔 App opened from ACCOUNT DELETED notification.");
          await ApiService.logout();
          Get.offAllNamed('/login');
        } else if (message.data['type'] == 'chat_message') {
          final rideId = message.data['rideId'];
          if (rideId != null) {
            Get.toNamed('/chat', arguments: {
              'rideId': rideId,
              'name': message.data['senderName'],
              'image': message.data['senderImage'],
              'otherId': message.data['senderId'],
            });
          }
        }
      });

      // Handle App Opened from Terminated State
      RemoteMessage? initialMessage = await _fcm.getInitialMessage().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint("FCM: ⏱️ getInitialMessage timed out");
          return null;
        },
      );
      if (initialMessage != null) {
        debugPrint("App opened from terminated state via notification: ${initialMessage.notification?.title}");
        if (initialMessage.data['type'] == 'chat_message') {
          final rideId = initialMessage.data['rideId'];
          if (rideId != null) {
            Future.delayed(const Duration(seconds: 2), () {
              Get.toNamed('/chat', arguments: {
                'rideId': rideId,
                'name': initialMessage.data['senderName'],
                'image': initialMessage.data['senderImage'],
                'otherId': initialMessage.data['senderId'],
              });
            });
          }
        }
      }

      // 7. Get and save token
      await getTokenAndSave();

      // 8. Token Refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint("FCM: ❌ Error getting token indirectly: $e");
      return null;
    }
  }

  Future<String?> getTokenAndSave() async {
    try {
      debugPrint("FCM: 🔍 Fetching token...");
      String? token = await _fcm.getToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint("FCM: ⏱️ Token fetch timed out");
          return null;
        },
      );
      if (token != null) {
        debugPrint("FCM: ✅ Token obtained: ${token.substring(0, 10)}...");
        await _saveTokenToBackend(token);
      } else {
        debugPrint("FCM: ⚠️ Token is null");
      }
      return token;
    } catch (e) {
      debugPrint("FCM: ❌ Error getting token: $e");
      return null;
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final authToken = await ApiService.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint("FCM: ⚠️ No auth token available. Skipping FCM token upload to backend.");
        return;
      }
      debugPrint("FCM: 📤 Sending token to backend...");
      bool success = await ApiService.updateFcmToken(token);
      if (success) {
        debugPrint("FCM: ✅ Token saved to backend successfully");
      } else {
        debugPrint("FCM: ❌ Failed to save token to backend (HTTP Error)");
      }
    } catch (e) {
      debugPrint("FCM: ❌ Error saving token: $e");
    }
  }
  
  Future<void> showLocalNotification({required String title, required String body, String? payload}) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
  
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load active notifications
      final String? stored = prefs.getString(_storageKey);
      if (stored != null) {
        final List<dynamic> decoded = jsonDecode(stored);
        notifications.assignAll(decoded.map((e) => Map<String, dynamic>.from(e)).toList());
        _updateUnreadCount();
      }

      // Load deleted IDs (tombstones)
      final List<String> deletedIds = prefs.getStringList(_tombstoneKey) ?? [];
      deletedNotificationIds.assignAll(deletedIds);
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => n['isSeen'] != true).length;
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save active notifications
      final String encoded = jsonEncode(notifications.toList());
      await prefs.setString(_storageKey, encoded);
      
      // Save unread count (optional but kept for compatibility)
      await prefs.setInt('${_storageKey}_count', unreadCount.value);

      // Save deleted IDs (limit to 100)
      if (deletedNotificationIds.length > 100) {
        deletedNotificationIds.assignAll(deletedNotificationIds.take(100).toList());
      }
      await prefs.setStringList(_tombstoneKey, deletedNotificationIds);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  bool addNotification({required String title, required String body, String? id, Map<String, dynamic>? payload}) {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) {
      return false;
    }
    if ((cleanTitle == 'Notification' || cleanTitle == 'New Message') && cleanBody.isEmpty) {
      return false;
    }
    
    final finalId = id ?? "${title}_${body}".hashCode.toString();

    // 1. Skip if ID is in deleted tombstones
    if (deletedNotificationIds.contains(finalId)) {
      debugPrint("AddNotification (Rider): Skipping deleted notification $finalId");
      return false;
    }

    // 2. Skip if already exists in active list
    if (notifications.any((n) => n['id'] == finalId)) {
      debugPrint("AddNotification (Rider): Skipping duplicate notification $finalId");
      return false;
    }

    notifications.insert(0, {
      'id': finalId,
      'title': title,
      'body': body,
      'time': DateTime.now().toIso8601String(),
      'isSeen': false,
      'payload': payload,
    });
    
    if (notifications.length > 50) notifications.removeLast();
    _updateUnreadCount();
    _saveToStorage();
    notifications.refresh();
    return true;
  }

  void markAllAsRead() {
    for (var n in notifications) {
      n['isSeen'] = true;
    }
    unreadCount.value = 0;
    _saveToStorage();
    notifications.refresh();
  }

  void clearAll() {
    // Add all current IDs to tombstone before clearing
    for (var n in notifications) {
      final id = n['id']?.toString() ?? '';
      if (id.isNotEmpty && !deletedNotificationIds.contains(id)) {
        deletedNotificationIds.add(id);
      }
    }

    notifications.clear();
    unreadCount.value = 0;
    _saveToStorage();
    notifications.refresh();

    // Clear system tray
    _localNotifications.cancelAll();
  }

  void removeNotification(int index) {
    if (index >= 0 && index < notifications.length) {
      final id = notifications[index]['id']?.toString() ?? '';
      if (id.isNotEmpty && !deletedNotificationIds.contains(id)) {
        deletedNotificationIds.add(id);
      }
      notifications.removeAt(index);
      _updateUnreadCount();
      _saveToStorage();
      notifications.refresh();

      // Clear system tray if no more notifications
      if (notifications.isEmpty) {
        _localNotifications.cancelAll();
      }
    }
  }

  /// Clears all notifications and tombstones from memory and storage.
  /// Called on logout.
  Future<void> reset() async {
    notifications.clear();
    deletedNotificationIds.clear();
    unreadCount.value = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_tombstoneKey);
    await prefs.remove('${_storageKey}_count');
    
    _localNotifications.cancelAll();
    notifications.refresh();
  }
}
