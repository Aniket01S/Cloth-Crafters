import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tailor_app/screens/notifications_screen.dart';
import 'package:tailor_app/screens/account/order_history_screen.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return buildUI(context);
  }

  Widget buildUI(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.red[100]),
        const Positioned(
          top: 30,
          left: 16, // Adjust this value as needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Aligns children to the start (left)
            children: [
              Text(
                "Account",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 35,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Customize your account settings!",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  spreadRadius: 3,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                buildItem(Icons.person, 'My Profile', () {
                  Navigator.pushNamed(context, '/profile_edit');
                }),
                SizedBox(height: 20),
                buildItem(Icons.accessibility, 'Measurements Profile', () {
                  Navigator.pushNamed(context, '/measurement_profile');
                }),
                SizedBox(height: 20),
                buildItem(Icons.notifications, 'Notifications', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                }),
                SizedBox(height: 20),
                buildItem(Icons.shopping_bag, 'Order History', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                }),
                SizedBox(height: 20),
                buildItem(Icons.settings, 'Settings', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings coming soon!')));
                }),
                SizedBox(height: 20),
                buildItem(Icons.privacy_tip, 'Terms & Privacy', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terms & Privacy coming soon!')));
                }),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildItem(IconData icon, String title, VoidCallback onTapped) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Background color of the container
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            spreadRadius: 2,
          ),
        ],
        borderRadius: BorderRadius.circular(10), // Border radius of the container
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.pink[100], // Background color of the circle avatar
          child: Icon(
            icon, // Icon inside the circle avatar
            color: Colors.black, // Color of the icon
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey, // Color of the trailing icon
        ),
        onTap: onTapped,
      ),
    );
  }
}
