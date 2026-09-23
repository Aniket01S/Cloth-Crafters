import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late Future<Map<String, String>> userProfile;
  bool isFetchingLocation = false;

  // Controllers to manage the text input fields
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userProfile = fetchUserProfile();
  }

  Future<void> _fetchLiveLocation() async {
    setState(() {
      isFetchingLocation = true;
    });
    String detectedCity = await fetchLocationAndCity();
    setState(() {
      isFetchingLocation = false;
      if (detectedCity.isNotEmpty) {
        addressController.text = detectedCity;
        CurrentState.city = detectedCity;
        CurrentState.address = detectedCity;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Live location fetched: $detectedCity'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not fetch location. Please ensure location services are enabled.'),
          backgroundColor: Colors.orange,
        ));
      }
    });
  }

  Future<Map<String, String>> fetchUserProfile() async {
    final email = CurrentState.email;

    if (email == null || email.isEmpty) {
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

      // Pre-fill the controllers with fetched data
      usernameController.text = data['username'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone_number'] ?? '';
      addressController.text = data['address'] ?? '';

      return {
        'username': data['username'] ?? '',
        'email': data['email'] ?? '',
        'phone_number': data['phone_number'] ?? '',
        'address': data['address'] ?? '',
      };
    } else {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateProfile() async {
    final email = CurrentState.email;

    if (email == null || email.isEmpty) {
      throw Exception('Email is missing. Please ensure you are logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/profile/update'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
          'username': usernameController.text,
          'phone_number': phoneController.text,
          'address': addressController.text,
        }),
      );

      if (response.statusCode == 200) {
        CurrentState.username = usernameController.text;
        CurrentState.address = addressController.text;
        CurrentState.city = addressController.text;
        print('Profile updated successfully');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);  // Go back to the previous screen after successful update
      } else {
        // Show error message
        final error = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $error'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (error) {
      // Handle network or other errors
      print('Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: Could not update profile'),
        backgroundColor: Colors.red,
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile'),),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 28, bottom: 50),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
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
              CircleAvatar(
                backgroundImage: AssetImage('assets/images/person.webp'),
                radius: 60,
              ),
              SizedBox(height: 20),
              buildEditableUIItem(Icons.person, "Username", usernameController),
              SizedBox(height: 20),
              buildEditableUIItem(Icons.email, "Email", emailController, isEditable: false),
              SizedBox(height: 20),
              buildEditableUIItem(Icons.phone, "Phone Number", phoneController),
              SizedBox(height: 20),
              buildEditableUIItem(
                Icons.location_on,
                "Address",
                addressController,
                suffixIcon: IconButton(
                  icon: isFetchingLocation
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location, color: Colors.red),
                  onPressed: _fetchLiveLocation,
                  tooltip: "Use Live Location",
                ),
              ),
              SizedBox(height: 30),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await updateProfile();
                  },
                  child: Text(
                    "Update Profile",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildEditableUIItem(IconData icon, String label, TextEditingController controller, {bool isEditable = true, Widget? suffixIcon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      width: double.infinity,
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.red,
            size: 24,
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEditable,  // Make it editable or not
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                suffixIcon: suffixIcon,
              ),
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
