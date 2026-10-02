// lib/services/push_notification_service.dart

import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ════════════════════════════════════════════════════════════════════════════
// ✅ CRITICAL: Background message handler (MUST be top-level function)
// ════════════════════════════════════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("📬 Background Message: ${message.notification?.title}");
  // ✅ Save to Firestore even in background
  await _saveNotificationToFirestore(message);
}

// ✅ Helper to save notification (works in background too)
Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
  try {
    final userId = message.data['toUserId']?.toString();
    if (userId == null || userId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          'title': message.notification?.title ?? 'New Notification',
          'body': message.notification?.body ?? '',
          'type': message.data['type'] ?? 'default',
          'senderId': message.data['senderId'] ?? '',
          'postId': message.data['postId'],
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'data': message.data,
        });

    log("✅ Notification saved to Firestore");
  } catch (e) {
    log("❌ Error saving notification: $e");
  }
}

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ Navigation key for routing from notifications
  static GlobalKey<NavigatorState>? navigatorKey;

  // ✅ Notification channel ID (Android)
  static const String _channelId = 'findus_notifications';
  static const String _channelName = 'FindUs Notifications';
  static const String _channelDescription = 'All notifications from FindUs app';

  // ════════════════════════════════════════════════════════════════════════════
  // 🚀 INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> init({GlobalKey<NavigatorState>? navKey}) async {
    navigatorKey = navKey;

    try {
      // ✅ 1. Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        log('⚠️ User granted provisional permission');
      } else {
        log('❌ User declined or has not accepted permission');
        return;
      }

      // ✅ 2. Create notification channel (Android 8+)
      await _createNotificationChannel();

      // ✅ 3. Initialize local notifications
      await _initializeLocalNotifications();

      // ✅ 4. Set background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // ✅ 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        log("📬 Foreground Message: ${message.notification?.title}");
        _showNotification(message);
        _saveNotificationToFirestore(message); // ✅ Save to Firestore
      });

      // ✅ 6. Handle notification taps (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        log("👆 Notification tapped (background): ${message.data}");
        _handleNotificationClick(message);
      });

      // ✅ 8. Get and save FCM token
      await _saveFCMToken();

      // ✅ 9. Listen for token refresh
      _fcm.onTokenRefresh.listen(_updateFCMToken);

      log("✅ Push Notification Service initialized successfully");
    } catch (e) {
      log("❌ Notification init error: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔔 NOTIFICATION CHANNEL (Android)
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF38B6FF),
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    log("✅ Notification channel created: $_channelId");
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔧 LOCAL NOTIFICATIONS SETUP
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log("👆 Local notification tapped: ${response.payload}");
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handlePayload(response.payload!);
        }
      },
    );

    log("✅ Local notifications initialized");
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📨 SHOW NOTIFICATION
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> _showNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New Notification';
    final body = message.notification?.body ?? '';
    final type = message.data['type']?.toString() ?? 'default';

    // ✅ Build notification payload for navigation
    final payload = _buildPayload(message.data);

    // ✅ Android-specific details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          color: const Color(0xFF38B6FF),
          ticker: title,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'FindUs',
          ),
        );

    // ✅ iOS-specific details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    log("✅ Notification shown: $title");
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔗 HANDLE NOTIFICATION CLICKS
  // ════════════════════════════════════════════════════════════════════════════

  static void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    _navigateByData(data);
  }

  static void _handlePayload(String payload) {
    // Payload format: "type|id"
    final parts = payload.split('|');
    if (parts.isEmpty) return;

    final type = parts[0];
    final id = parts.length > 1 ? parts[1] : null;

    final data = <String, dynamic>{
      'type': type,
      if (id != null) _getIdKey(type): id,
    };

    _navigateByData(data);
  }

  static String _getIdKey(String type) {
    switch (type) {
      case 'job':
      case 'post':
        return 'postId';
      case 'profile':
      case 'follow':
        return 'userId';
      default:
        return 'id';
    }
  }

  static String _buildPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? 'default';
    final id = data['postId'] ?? data['userId'] ?? '';
    return "$type|$id";
  }

  static void _navigateByData(Map<String, dynamic> data) {
    final navigator = navigatorKey?.currentState;

    if (navigator == null) {
      log("⚠️ Navigator এখনো রেডি না — navigation হচ্ছে না");
      return;
    }

    final type = data['type']?.toString() ?? 'default';
    log("🔗 Navigating: $type → data: $data");

    switch (type) {
      case 'job':
      case 'post':
        final postId = data['postId']?.toString();
        if (postId != null && postId.isNotEmpty) {
          navigator.pushNamed('/job-details', arguments: postId);
        } else {
          navigator.pushNamed('/notifications');
        }
        break;

      case 'profile':
      case 'follow':
        final userId = data['userId'] ?? data['senderId']?.toString();
        if (userId != null && userId.isNotEmpty) {
          navigator.pushNamed('/profile', arguments: userId);
        } else {
          navigator.pushNamed('/notifications');
        }
        break;

      default:
        navigator.pushNamed('/notifications');
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔑 FCM TOKEN MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> _saveFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        log("✅ FCM Token: $token");
        await _updateFCMToken(token);
      } else {
        log("⚠️ FCM token is null");
      }
    } catch (e) {
      log("❌ Error getting FCM token: $e");
    }
  }

  static Future<void> _updateFCMToken(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        log("⚠️ No user logged in, cannot save FCM token");
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': Theme.of(navigatorKey!.currentContext!).platform.toString(),
      }, SetOptions(merge: true));

      log("✅ FCM token saved to Firestore for user: $userId");
    } catch (e) {
      log("❌ Error saving FCM token: $e");
    }
  }

  /// ✅ Get current FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      log("❌ Error getting token: $e");
      return null;
    }
  }

  /// ✅ Delete FCM token (on logout)
  static Future<void> deleteFCMToken() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'fcmToken': FieldValue.delete()},
        );
      }
      await _fcm.deleteToken();
      log("✅ FCM token deleted");
    } catch (e) {
      log("❌ Error deleting token: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📢 SUBSCRIBE TO TOPICS
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      log("✅ Subscribed to topic: $topic");
    } catch (e) {
      log("❌ Error subscribing to topic: $e");
    }
  }

  /// ✅ Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      log("✅ Unsubscribed from topic: $topic");
    } catch (e) {
      log("❌ Error unsubscribing from topic: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📊 BADGE MANAGEMENT
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Set app badge count (iOS)
  static Future<void> setBadgeCount(int count) async {
    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS badge update
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(badge: true);

      log("✅ Badge count set to: $count");
    } catch (e) {
      log("❌ Error setting badge: $e");
    }
  }

  /// ✅ Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      log("✅ All notifications cleared");
    } catch (e) {
      log("❌ Error clearing notifications: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🧪 TESTING
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Show test notification
  static Future<void> showTestNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification from FindUs',
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformDetails,
      payload: 'test|',
    );

    log("✅ Test notification shown");
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔒 PERMISSION CHECK
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Check if notification permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      log("❌ Error checking permission: $e");
      return false;
    }
  }

  /// ✅ Request permission again
  static Future<bool> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      log("❌ Error requesting permission: $e");
      return false;
    }
  }
}
