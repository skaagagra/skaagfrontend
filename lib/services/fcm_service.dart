import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

// Background handler must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Get Token and update backend
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("FCM Token: $token");
      await syncToken();
    }
  }

  Future<void> syncToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print("Syncing FCM Token: $token");
      await _updateBackendToken(token);
    }
  }

  Future<void> _updateBackendToken(String token) async {
    try {
      // We pass generic values for other fields if we only want to update token.
      // However, the API might require all fields. 
      // Assuming updateProfile handles partial updates or we fetch profile first.
      // For now, we will try to update just the token if possible, or leave it. 
      // The user's requested API has updateProfile taking (fullName, address, fcmToken).
      // We might need to fetch current profile first.
      
      final profile = await ApiService().getProfile();
      await ApiService().updateProfile(
        fullName: profile['full_name'] ?? '',
        address: profile['address'] ?? '',
        fcmToken: token,
      );
    } catch (e) {
      print("Failed to update FCM token on backend: $e");
    }
  }
}
