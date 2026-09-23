import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/screens/my_accepted_applications.dart';
import 'package:tailor_app/services/token_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateVacancyScreen extends StatefulWidget {
  @override
  _CreateVacancyScreenState createState() => _CreateVacancyScreenState();
}

class _CreateVacancyScreenState extends State<CreateVacancyScreen> {
  final TextEditingController salaryController = TextEditingController();
  String? selectedWorkingHours;

  bool isLoading = false;

  final List<String> workingHoursOptions = [
    'Part-time (4 hours)',
    'Full-time (8 hours)',
    'Overtime (10+ hours)',
    'Flexible hours'
  ];

  Future<void> _createVacancy() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (CurrentState.email.isEmpty) await getUserDetails();
      final response = await http.post(
        Uri.parse('$apiUrl/vacancy/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': CurrentState.email,
          'working_hours': selectedWorkingHours,
          'salary_offered': salaryController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vacancy created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        salaryController.clear();
        setState(() {
          selectedWorkingHours = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create vacancy: ${json.decode(response.body)['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return MyAcceptedApplicationsScreen();
                  }));
                },
                icon: const Icon(Icons.people_outline, color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () {
                  var result = TokenStorage.clearToken();
                  if (result != null) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Post Vacancy',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/intro4.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.9), Colors.transparent, Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 32.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hire Talent',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                  Text(
                    'Find the best tailors for your boutique.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1),
                  const SizedBox(height: 48),
                  
                  // Dropdown for Working Hours
                  const Text(
                    'WORKING HOURS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 2),
                  ).animate().fade(duration: 500.ms, delay: 200.ms),
                  const SizedBox(height: 16),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12, width: 2)),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedWorkingHours,
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                      items: workingHoursOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedWorkingHours = newValue;
                        });
                      },
                      hint: Text('Select Shift Timing', style: TextStyle(color: Colors.grey[400])),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ).animate().fade(duration: 500.ms, delay: 250.ms).slideX(begin: -0.1),
                  const SizedBox(height: 40),

                  // Text Field for Salary Offered
                  const Text(
                    'SALARY (₹)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 2),
                  ).animate().fade(duration: 500.ms, delay: 300.ms),
                  const SizedBox(height: 16),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black12, width: 2)),
                    ),
                    child: TextField(
                      controller: salaryController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'e.g., 15000',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ).animate().fade(duration: 500.ms, delay: 350.ms).slideX(begin: -0.1),
                  const SizedBox(height: 64),

                  // Create Vacancy Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedWorkingHours != null && salaryController.text.isNotEmpty) {
                          _createVacancy();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all fields.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'PUBLISH VACANCY',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                    ).animate().fade(duration: 500.ms, delay: 450.ms).scale(begin: const Offset(0.9, 0.9)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
