import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      // 1. Request Permission
      await requestPermission();

      // 2. Setup Local Notifications (for foreground)
      final AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      
      final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap here if needed
        },
      );

      // 3. Create Android Channel
      if (Platform.isAndroid) {
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          'buku_emak_channel',
          'Notifikasi Buku Emak',
          description: 'Digunakan untuk pengingat arisan dan tabungan',
          importance: Importance.max,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // 4. Listen for Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Handle opening app from notification
      });
      
      // Get token for testing/server side
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
      debugPrint("NotificationService initialized successfully.");
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }
  }

  Future<void> requestPermission() async {
    // Permission for iOS/Android
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Explicit request for Android 13+
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'buku_emak_channel',
            'Notifikasi Buku Emak',
            icon: 'notification_icon',
            largeIcon: null, // Clear large icon for simple top-only display
            color: const Color(0xFF10B981),
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  Future<void> showTestNotification() async {
    try {
      debugPrint("Attempting to show test notification...");
      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'buku_emak_channel',
        'Notifikasi Buku Emak',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: 'notification_icon',
        largeIcon: null, // Move everything to the top header
        color: Color(0xFF10B981),
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics, iOS: DarwinNotificationDetails());
          
      await _localNotifications.show(
        0,
        'Halo, Emak Sayang! 💖',
        'Ini cuma tes notifikasi buat mastiin ijinnya udah beres. Semangat ngebuku ya!',
        platformChannelSpecifics,
      );
      debugPrint("Test notification should be visible now.");
    } catch (e) {
      debugPrint("Error showing test notification: $e");
    }
  }
}
