import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';
import 'dart:convert';
import 'package:tailor_app/widgets/rounded_button.dart';

class OrderDressScreen extends StatefulWidget {
  final int dressId; // Dress ID parameter

  const OrderDressScreen({super.key, required this.dressId});

  @override
  State<OrderDressScreen> createState() => _OrderDressScreenState();
}

class _OrderDressScreenState extends State<OrderDressScreen> {
  int quantity = 0;
  Map<String, dynamic>? dressDetails; // Store dress details
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('Dress Id To fetch: ${widget.dressId}');
    fetchDressDetails();
  }

  Future<void> fetchDressDetails() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/products/${widget.dressId}'));
      if (response.statusCode == 200) {
        setState(() {
          dressDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load dress details. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching dress details: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildUI();
  }

  Widget buildUI() {
    return Scaffold(
      appBar: AppBar(title: Text('Order Dress')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(dressDetails!["image"], fit: BoxFit.contain),
              SizedBox(height: 5.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Price per unit: ${dressDetails!["cost"]} Rs.",
                    style: TextStyle(color: Colors.grey, fontSize: 16.0),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dressDetails!["name"],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      fontSize: 20.0,
                    ),
                  ),
                  quantityManager(),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      dressDetails!["decription"], // Ensure this matches your response
                      style: TextStyle(fontSize: 16),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.0),
          RoundedButton(
            onTap: () async {
              if (quantity > 0) {
                print('Sending request to add to cart with:');
                print('Email: ${CurrentState.email}');
                print('Product ID: ${widget.dressId}');
                print('Quantity: $quantity');

                final response = await http.post(
                  Uri.parse('$apiUrl/cart/add'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({
                    'email': '${CurrentState.email}', // Replace with actual user email
                    'product_id': widget.dressId, // Use the product_id from dress details
                    'quantity': quantity,
                  }),
                );

                print('Response status: ${response.statusCode}');
                print('Response body: ${response.body}');

                if (response.statusCode == 201) {
                  // Item added successfully
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item added to cart!')),
                  );
                } else {
                  // Handle errors
                  final errorMessage = json.decode(response.body)['message'] ?? 'Failed to add to cart';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              } else {
                // Show a message if quantity is zero
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a quantity')),
                );
              }
            },
            title: 'Add to cart',
          ),

          ],
          ),
        ),
      ),
    );
  }

  Widget quantityManager() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        color: Colors.red,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                quantity += 1; // Increase quantity
              });
            },
            child: Icon(Icons.add, color: Colors.white),
          ),
          SizedBox(width: 12.0),
          Text(
            "$quantity",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 12.0),
          InkWell(
            onTap: () {
              setState(() {
                if (quantity > 0) {
                  quantity -= 1; // Decrease quantity if greater than 0
                }
              });
            },
            child: Icon(Icons.remove, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
