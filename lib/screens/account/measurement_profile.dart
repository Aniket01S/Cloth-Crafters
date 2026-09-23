import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MeasurementProfile extends StatefulWidget {
  @override
  _MeasurementProfileState createState() => _MeasurementProfileState();
}

class _MeasurementProfileState extends State<MeasurementProfile> {
  String selectedGender = 'Male';
  String phoneNumber = '7389836702';
  String selectedDate = 'Your Selected Date';
  String currentLocation = 'Detecting location...';

  @override
  Widget build(BuildContext context) {
    return buildUI();
  }

  Widget buildUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Get Measured at Home",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Get a professional tailor to get measured at your place.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: buildItemUI("Male")),
                const SizedBox(width: 10),
                Expanded(child: buildItemUI("Female")),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    spreadRadius: 2,
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Uniform vertical padding
                    child: Row(
                      children: [
                        Icon(Icons.call_outlined),
                        SizedBox(width: 8),
                        Text(phoneNumber),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Uniform vertical padding
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.calendar_month_outlined),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                            }
                          },
                        ),
                        SizedBox(width: 8),
                        Text(selectedDate),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0), // Uniform vertical padding
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.location_on_outlined),
                          onPressed: () {
                            print('Tapped');
                          },
                        ),
                        SizedBox(width: 8),
                        Text(currentLocation),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // book visit logic
                  print("Book visit tapped");
                },
                child: Text(
                  "Book Visit",
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
    );
  }

  Widget buildItemUI(String type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = type;
          phoneNumber = type == 'Male' ? '7389836702' : '7992020250';
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              spreadRadius: 2,
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Radio<String>(
                value: type,
                groupValue: selectedGender,
                onChanged: (String? value) {
                  setState(() {
                    selectedGender = value!;
                    phoneNumber = value == 'Male' ? '7389836702' : '7992020250';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
