import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tailor_app/screens/account/manual_measurement.dart';
import 'package:tailor_app/screens/account/measurement_profile.dart';

class MeasurementController extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MeasurementControllerState();
  }
}

class _MeasurementControllerState extends State<MeasurementController> {
  @override
  Widget build(BuildContext context) {
    return buildUI();
  }

  Widget buildUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Give Measurements",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Using our technology or with the help of a professional tailor you can measure yourself in your comfort zone",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            buildUIItem(
              'Get Measured at Home by a Tailor',
              'You can now get measured by calling a professional tailor of a specific gender at your home',
                (){
                Navigator.push(context, MaterialPageRoute(builder: (context){return MeasurementProfile();}));
                },
            ),
            SizedBox(height: 20),
            buildUIItem(
              'Measure Yourself',
              'Select the dress category and update your measured body dimensions just in a few taps',
                (){
                  Navigator.push(context, MaterialPageRoute(builder: (context){return ManualMeasurement();}));
                }
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUIItem(String title, String description,var onTapped) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTapped,
        contentPadding: EdgeInsets.all(16.0),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.red,
          ),
        ),
        subtitle: Text(description),
        trailing: Icon(Icons.chevron_right, color: Colors.red),
      ),
    );
  }
}
