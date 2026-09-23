import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/screens/account/terms_privacy_screen.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  bool _passwordVisibility = false;
  bool _isChecked = false;
  String _selectedOption = "User";

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isFetchingLocation = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _autoFillAddressFromLocation();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _autoFillAddressFromLocation() async {
    if (mounted) setState(() => _isFetchingLocation = true);
    String detectedCity = await fetchLocationAndCity();
    if (mounted) {
      setState(() {
        _isFetchingLocation = false;
        if (detectedCity.isNotEmpty && _addressController.text.isEmpty) {
          _addressController.text = detectedCity;
        }
      });
    }
  }

  bool _validateFields() {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showErrorDialog("All fields are required.");
      return false;
    }
    if (!_isChecked) {
      _showErrorDialog("You must agree to the Terms & Privacy.");
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Error", style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.black)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerUser() async {
    if (_validateFields()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFF06292))),
      );

      try {
        bool success = await registerUser(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
          userType: _selectedOption,
          address: _addressController.text.trim(),
        );

        Navigator.pop(context);

        if (success) {
          Fluttertoast.showToast(
            msg: "User registered successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro2.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      height: MediaQuery.of(context).size.height * 0.85,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Create Account \u2728",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Join us and explore amazing styles",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            buildCuteTextField(
                              controller: _usernameController,
                              icon: Icons.person_rounded,
                              label: 'Username',
                              hint: 'Enter your name',
                            ),
                            const SizedBox(height: 16),
                            
                            buildCuteTextField(
                              controller: _emailController,
                              icon: Icons.alternate_email_rounded,
                              label: 'Email Address',
                              hint: 'Enter your email',
                            ),
                            const SizedBox(height: 16),
                            
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.shade50.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IntlPhoneField(
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: Color(0xFFF06292), width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                ),
                                initialCountryCode: 'IN',
                                dropdownIconPosition: IconPosition.trailing,
                                flagsButtonPadding: const EdgeInsets.only(left: 12),
                                onChanged: (phone) {
                                  _phoneController.text = phone.completeNumber;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            buildCuteTextField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              label: 'Password',
                              hint: 'Create a password',
                              isPassword: true,
                            ),
                            const SizedBox(height: 24),
                            
                            const Text(
                              "I am a...",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: buildCuteRoleButton("User", Icons.shopping_bag_rounded)),
                                const SizedBox(width: 8),
                                Expanded(child: buildCuteRoleButton("Tailor", Icons.content_cut_rounded)),
                                const SizedBox(width: 8),
                                Expanded(child: buildCuteRoleButton("Boutique", Icons.storefront_rounded)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            buildCuteTextField(
                              controller: _addressController,
                              icon: Icons.home_rounded,
                              label: 'Address',
                              hint: 'Enter your city or address',
                              suffixIcon: IconButton(
                                icon: _isFetchingLocation
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF06292)))
                                    : const Icon(Icons.my_location_rounded, color: Color(0xFFF06292)),
                                onPressed: _autoFillAddressFromLocation,
                                tooltip: "Auto-detect location",
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            Row(
                              children: [
                                Checkbox(
                                  value: _isChecked,
                                  activeColor: const Color(0xFFF06292),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  onChanged: (value) => setState(() => _isChecked = value ?? false),
                                ),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      text: "I agree to the ",
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                      children: [
                                        TextSpan(
                                          text: "Terms & Privacy",
                                          style: const TextStyle(color: Color(0xFFF06292), fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => TermsPrivacyScreen()));
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF06292),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: const Color(0xFFF06292).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: "Already have an account? ",
                                  style: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w500),
                                  children: [
                                    TextSpan(
                                      text: "Log In",
                                      style: const TextStyle(
                                        color: Color(0xFFF06292),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCuteRoleButton(String role, IconData icon) {
    bool isSelected = _selectedOption == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF06292) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFF06292) : Colors.grey.shade300, width: 1.5),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFF06292).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 24),
            const SizedBox(height: 6),
            Text(
              role,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCuteTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade50.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_passwordVisibility : false,
        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFF06292)),
          suffixIcon: suffixIcon ?? (isPassword
              ? IconButton(
                  icon: Icon(
                    !_passwordVisibility ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: Colors.black38,
                  ),
                  onPressed: () => setState(() => _passwordVisibility = !_passwordVisibility),
                )
              : null),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFF06292), width: 1.5),
          ),
        ),
      ),
    );
  }
}
