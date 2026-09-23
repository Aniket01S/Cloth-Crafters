import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/services/token_storage.dart';  // For storing token
import '../constants.dart';
  // To access CurrentState class

Future<String?> loginUser(String email, String password) async {
  final url = Uri.parse('$apiUrl/login');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email.trim(),
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];

      // Save token locally
      await TokenStorage.saveToken(token);

      // Decode the token and update the CurrentState
      await getUserDetails();

      return token;
    } else {
      final data = json.decode(response.body);
      final message = data['message'] ?? 'Login failed. Please check your credentials.';
      print('Login failed: $message');
      throw Exception(message);
    }
  } on SocketException catch (e) {
    print('SocketException occurred: $e');
    throw Exception('Cannot connect to server ($apiUrl). Please check server state & network.');
  } on TimeoutException catch (e) {
    print('TimeoutException occurred: $e');
    throw Exception('Connection timed out. Server is not responding.');
  } catch (e) {
    print('Error occurred: $e');
    final errStr = e.toString();
    if (errStr.contains('Connection refused') || errStr.contains('ClientException')) {
      throw Exception('Cannot connect to server ($apiUrl). Ensure server is running.');
    }
    throw Exception(errStr.replaceAll('Exception: ', ''));
  }
}

Future<bool> registerUser({
  required String username,
  required String email,
  required String phoneNumber,
  required String password,
  required String userType,
  required String address,
}) async {
  final url = Uri.parse('$apiUrl/register');

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': username.trim(),
        'email': email.trim(),
        'phone_number': phoneNumber.trim(),
        'password': password,
        'user_type': userType,
        'address': address.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201) {
      return true;
    } else {
      final data = json.decode(response.body);
      final message = data['message'] ?? 'Registration failed.';
      throw Exception(message);
    }
  } on SocketException catch (e) {
    print('SocketException occurred: $e');
    throw Exception('Cannot connect to server ($apiUrl). Please check server state & network.');
  } on TimeoutException catch (e) {
    print('TimeoutException occurred: $e');
    throw Exception('Connection timed out. Server is not responding.');
  } catch (e) {
    print('Error occurred: $e');
    final errStr = e.toString();
    if (errStr.contains('Connection refused') || errStr.contains('ClientException')) {
      throw Exception('Cannot connect to server ($apiUrl). Ensure server is running.');
    }
    throw Exception(errStr.replaceAll('Exception: ', ''));
  }
}
