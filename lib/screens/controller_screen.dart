import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/screens/cart_screen.dart';
import 'package:tailor_app/screens/home_screen.dart';
import 'package:tailor_app/dress_collection_screen.dart';
import 'account/account_screen.dart';

class ControllerScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ControllerScreenState();
  }
}

class _ControllerScreenState extends State<ControllerScreen> {
  var currentPageIndex = 0;
  int cartCount = 1;

  @override
  void initState() {
    super.initState();
    fetchCartCount();
  }

  Future<void> fetchCartCount() async {
    try {
      if (CurrentState.email.isEmpty) await getUserDetails();
      final email = CurrentState.email;
      if (email.isEmpty) return;

      int total = 0;
      final res1 = await http.get(Uri.parse('$apiUrl/cart/product-null/$email'));
      if (res1.statusCode == 200) {
        total += (jsonDecode(res1.body) as List).length;
      }

      final res2 = await http.get(Uri.parse('$apiUrl/cart/fabric-null/$email'));
      if (res2.statusCode == 200) {
        total += (jsonDecode(res2.body) as List).length;
      }

      final res3 = await http.get(Uri.parse('$apiUrl/alter_clothes/$email'));
      if (res3.statusCode == 200) {
        total += (jsonDecode(res3.body) as List).length;
      }

      final res4 = await http.get(Uri.parse('$apiUrl/customize_clothes/$email'));
      if (res4.statusCode == 200) {
        total += (jsonDecode(res4.body) as List).length;
      }

      if (mounted) {
        setState(() {
          cartCount = total;
        });
      }
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 65,
        elevation: 10,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF4511E),
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            if (index == 1) fetchCartCount();
          });
        },
        destinations: <Widget>[
          const NavigationDestination(
            selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cartCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            label: 'My Cart',
          ),
          const NavigationDestination(
            selectedIcon: Icon(Icons.favorite_rounded, color: Colors.white),
            icon: Icon(Icons.favorite_outline_rounded),
            label: 'Wishlist',
          ),
          const NavigationDestination(
            selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
            icon: Icon(Icons.person_outline_rounded),
            label: 'Account',
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          HomeScreen(),
          CartScreen(),
          DressCollectionScreen(),
          AccountScreen(),
        ],
      ),
    );
  }
}
