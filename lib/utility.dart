import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/token_storage.dart'; // Import the token storage
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

void showFullScreenImageDialog(BuildContext context, String imageData) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4.0,
                child: imageData.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(imageData.split(',').last),
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        imageData,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 80),
                      ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
Future<void> getUserDetails() async {
  final token = await TokenStorage.getToken();

  if (token != null) {
    final decodedToken = JwtDecoder.decode(token);

    // Extract details from the token payload with null checks
    final email = decodedToken['email'] ?? 'Unknown Email';
    final username = decodedToken['username'] ?? 'Unknown Username';
    final userType = decodedToken['user_type'] ?? 'Unknown User Type';
    final address = decodedToken['address'] ?? '';

    // Set these details in the CurrentState class
    CurrentState.email = email;
    CurrentState.username = username;
    CurrentState.userType = userType;
    CurrentState.address = address;

    // Now, print the values
    print('Email: ${CurrentState.email}');
    print('Username: ${CurrentState.username}');
    print('User Type: ${CurrentState.userType}');
    print('Address: ${CurrentState.address}');
  } else {
    print('No token found');
  }
}

class CurrentState {
  static String _username = "", _email = "", _userType = "", _city = "", _address = "";

  CurrentState();

  static String get userType => _userType;
  static String get email => _email;
  static String get username => _username;
  static String get city => _city;
  static String get address => _address;
  static String get userLocationOrCity => _address.trim().isNotEmpty ? _address : _city;

  static set userType(String value) {
    _userType = value;
  }

  static set email(String value) {
    _email = value;
  }

  static set username(String value) {
    _username = value;
  }

  static set city(String value) {
    _city = value;
  }

  static set address(String value) {
    _address = value;
  }
}

Future<String> fetchLocationAndCity() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return '';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return '';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return '';
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      String detectedCity = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? "";
      if (detectedCity.isNotEmpty) {
        CurrentState.city = detectedCity;
      }
      print('City updated to: ${CurrentState.city}');
      return detectedCity;
    }
  } catch (e) {
    print("Error fetching location: $e");
  }
  return '';
}
