import 'package:flutter/material.dart';
import 'dart:convert'; // For decoding JSON responses
import 'package:http/http.dart' as http;
import 'package:tailor_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility.dart'; // For making HTTP requests

class Vacancy extends StatefulWidget {
  @override
  _VacancyState createState() => _VacancyState();
}

class _VacancyState extends State<Vacancy> {
  List<Map<String, dynamic>> vacancies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVacancies();
  }

  Future<void> hideVacancy(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> hidden = prefs.getStringList('hidden_vacancies_${CurrentState.email}') ?? [];
    if (!hidden.contains(id)) {
      hidden.add(id);
      await prefs.setStringList('hidden_vacancies_${CurrentState.email}', hidden);
    }
  }

  // Function to fetch vacancies from the API
  Future<void> fetchVacancies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> hidden = prefs.getStringList('hidden_vacancies_${CurrentState.email}') ?? [];

      final response = await http.get(Uri.parse('$apiUrl/vacancy/all'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched vacancies: ${data['vacancies']}');

        setState(() {
          if (data['vacancies'] != null) {
            List<Map<String, dynamic>> allVacancies = List<Map<String, dynamic>>.from(data['vacancies']);
            
            // Filter out hidden (applied/rejected) vacancies
            allVacancies.removeWhere((v) => hidden.contains(v['Vacancy_id'].toString()));

            if (CurrentState.city.isNotEmpty) {
              vacancies = allVacancies.where((v) => v['address'] != null && v['address'].toString().toLowerCase().contains(CurrentState.city.toLowerCase())).toList();
            } else {
              vacancies = allVacancies;
            }
          } else {
            vacancies = [];
          }
          isLoading = false;
        });
      } else {
        print('Failed to load vacancies');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching vacancies: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to apply for the vacancy
  Future<void> applyForVacancy(String email, String vacancyId) async {
    final response = await http.post(
      Uri.parse('$apiUrl/application/apply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'Vacancy_id': vacancyId,
      }),
    );

    if (response.statusCode == 201) {
      // Application submitted successfully
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message']),
          backgroundColor: Colors.green,
        ));
      }
      // Remove from list so it doesn't show anymore
      hideVacancy(vacancyId);
      setState(() {
        vacancies.removeWhere((v) => v['Vacancy_id'].toString() == vacancyId);
      });
    } else {
      // Handle error
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorData['message']),
        backgroundColor: Colors.red,
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Vacancies'),
            Icon(Icons.exit_to_app),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Vacancy here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),

            // List of Vacancies
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : vacancies.isEmpty
                      ? Center(child: Text('No vacancies available'))
                      : ListView.builder(
                          itemCount: vacancies.length,
                          itemBuilder: (context, index) {
                            return buildVacancyItem(vacancies[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build a single vacancy item with an Apply button
  Widget buildVacancyItem(Map<String, dynamic> vacancy) {
    // Debugging output for each vacancy
    print('Vacancy: $vacancy');

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
            // Vacancy ID
            Text(
              'Vacancy ID: ${vacancy['Vacancy_id'] ?? ''}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),

            // Address
            Text(
              vacancy['address'] ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 12),

            // Working Hours
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text(
                  'Working Hours: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    vacancy['working_hours'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Salary Offered
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Salary Offered: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${vacancy['salary_offered'] ?? ''} Rs./month',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Contact Number
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Contact: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: Text(
                    vacancy['phone_number'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    String vId = vacancy['Vacancy_id'].toString();
                    hideVacancy(vId);
                    setState(() {
                      vacancies.remove(vacancy);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text('Reject', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    String email = CurrentState.email; 
                    String vacancyId = vacancy['Vacancy_id'].toString(); 
                    applyForVacancy(email, vacancyId); 
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), 
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
