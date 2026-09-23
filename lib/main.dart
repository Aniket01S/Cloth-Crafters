import 'package:flutter/material.dart';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/services/token_storage.dart';
import 'package:tailor_app/dress_collection_screen.dart';
import 'package:tailor_app/screens/account/manual_measurement.dart';
import 'package:tailor_app/screens/account/measurement_controller.dart';
import 'package:tailor_app/screens/account/measurement_profile.dart';
import 'package:tailor_app/screens/account/order_history_screen.dart';
import 'package:tailor_app/screens/account/terms_privacy_screen.dart';
import 'package:tailor_app/screens/boutique/controller_screen.dart';
import 'package:tailor_app/screens/controller_screen.dart';
import 'package:tailor_app/screens/login_screen.dart';
import 'package:tailor_app/screens/my_accepted_applications.dart';
import 'package:tailor_app/screens/order_dress_screen.dart';
import 'package:tailor_app/screens/order_fabric_screen.dart';
import 'package:tailor_app/screens/profile/profile_edit_screen.dart';
import 'package:tailor_app/screens/profile/profile_screen.dart';
import 'package:tailor_app/screens/search_tailor_screen.dart';
import 'package:tailor_app/screens/signup_screen.dart';
import 'package:tailor_app/screens/tailor/controller_screen.dart';
import 'package:tailor_app/screens/notifications_screen.dart';
import 'package:tailor_app/screens/welcome_screen.dart';

import 'package:tailor_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  NotificationService().startPolling();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _homeScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    await fetchLocationAndCity(); // Fetch location and city first
    final token = await TokenStorage.getToken();
    if (token != null) {
      await getUserDetails();
      if (CurrentState.userType == 'Tailor') {
        setState(() {
          _homeScreen = ControllerScreenTailor();
        });
        return;
      } else if (CurrentState.userType == 'Boutique') {
        setState(() {
          _homeScreen = ControllerScreenBoutique();
        });
        return;
      } else {
        setState(() {
          _homeScreen = ControllerScreen();
        });
        return;
      }
    }
    setState(() {
      _homeScreen = WelcomeScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailor App',
      theme: ThemeData(
        canvasColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        focusColor: Colors.blue,
        useMaterial3: true,
      ),
      home: _homeScreen,
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/controller': (context) => ControllerScreen(),
        '/profile_edit': (context) => ProfileEditScreen(),
        '/profile': (context) => ProfileScreen(),
        '/order_history': (context) => OrderHistoryScreen(),
        '/terms_privacy': (context) => TermsPrivacyScreen(),
        '/measurement_profile': (context) => MeasurementController(),
        '/dresscollection': (context) => DressCollectionScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}


