import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String title; // Text on the button
  final VoidCallback onTap; // Function to handle button tap

  const RoundedButton({
    Key? key,
    required this.title, // Ensure the title is required
    required this.onTap, // Ensure the onTap is required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap, // The callback function
        child: Text(
          title, // Button text
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }
}
