import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with WidgetsBindingObserver {
  List<dynamic> notifications = [];
  int unreadCount = 0;
  bool isLoading = true;
  bool permissionGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _requestNotificationPermission();
    fetchNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        permissionGranted = status.isGranted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      if (mounted) setState(() => permissionGranted = true);
      return;
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    final result = await Permission.notification.request();
    if (result.isPermanentlyDenied) {
      await openAppSettings();
    }

    if (mounted) {
      setState(() {
        permissionGranted = result.isGranted;
      });
    }
  }

  Future<void> fetchNotifications() async {
    try {
      if (CurrentState.email.isEmpty) await getUserDetails();
      final email = CurrentState.email;
      
      final response = await http.get(Uri.parse('$apiUrl/notifications/$email'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            notifications = data['notifications'] ?? [];
            unreadCount = data['unread_count'] ?? 0;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final email = CurrentState.email;
      final response = await http.post(
        Uri.parse('$apiUrl/notifications/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        fetchNotifications();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('All notifications marked as read!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'job':
        return Icons.work_outline_rounded;
      case 'review':
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Colors.redAccent;
      case 'job':
        return Colors.orangeAccent;
      case 'review':
        return Colors.amber;
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text('Mark all as read', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Permission Alert Banner if notifications permission is disabled
          if (!permissionGranted)
            Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.notifications_off, color: Colors.amber),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Notifications are disabled. Allow to receive real-time updates.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _requestNotificationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text('Allow', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 70, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            final bool isRead = notif['read'] ?? false;
                            final String type = notif['type'] ?? 'info';

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : Colors.red[50]!.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead ? Colors.black12 : Colors.red.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: _getColorForType(type).withOpacity(0.15),
                                  child: Icon(_getIconForType(type), color: _getColorForType(type), size: 22),
                                ),
                                title: Text(
                                  notif['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['message'] ?? '',
                                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notif['timestamp'] ?? '',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                    ),
                                  ],
                                ),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
