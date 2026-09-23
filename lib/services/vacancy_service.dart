import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tailor_app/constants.dart';

class VacancyService {
  static const String postVacancyUrl = '$apiUrl/vacancy/post'; // Replace with your actual API URL

  static Future<Map<String, dynamic>> postVacancy({
    required String email,
    required String workingHours,
    required String salaryOffered,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(postVacancyUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email, // Correct field name
          'working_hours': workingHours, // Correct field name
          'salary_offered': salaryOffered, // Correct field name
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body); // Vacancy posted successfully
      } else {
        try {
          final body = jsonDecode(response.body);
          return {
            'error': (body is Map && body.containsKey('message')) ? body['message'] : 'Failed to post vacancy'
          };
        } catch (e) {
          return {'error': 'Failed to post vacancy'};
        }
      }
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  // Method to delete a vacancy by Vacancy_id
  Future<bool> deleteVacancy(String vacancyId) async {
    final url = Uri.parse('$apiUrl/vacancy/delete/$vacancyId'); // Complete URL

    try {
      final response = await http.delete(url);

      // Check the response status code
      if (response.statusCode == 200) {
        print('Vacancy deleted successfully.');
        return true; // Deletion successful
      } else {
        // Handle errors based on status code
        print('Failed to delete vacancy: ${response.body}');
        return false; // Deletion failed
      }
    } catch (e) {
      print('Error occurred while deleting vacancy: $e');
      return false; // An error occurred
    }
  }

}
