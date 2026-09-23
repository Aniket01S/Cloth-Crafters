import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyAcceptedApplicationsScreen extends StatefulWidget {
  @override
  _MyAcceptedApplicationsScreenState createState() =>
      _MyAcceptedApplicationsScreenState();
}

class _MyAcceptedApplicationsScreenState
    extends State<MyAcceptedApplicationsScreen> {
  // List of accepted applications
  List<Map<String, String>> applications = [
    {
      'name': 'RadhaRani Boutique',
      'salary': '34000',
      'workingHours': '9am to 5pm',
      'address': 'Saket Nagar'
    },
    {
      'name': 'Rohan Boutique',
      'salary': '20000',
      'workingHours': '10am to 9pm',
      'address': 'LIG'
    },
    // Add more applications here as needed
  ];

  // Function to remove an application from the list
  void _removeApplication(int index) {
    setState(() {
      applications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Accepted Applications',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: applications.length,
                itemBuilder: (context, index) {
                  return buildApplicationCard(
                    index,
                    applications[index]['name']!,
                    applications[index]['salary']!,
                    applications[index]['workingHours']!,
                    applications[index]['address']!,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build each application card
  Widget buildApplicationCard(
      int index, String name, String salary, String workingHours, String address) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 40, color: Colors.black),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Salary: $salary'),
                Text('Working Hours: $workingHours'),
                Text('Address: $address'),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _removeApplication(index);
            },
            child: Icon(Icons.check_circle, size: 30, color: Colors.black),
          ),
        ],
      ),
    );
  }
}