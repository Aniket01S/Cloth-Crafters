import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Welcome to Our App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We aim to provide a seamless and enjoyable experience while using our services. This guide will help you understand our key policies and how to get support when needed.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '2. How We Collect Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We collect information such as your name, email address, and phone number when you register on our platform. This helps us offer personalized services and support.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '3. Use of Your Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your data is used to:\n- Provide a personalized experience.\n- Ensure your orders are handled smoothly.\n- Keep you updated with relevant information and offers.\n- Improve our services based on your feedback.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '4. Sharing Your Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We do not share your personal information with third parties unless it is necessary to operate the service or required by law. We take measures to protect your privacy.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '5. Security Measures',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We use advanced security protocols to keep your data safe. Only authorized personnel have access to your information, and they are bound by strict confidentiality agreements.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '6. Contact Us',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            RichText(
              text: TextSpan(
                text: 'If you have any questions or require assistance, please feel free to reach out to our support team. We are here to help you with any issues or queries you may have.',
                style: TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(text: '\n\nSupport Contact No.: '),
                  TextSpan(
                    text: '+91-8871152761',
                    style: TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('Tapped the contact number');
                      },
                  ),
                  TextSpan(text: '\nSupport Email: '),
                  TextSpan(
                    text: 'aniketsingh123787898@gmail.com',
                    style: TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('Tapped the email');
                      },
                  ),
                  TextSpan(
                      text:
                      '\n\nWe strive to respond to all inquiries within 24-48 hours.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
