import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/widgets/rounded_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utility.dart';

class OrderFabricScreen extends StatefulWidget {
  final int fabricId; // Add fabricId parameter

  const OrderFabricScreen({Key? key, required this.fabricId}) : super(key: key);

  @override
  State<OrderFabricScreen> createState() => _OrderFabricScreenState();
}

class _OrderFabricScreenState extends State<OrderFabricScreen> {
  int quantity = 0; // Change value to quantity
  late String fabricName;
  late String fabricImage;
  late String fabricDescription;
  late double fabricPrice;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    print('Fabric ID: ${widget.fabricId}');
    fetchFabricDetails(widget.fabricId); // Use fabricId from constructor
  }

  Future<void> fetchFabricDetails(int fabricId) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/fabric/${widget.fabricId}'));
      if (response.statusCode == 200) {
        final fabricData = json.decode(response.body);
        setState(() {
          fabricName = fabricData['name'];
          fabricImage = fabricData['image'];
          fabricDescription = fabricData['decription']; // Use 'decription' as in the API response
          fabricPrice = fabricData['cost'].toDouble();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load fabric details. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching fabric details: $e';
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
      appBar: AppBar(title: Text('Order Fabric')),
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
              Image.network(fabricImage, width: MediaQuery.of(context).size.width, fit: BoxFit.cover),
              SizedBox(height: 5.0),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text("Price per unit: ${fabricPrice.toStringAsFixed(2)}", style: TextStyle(color: Colors.grey, fontSize: 16.0)),
              ]),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fabricName, style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 20.0)),
                  quantityManager(),
                ],
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      fabricDescription,
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
                    print('Sending request to add fabric to cart with:');
                    print('Email: ${CurrentState.email}');
                    print('Fabric ID: ${widget.fabricId}');
                    print('Quantity: $quantity');

                    final response = await http.post(
                      Uri.parse('$apiUrl/cart/add'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'email': '${CurrentState.email}', // Replace with actual user email
                        'fabric_id': widget.fabricId, // Use fabric_id instead of product_id
                        'quantity': quantity,
                      }),
                    );

                    print('Response status: ${response.statusCode}');
                    print('Response body: ${response.body}');

                    if (response.statusCode == 201) {
                      // Item added successfully
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fabric added to cart!')),
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
          Text("$quantity", style: TextStyle(color: Colors.white)),
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
