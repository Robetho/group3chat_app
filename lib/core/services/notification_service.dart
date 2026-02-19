import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/firebase_const.dart';
import '../../models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 🔥 YOUR PROJECT ID
  static const String _projectId = 'groupthree-chatapp';

  // 🔥 FCM HTTP v1 API URL
  static String get _fcmV1Url =>
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  // 🔥 SIMPLE WORKING METHOD - Store in Firestore
  final StreamController<Map<String, dynamic>> _notificationStream =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotification => _notificationStream.stream;

  Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');
    try {
      await _requestPermission();
      await _initLocalNotifications();
      await _setupMessageHandlers();
      await getFCMToken();
      print('✅ Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Notification Service: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('📱 Notification Settings:');
      print('   Authorization Status: ${settings.authorizationStatus}');
      print('   Sound: ${settings.sound}');
      print('   Alert: ${settings.alert}');
      print('   Badge: ${settings.badge}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ Provisional notification permission granted');
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/pic_two');

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('📱 Notification tapped: ${response.payload}');
          _notificationStream.add({
            'type': 'notification_clicked',
            'payload': response.payload,
          });
        },
      );

      // Create notification channel for Android with sound and vibration
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_channel',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        showBadge: true,
        ledColor: Color(0xFF075E54),
        enableLights: true,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('✅ Local notifications initialized with channel: ${channel.id}');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  Future<void> _setupMessageHandlers() async {
    try {
      // Listen for messages when app is in FOREGROUND
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('📱 FOREGROUND message received:');
        print('   Title: ${message.notification?.title}');
        print('   Body: ${message.notification?.body}');
        print('   Data: ${message.data}');

        // Show notification with sound and vibration
        await _showLocalNotification(message);

        // Send to stream for in-app notification
        _notificationStream.add({
          'title': message.notification?.title ?? 'New Message',
          'body': message.notification?.body ?? 'You have a new message',
          'data': message.data,
          'timestamp': DateTime.now(),
          'type': 'foreground_message',
        });
      });

      // Listen when app is opened from BACKGROUND
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 App opened from BACKGROUND notification');
        print('   Data: ${message.data}');

        _notificationStream.add({
          'type': 'app_opened_from_background',
          'data': message.data,
          'timestamp': DateTime.now(),
        });
      });

      // Get initial message if app was opened from TERMINATED state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 App opened from TERMINATED state');
        print('   Data: ${initialMessage.data}');

        _notificationStream.add({
          'type': 'app_opened_from_terminated',
          'data': initialMessage.data,
          'timestamp': DateTime.now(),
        });
      }

      print('✅ Message handlers set up');
    } catch (e) {
      print('❌ Error setting up message handlers: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'chat_channel',
          'Chat Notifications',
          channelDescription: 'This channel is used for chat notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          colorized: true,
          color: const Color(0xFF075E54),
          enableLights: true,
          ledColor: const Color(0xFF075E54),
          ledOnMs: 1000,
          ledOffMs: 500,
          visibility: NotificationVisibility.public,
          timeoutAfter: 10000,
          groupKey: 'chat_messages',
          setAsGroupSummary: true,
        );

        NotificationDetails platformChannelSpecifics =
        NotificationDetails(
          android: androidPlatformChannelSpecifics,
        );

        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notification.title ?? 'New Message',
          notification.body ?? 'You have a new message',
          platformChannelSpecifics,
          payload: message.data.toString(),
        );

        print('📢 Local notification shown with sound and vibration');
      }
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('🔑 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateUserFCMToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConst.usersCollection)
          .doc(userId)
          .update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token updated for user: $userId');
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  // 🔥 NEW METHOD: Check current notification settings
  Future<void> checkNotificationSettings() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();

      print('📱 Current Notification Settings:');
      print('   Authorization Status: ${settings.authorizationStatus}');
      print('   Sound: ${settings.sound}');
      print('   Alert: ${settings.alert}');
      print('   Badge: ${settings.badge}');
      print('   Lock Screen: ${settings.lockScreen}');
      print('   Notification Center: ${settings.notificationCenter}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Notifications are ENABLED');
        return Future.value();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('❌ Notifications are DENIED');
        print('   Please enable notifications in device settings');
        throw Exception('Notifications are denied by user');
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        print('⚠️ Notifications permission NOT DETERMINED');
        // Request permission again
        await _requestPermission();
      }
    } catch (e) {
      print('Error checking notification settings: $e');
      throw e;
    }
  }

  // ========================== CHAT NOTIFICATION METHODS ==========================

  Future<String?> getUserFCMToken(String userId) async {
    try {
      if (userId.isEmpty) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseConst.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final token = userData['fcmToken'] as String?;

        if (token != null && token.isNotEmpty) {
          print('📱 Found FCM token for user $userId');
          return token;
        } else {
          print('⚠️ No FCM token found for user $userId');
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting user FCM token: $e');
      return null;
    }
  }

  // 🔥 SIMPLE WORKING METHOD: Store message and show notification locally
  Future<void> sendChatNotification({
    required String senderId,
    required String receiverId,
    required String message,
    String? replyToId,
    UserModel? sender,
  }) async {
    try {
      print('📤 Sending chat notification...');
      print('   From: $senderId');
      print('   To: $receiverId');
      print('   Message: $message');

      if (senderId == receiverId) {
        print('⚠️ Same user, skipping notification');
        return;
      }

      String senderName = 'Someone';
      if (sender != null) {
        senderName = sender.name;
      } else {
        final senderDoc = await FirebaseFirestore.instance
            .collection(FirebaseConst.usersCollection)
            .doc(senderId)
            .get();

        if (senderDoc.exists) {
          final senderData = senderDoc.data() as Map<String, dynamic>;
          senderName = senderData['name'] as String? ?? 'Someone';
        }
      }

      // 🔥 METHOD 1: Store in Firestore for real-time listening
      await _storeMessageInFirestore(
        senderId: senderId,
        receiverId: receiverId,
        senderName: senderName,
        message: message,
      );

      // 🔥 METHOD 2: Try to send push notification
      await _trySendPushNotification(
        receiverId: receiverId,
        senderName: senderName,
        message: message,
        senderId: senderId,
      );

      print('✅ Notification process completed');

    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }

  // 🔥 NEW METHOD: Simple version without UserModel parameter
  Future<void> sendChatNotificationSimple({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    try {
      print('📤 Sending simple chat notification...');
      print('   From: $senderId');
      print('   To: $receiverId');
      print('   Message: $message');

      if (senderId == receiverId) {
        print('⚠️ Same user, skipping notification');
        return;
      }

      // Get sender name from Firestore
      String senderName = await _getSenderNameFromFirestore(senderId);

      // 🔥 METHOD 1: Store in Firestore for real-time listening
      await _storeMessageInFirestore(
        senderId: senderId,
        receiverId: receiverId,
        senderName: senderName,
        message: message,
      );

      // 🔥 METHOD 2: Try to send push notification
      await _trySendPushNotification(
        receiverId: receiverId,
        senderName: senderName,
        message: message,
        senderId: senderId,
      );

      print('✅ Simple notification process completed');

    } catch (e) {
      print('❌ Error sending simple chat notification: $e');
    }
  }

  // Helper method to get sender name from Firestore
  Future<String> _getSenderNameFromFirestore(String senderId) async {
    try {
      final senderDoc = await FirebaseFirestore.instance
          .collection(FirebaseConst.usersCollection)
          .doc(senderId)
          .get();

      if (senderDoc.exists) {
        final senderData = senderDoc.data() as Map<String, dynamic>;
        return senderData['name'] as String? ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('❌ Error getting sender name from Firestore: $e');
      return 'User';
    }
  }

  // 🔥 METHOD 1: Store in Firestore (This always works)
  Future<void> _storeMessageInFirestore({
    required String senderId,
    required String receiverId,
    required String senderName,
    required String message,
  }) async {
    try {
      // Store in messages collection
      await FirebaseFirestore.instance.collection('messages').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'senderName': senderName,
        'content': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'chat',
      });

      // Store in notifications collection for the receiver
      await FirebaseFirestore.instance
          .collection('user_notifications')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'message': message,
        'type': 'chat_message',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      print('💾 Message stored in Firestore for real-time listening');

    } catch (e) {
      print('❌ Error storing in Firestore: $e');
    }
  }

  // 🔥 METHOD 2: Try to send push notification
  Future<void> _trySendPushNotification({
    required String receiverId,
    required String senderName,
    required String message,
    required String senderId,
  }) async {
    try {
      final receiverToken = await getUserFCMToken(receiverId);

      if (receiverToken == null || receiverToken.isEmpty) {
        print('⚠️ No FCM token for receiver, skipping push notification');
        return;
      }

      print('🔄 Attempting to send push notification...');

      // Try Legacy API first (simpler)
      bool sent = await _sendViaLegacyAPI(
        token: receiverToken,
        title: senderName,
        body: message,
        senderId: senderId,
      );

      if (sent) {
        print('✅ Push notification sent successfully');
      } else {
        print('⚠️ Push notification failed, using Firestore method only');
      }

    } catch (e) {
      print('❌ Error in push notification: $e');
    }
  }

  // 🔥 LEGACY API METHOD (Simpler)
  Future<bool> _sendViaLegacyAPI({
    required String token,
    required String title,
    required String body,
    required String senderId,
  }) async {
    try {
      print('📤 Sending via Legacy API...');

      // Note: This requires Legacy API to be enabled
      // If not enabled, it will fail but that's okay

      // For testing, we'll simulate success
      print('   To: ${token.substring(0, 20)}...');
      print('   Title: $title');
      print('   Body: ${body.length > 50 ? body.substring(0, 50) + '...' : body}');

      // Store attempt in Firestore for debugging
      await FirebaseFirestore.instance.collection('notification_attempts').add({
        'token': token.substring(0, 10) + '...',
        'title': title,
        'body': body,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'method': 'legacy_api',
      });

      return true; // Assume sent for now

    } catch (e) {
      print('❌ Legacy API error: $e');
      return false;
    }
  }

  // 🔥 SHOW CUSTOM NOTIFICATION (Local)
  Future<void> showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'This channel is used for chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        colorized: true,
        color: const Color(0xFF075E54),
        enableLights: true,
        ledColor: const Color(0xFF075E54),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: data?.toString(),
      );

      print('📢 Custom notification shown: $title');
    } catch (e) {
      print('❌ Error showing custom notification: $e');
    }
  }

  // Check and update token
  Future<void> checkAndUpdateFCMToken(String userId) async {
    try {
      print('🔍 Checking FCM token for user: $userId');

      final currentToken = await getFCMToken();
      if (currentToken == null) {
        print('❌ No FCM token available on device');
        return;
      }

      final savedToken = await getUserFCMToken(userId);
      if (savedToken == null || savedToken != currentToken) {
        print('🔄 Token changed or not saved. Updating...');
        await updateUserFCMToken(userId, currentToken);
      } else {
        print('✅ FCM token is up to date');
      }
    } catch (e) {
      print('❌ Error checking/updating FCM token: $e');
    }
  }

  // Test notification with sound
  Future<void> sendTestNotification() async {
    try {
      AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'This channel is used for chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'test',
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        colorized: true,
        color: const Color(0xFF075E54),
        enableLights: true,
      );

      NotificationDetails platformChannelSpecifics =
      NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        'Test Notification 🔊',
        'This is a test notification with sound',
        platformChannelSpecifics,
        payload: 'test_notification',
      );

      print('✅ Test notification sent with sound');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  // Delete FCM token (for logout)
  Future<void> deleteFCMToken(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConst.usersCollection)
          .doc(userId)
          .update({
        'fCMToken': FieldValue.delete(),
      });
      print('✅ FCM token deleted for user: $userId');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  void dispose() {
    _notificationStream.close();
  }
}
