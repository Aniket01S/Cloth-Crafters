import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/services/token_storage.dart';
import 'package:tailor_app/screens/boutique_detail_screen.dart';
import 'package:tailor_app/screens/notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, String>> userProfile;

  @override
  void initState() {
    super.initState();
    userProfile = fetchUserProfile();
  }

  Future<Map<String, String>> fetchUserProfile() async {
    if (CurrentState.email.isEmpty) {
      await getUserDetails();
    }
    final email = CurrentState.email;

    if (email.isEmpty) {
      throw Exception('Email is missing. Please ensure you are logged in.');
    }

    final response = await http.post(
      Uri.parse('$apiUrl/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        'username': data['username'] ?? 'N/A',
        'email': data['email'] ?? 'N/A',
        'phone_number': data['phone_number'] ?? 'N/A',
        'address': data['address'] ?? 'N/A',
        'user_type': data['user_type'] ?? 'User',
      };
    } else {
      throw Exception('Failed to load profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: userProfile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final data = snapshot.data!;
              final username = data['username'] ?? 'User';

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi $username!",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Manage your account & profile settings",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Content Card
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            spreadRadius: 2,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.red[100],
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 20),
                          buildUIItem(Icons.person, data['username']!),
                          SizedBox(height: 16),
                          buildUIItem(Icons.email, data['email']!),
                          SizedBox(height: 16),
                          buildUIItem(Icons.phone, data['phone_number']!),
                          SizedBox(height: 16),
                          buildUIItem(Icons.location_on, data['address']!),
                          SizedBox(height: 24),

                          // Notifications Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                              },
                              icon: Icon(Icons.notifications_active, color: Colors.red),
                              label: Text(
                                "Notifications & Alerts",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Edit Profile Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/profile_edit');
                                setState(() {
                                  userProfile = fetchUserProfile();
                                });
                              },
                              icon: Icon(Icons.edit),
                              label: Text(
                                "Edit Profile",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // View Reviews / Public Profile Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BoutiqueDetailScreen(
                                      provider: {
                                        'email': data['email'],
                                        'username': data['username'],
                                        'address': data['address'],
                                        'phone_number': data['phone_number'],
                                        'user_type': data['user_type'],
                                      },
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.star, color: Colors.amber),
                              label: Text(
                                "View Public Profile & Reviews",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () async {
                                await TokenStorage.clearToken();
                                CurrentState.email = '';
                                CurrentState.username = '';
                                CurrentState.userType = '';
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              },
                              icon: Icon(Icons.logout, color: Colors.red),
                              label: Text(
                                "Logout",
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildUIItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      width: double.infinity,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.red,
            size: 22,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
