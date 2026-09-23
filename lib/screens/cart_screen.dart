import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/widgets/empty_cart.dart';
import 'package:tailor_app/widgets/cart_item.dart';
import 'package:tailor_app/widgets/alter_customize.dart';
import '../widgets/rounded_button.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> alterCustomizeItems = [];

  var sum;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    fetchDressItems();
    fetchAlterCustomizeRequests();
    fetchCustomizeRequests();
  }

  Future<void> refreshCart() async {
    setState(() {
      cartItems.clear();
      alterCustomizeItems.clear();
    });

    await fetchCartItems();
    await fetchDressItems();
    await fetchAlterCustomizeRequests();
    await fetchCustomizeRequests();
  }

  Future<void> fetchAlterCustomizeRequests() async {
    final email = CurrentState.email;
    final alterCustomizeUrl = '$apiUrl/alter_clothes/$email';

    try {
      final response = await http.get(Uri.parse(alterCustomizeUrl));
      if (response.statusCode == 200) {
        final List<dynamic> alterCustomizeResponse = json.decode(response.body);
        setState(() {
          alterCustomizeItems = List<Map<String, dynamic>>.from(alterCustomizeResponse);
        });
      } else {
        print('Failed to load alter/customize requests');
      }
    } catch (error) {
      print('Error fetching alter/customize requests: $error');
    }
  }

  Future<void> fetchCustomizeRequests() async {
    final email = CurrentState.email;
    final customizeUrl = '$apiUrl/customize_clothes/$email';

    try {
      final response = await http.get(Uri.parse(customizeUrl));
      if (response.statusCode == 200) {
        final List<dynamic> customizeResponse = json.decode(response.body);
        setState(() {
          alterCustomizeItems.addAll(List<Map<String, dynamic>>.from(customizeResponse));
        });
      } else {
        print('Failed to load customize requests');
      }
    } catch (error) {
      print('Error fetching customize requests: $error');
    }
  }

  Future<void> fetchCartItems() async {
    final email = CurrentState.email;
    final cartUrl = '$apiUrl/cart/product-null/$email';

    try {
      final response = await http.get(Uri.parse(cartUrl));
      if (response.statusCode == 200) {
        final List<dynamic> cartItemsResponse = json.decode(response.body);
        for (var item in cartItemsResponse) {
          final fabricId = item['fabric_id'];
          final quantity = item['quantity'];
          if (fabricId != null) {
            fetchFabricDetails(fabricId, quantity);
          }
        }
      } else {
        print('Failed to load cart items');
      }
    } catch (error) {
      print('Error fetching cart items: $error');
    }
  }

  Future<void> fetchFabricDetails(int fabricId, int quantity) async {
    final fabricUrl = '$apiUrl/fabric/$fabricId';

    try {
      final response = await http.get(Uri.parse(fabricUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> fabricDetails = json.decode(response.body);
        fabricDetails['quantity'] = quantity;
        setState(() {
          cartItems.add(fabricDetails);
        });
      } else {
        print('Failed to load fabric details');
      }
    } catch (error) {
      print('Error fetching fabric details: $error');
    }
  }

  Future<void> fetchDressItems() async {
    final email = CurrentState.email;
    final dressCartUrl = '$apiUrl/cart/fabric-null/$email';

    try {
      final response = await http.get(Uri.parse(dressCartUrl));
      if (response.statusCode == 200) {
        final List<dynamic> dressCartItems = json.decode(response.body);
        for (var item in dressCartItems) {
          final productId = item['product_id'];
          final quantity = item['quantity'];
          if (productId != null) {
            fetchProductDetails(productId, quantity);
          }
        }
      } else {
        print('Failed to load dress items');
      }
    } catch (error) {
      print('Error fetching dress items: $error');
    }
  }

  Future<void> clearCart() async {
    final email = CurrentState.email;
    final clearCartUrl = '$apiUrl/cart/clear/$email';
    final clearAlterUrl = '$apiUrl/alter_clothes/$email';  // New URL to clear alter requests
    final clearCustomizeUrl = '$apiUrl/customize_clothes/$email'; // New URL to clear customize requests

    try {
      // Clear cart items
      final cartResponse = await http.delete(Uri.parse(clearCartUrl));
      if (cartResponse.statusCode == 200) {
        print('Cart cleared successfully');
      } else {
        print('Failed to clear cart: ${cartResponse.body}');
      }

      // Clear alter requests
      final alterResponse = await http.delete(Uri.parse(clearAlterUrl));
      if (alterResponse.statusCode == 200) {
        print('Alter requests cleared successfully');

      } else {
        print('Failed to clear alter requests: ${alterResponse.body}');
      }

      // Clear customize requests
      final customizeResponse = await http.delete(Uri.parse(clearCustomizeUrl));
      if (customizeResponse.statusCode == 200) {
        print('Customize requests cleared successfully');
      } else {
        print('Failed to clear customize requests: ${customizeResponse.body}');
      }

      // Update the UI after clearing all records
      setState(() {
        cartItems.clear();
        alterCustomizeItems.clear();
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cart and customization requests cleared successfully'),
      ));
    } catch (error) {
      print('Error clearing cart or requests: $error');
    }
  }


  Future<void> fetchProductDetails(int productId, int quantity) async {
    final productUrl = '$apiUrl/products/$productId';

    try {
      final response = await http.get(Uri.parse(productUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> productDetails = json.decode(response.body);
        productDetails['quantity'] = quantity;
        setState(() {
          cartItems.add(productDetails);
        });
      } else {
        print('Failed to load product details');
      }
    } catch (error) {
      print('Error fetching product details: $error');
    }
  }

  // Function to calculate the total order amount
  double calculateOrderTotal() {
    double total = 0.0;

    // Calculate total for cart items
    for (var item in cartItems) {
      double price = item['price'] ?? 0.0; // Assume price is available in fabric/product details
      int quantity = item['quantity'] ?? 0;
      total += price * quantity; // Multiply price by quantity
    }

    // Add charges for alter requests
    total += 150 * alterCustomizeItems.length; // 150 Rs for each alter request

    // Add charges for customize requests
    total += 150 * alterCustomizeItems.length; // 150 Rs for each customize request

    return total;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total
    double orderTotal = 0.0;

    // Calculate total cost of fabrics and dresses
    for (var item in cartItems) {
      if (item['price'] != null && item['quantity'] != null) {
        orderTotal += (item['price'] as num).toDouble() * (item['quantity'] as num);
      }
    }

    // Add costs for alter and customize requests
    orderTotal += 150 * alterCustomizeItems.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: cartItems.isEmpty && alterCustomizeItems.isEmpty
          ? EmptyCartUI(onExplore: () {
        Navigator.pushNamed(context, '/dresscollection');
      }) // Show empty cart UI if both cart and alter/customize items are empty
          : RefreshIndicator(
        onRefresh: refreshCart, // Calls refreshCart when user pulls down
        child: ListView(
          children: [
            // Display cart items (fabrics and dresses)
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: cartItems.length,
              itemBuilder: (context, index) {


                return CartItem(fabric: cartItems[index]);
              },
            ),
            // Display alter/customize requests
            if (alterCustomizeItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Alter/Customize Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: alterCustomizeItems.length,
              itemBuilder: (context, index) {

                return AlterCustomizeItem(alterRequest: alterCustomizeItems[index]);
              },
            ),
            // Horizontal line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Divider(thickness: 2, height: 32),
            ),
            // Order Total
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${orderTotal.toStringAsFixed(0)} Rs.', // Display calculated total
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Make Order button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: RoundedButton(
                onTap: () {
                  clearCart(); // Clear the cart, alter, and customize records
                  refreshCart(); // Refresh the cart to update UI
                },
                title: 'Make Payment',
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
