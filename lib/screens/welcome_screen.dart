import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tailor_app/screens/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  @override

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              buildPageContent("assets/images/intro3.jpeg"),
              buildPageContent("assets/images/intro1.jpeg"),
              buildPageContent("assets/images/intro2.jpeg"),
              buildPageContent("assets/images/intro2.jpeg"),
            ],
          ),
          Positioned(
            top: 30,
            right: 20,
            child: TextButton(
              onPressed: () {
                navigateToRoute('/login',context);
              },
              child: const Text(
                "SKIP",
                style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,letterSpacing: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    spreadRadius: 3,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == 0
                        ? "Customize your clothes"
                        : _currentPage == 1
                        ? "Get Measurements"
                        : _currentPage == 2
                        ? "Alter your clothes"
                        : "Empowering Business",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _currentPage == 0
                        ? "Personalize your wardrobe by choosing fabrics, colors, and styles to create unique outfits that reflect your taste."
                        : _currentPage == 1
                        ? "Accurately measure yourself or schedule a fitting appointment to ensure perfectly tailored clothing that fits like a dream."
                        : _currentPage == 2
                        ? "Need adjustments? Whether it’s hemming, resizing, or restyling, our skilled tailors will transform your garments to perfection."
                        : "Tailors, entrepreneurs, this app provides tools and resources to boost your business.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, letterSpacing: 0.5),
                  ),
                  SizedBox(height: 20),
                  buildPageIndicator(),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 3) {
                          _controller.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        } else {
                          navigateToRoute('/login', context);
                        }
                      },

                      child: Text(_currentPage < 3 ? "Next" : "Get Started" , style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),

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
          ),
        ],
      ),
    );
  }

  Widget buildPageContent(String imagePath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withOpacity(0.2), // Dark overlay to improve text visibility
        ),
      ],
    );
  }

  Widget buildPageIndicator() {
    return SmoothPageIndicator(
      controller: _controller,
      count: 4,
      effect: const ExpandingDotsEffect(
        dotWidth: 8,
        dotHeight: 8,
        activeDotColor: Colors.redAccent,
      ),
    );
  }

  void navigateToRoute(String s, BuildContext context) {
    print('inside method');
    Navigator.popAndPushNamed(context, s);
    return;
  }
}
