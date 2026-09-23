import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Timer? _pollingTimer;
  final Set<String> _shownNotificationIds = {};
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap here if needed
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  void startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    
    // Poll every 10 seconds for new notifications
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkNewNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkNewNotifications() async {
    final email = CurrentState.email;
    if (email.isEmpty) return;

    try {
      final response = await http.get(Uri.parse('$apiUrl/notifications/$email'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> notifications = data['notifications'] ?? [];

        // Check for unread notifications that haven't been shown as a system popup yet
        for (var notif in notifications) {
          final String id = notif['id'] ?? '';
          final bool isRead = notif['read'] ?? false;
          
          if (!isRead && id.isNotEmpty && !_shownNotificationIds.contains(id)) {
            _shownNotificationIds.add(id);
            _showNotification(notif['title'] ?? 'New Alert', notif['message'] ?? 'You have a new notification.');
          }
        }
      }
    } catch (e) {
      print('Error polling notifications: $e');
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'tailor_app_channel_id',
      'Tailor App Notifications',
      channelDescription: 'Important updates for Tailor App',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID for each notification instance
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }
}
