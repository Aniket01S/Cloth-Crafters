import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tailor_app/constants.dart';
import 'dart:convert';

import '../../services/token_storage.dart';
import '../../utility.dart';

class ApplicationStatusScreen extends StatefulWidget {
  @override
  _ApplicationStatusScreenState createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  List<Map<String, dynamic>> applications = []; // Change type to dynamic
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    final email = CurrentState.email; // Assuming you have a method to get the logged-in user's email
    final response = await http.get(Uri.parse('$apiUrl/applications/$email'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        applications = data.map((application) {
          return {
            'name': application['name'],
            'address': application['address'],
            'phone_number': application['phone_number'],
            'Vacancy_id': application['Vacancy_id'].toString(),
            'email': application['email'],
            'status': application['status'],
          };
        }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        // Handle error appropriately
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Application Status'),
            InkWell(
              child: Icon(Icons.exit_to_app),
              onTap: () {
                print("logout button pressed");
                TokenStorage.clearToken();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : applications.isEmpty
            ? Center(child: Text('No applications found'))
            : ListView.builder(
          itemCount: applications.length,
          itemBuilder: (context, index) {
            return buildApplicationItem(applications[index]);
          },
        ),
      ),
    );
  }

  Widget buildApplicationItem(Map<String, dynamic> application) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              application['name'] ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.home, color: Colors.blueAccent, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    application['address'] ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Phone Number
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact: ${application['phone_number'] ?? ''}',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Vacancy ID
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.work, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vacancy ID: ${application['Vacancy_id'] ?? ''}',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Application Status
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Application Status: ${application['status'] ?? ''}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: application['status'] == 'Accepted'
                      ? Colors.green
                      : application['status'] == 'Rejected'
                      ? Colors.red
                      : Colors.purple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
