import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatting
import 'package:http/http.dart' as http; // Importing http package for API calls
import 'dart:convert'; // For encoding and decoding JSON
import 'package:fluttertoast/fluttertoast.dart'; // For showing toast messages
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';

class ManualMeasurement extends StatefulWidget {
  @override
  _ManualMeasurementState createState() => _ManualMeasurementState();
}

class _ManualMeasurementState extends State<ManualMeasurement> {
  // Variables to store the values entered in text fields
  TextEditingController chestSizeController = TextEditingController();
  TextEditingController waistSizeController = TextEditingController();
  TextEditingController hipSizeController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  TextEditingController shoulderWidthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
  }

// Function to fetch measurements from the API
  Future<void> _fetchMeasurements() async {
    try {
      final email = CurrentState.email; // Replace with the actual email
      final url = Uri.parse('$apiUrl/measurements/$email');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ensure data is not null and fields are converted to string
        setState(() {
          chestSizeController.text = (data['chest_size'] != null) ? data['chest_size'].toString() : '';
          waistSizeController.text = (data['waist_size'] != null) ? data['waist_size'].toString() : '';
          hipSizeController.text = (data['hip_size'] != null) ? data['hip_size'].toString() : '';
          heightController.text = (data['height'] != null) ? data['height'].toString() : '';
          shoulderWidthController.text = (data['shoulder_width'] != null) ? data['shoulder_width'].toString() : '';
        });
      } else if (response.statusCode == 404) {
        // Handle case where no measurements are found
        print('No measurements found for this user.');
        // Optionally clear the fields or show a message
        setState(() {
          chestSizeController.text = '';
          waistSizeController.text = '';
          hipSizeController.text = '';
          heightController.text = '';
          shoulderWidthController.text = '';
        });
      } else {
        _showErrorDialog('Failed to fetch measurements. Please try again later.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred while fetching measurements.');
    }
  }


  // Function to check if any field is empty
  bool _isAnyFieldEmpty() {
    return chestSizeController.text.isEmpty ||
        waistSizeController.text.isEmpty ||
        hipSizeController.text.isEmpty ||
        heightController.text.isEmpty ||
        shoulderWidthController.text.isEmpty;
  }

  // Function to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // Function to make the API POST call
  Future<void> _saveMeasurements() async {
    if (_isAnyFieldEmpty()) {
      _showErrorDialog('All fields are required!');
      return;
    }

    try {
      final url = Uri.parse('$apiUrl/measurements');

      // Make a POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': CurrentState.email,  // Replace with the actual email
          'chest_size': chestSizeController.text,
          'waist_size': waistSizeController.text,
          'hip_size': hipSizeController.text,
          'height': heightController.text,
          'shoulder_width': shoulderWidthController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show success toast and go back
        Fluttertoast.showToast(
          msg: "Measurements saved successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pop(context); // Go back to the previous screen
      } else {
        _showErrorDialog('Failed to save measurements. Please try again later.');
      }
    } catch (error) {
      _showErrorDialog('An error occurred. Please check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildUI();
  }

  Widget buildUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manual Measurement"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            buildTextField('Chest Size (in cm)', chestSizeController),
            const SizedBox(height: 20),
            buildTextField('Waist Size (in cm)', waistSizeController),
            const SizedBox(height: 20),
            buildTextField('Hip Size (in cm)', hipSizeController),
            const SizedBox(height: 20),
            buildTextField('Height (in cm)', heightController),
            const SizedBox(height: 20),
            buildTextField('Shoulder Width (in cm)', shoulderWidthController),
            const SizedBox(height: 40),
            buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // Reusable TextField builder for float inputs with hints
  Widget buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ], // Restrict input to floats
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // Save button
  Widget buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _saveMeasurements(); // Call the function when save is pressed
        },
        child: Text(
          "Save Changes",
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
    );
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is removed from the widget tree
    chestSizeController.dispose();
    waistSizeController.dispose();
    hipSizeController.dispose();
    heightController.dispose();
    shoulderWidthController.dispose();
    super.dispose();
  }
}
