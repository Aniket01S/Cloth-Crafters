import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/screens/chat_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OpenOrdersScreen extends StatefulWidget {
  @override
  _OpenOrdersScreenState createState() => _OpenOrdersScreenState();
}

class _OpenOrdersScreenState extends State<OpenOrdersScreen> {
  List<dynamic> openOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOpenOrders();
  }

  Future<void> fetchOpenOrders() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/orders/open'));
      if (response.statusCode == 200) {
        setState(() {
          openOrders = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print('Error fetching open orders: $e');
      setState(() { isLoading = false; });
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      if (CurrentState.email.isEmpty) await getUserDetails();
      final response = await http.put(
        Uri.parse('$apiUrl/orders/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'boutique_email': CurrentState.email})
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Accepted!")));
        fetchOpenOrders(); // Refresh
      }
    } catch (e) {
      print('Error accepting order: $e');
    }
  }

  Future<void> showRejectDialog(String orderId) async {
    TextEditingController _reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Reject Request", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to reject this request?"),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: "Reason for rejection (Optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
              maxLines: 3,
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.put(
                  Uri.parse('$apiUrl/orders/reject'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'order_id': orderId, 'reject_reason': _reasonController.text.trim()})
                );
                if (!mounted) return;
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Rejected!")));
                  fetchOpenOrders();
                }
              } catch (e) {
                print('Error rejecting order: $e');
              }
            },
            child: const Text("Reject", style: TextStyle(letterSpacing: 1.5)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Open Requests',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/fabric_yarn.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.9), Colors.transparent, Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator(color: Colors.black)),
                  )
                : openOrders.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.style_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "No open requests.",
                                style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 1.1),
                              ),
                            ],
                          ).animate().fade(duration: 600.ms).slideY(begin: 0.1),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 100),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: openOrders.length,
                        itemBuilder: (context, index) {
                          final order = openOrders[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card Header Image (Thumbnail)
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    image: const DecorationImage(
                                      image: AssetImage('assets/images/fabric_pinksilk.webp'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${order['type']} - ${order['category']}'.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${order['customer_email']}',
                                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      if (order['description'] != null && order['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          '${order['description']}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatScreen(
                                                      orderId: order['order_id'],
                                                      senderEmail: CurrentState.email,
                                                      receiverTitle: order['customer_email'] ?? 'Customer',
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                side: const BorderSide(color: Colors.black12),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              child: const Icon(Icons.chat_bubble_outline, size: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              onPressed: () => showRejectDialog(order['order_id']),
                                              child: const Text(
                                                'REJECT',
                                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                elevation: 0,
                                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                              ),
                                              onPressed: () => acceptOrder(order['order_id']),
                                              child: const Text(
                                                'ACCEPT',
                                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fade(duration: 500.ms, delay: (50 * index).ms).slideY(begin: 0.1);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
