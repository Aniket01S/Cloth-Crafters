import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tailor_app/screens/tailor/application_status_screen.dart';
import 'package:tailor_app/screens/tailor/vacancy_screen.dart';
import 'package:tailor_app/screens/profile/profile_screen.dart';
import 'package:tailor_app/screens/boutique/open_orders_screen.dart';
import 'package:tailor_app/screens/boutique/my_jobs_screen.dart';

import '../../services/token_storage.dart';

class ControllerScreenTailor extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ControllerScreenState();
  }
}

class _ControllerScreenState extends State<ControllerScreenTailor> {
  var currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return buildUI(context);
  }

  Widget buildUI(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: <Widget>[
        Vacancy(), // Screen for the Vacancy tab
        ApplicationStatusScreen(), // Screen for the Application Status tab
        OpenOrdersScreen(), // Screen for open user requests
        MyJobsScreen(), // Screen to track accepted jobs
        ProfileScreen(),
      ][currentPageIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.work_outline, Icons.work, 0, 'VACANCY'),
              _buildNavItem(Icons.check_circle_outline, Icons.check_circle, 1, 'STATUS'),
              _buildNavItem(Icons.style_outlined, Icons.style, 2, 'OPEN'),
              _buildNavItem(Icons.handyman_outlined, Icons.handyman, 3, 'JOBS'),
              _buildNavItem(Icons.person_outline, Icons.person, 4, 'PRO'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index, String label) {
    final isSelected = currentPageIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentPageIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
