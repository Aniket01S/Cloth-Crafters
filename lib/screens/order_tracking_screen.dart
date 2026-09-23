import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/screens/chat_screen.dart';
import 'package:tailor_app/screens/boutique_detail_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      if (CurrentState.email.isEmpty) await getUserDetails();
      final email = CurrentState.email;
      
      final response = await http.get(Uri.parse('$apiUrl/orders/customer/$email'));
      if (response.statusCode == 200) {
        setState(() {
          orders = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() { isLoading = false; });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Tracking')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text("No orders found."))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    int progressVal = int.tryParse(order['progress'].toString().replaceAll('%', '')) ?? 0;
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${order['type']} - ${order['category']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order['status'] == 'Pending' ? Colors.orange[100] : (order['status'] == 'Rejected' ? Colors.red[100] : Colors.green[100]),
                                    borderRadius: BorderRadius.circular(12)
                                  ),
                                  child: Text(order['status'], style: TextStyle(color: order['status'] == 'Pending' ? Colors.orange[800] : (order['status'] == 'Rejected' ? Colors.red[800] : Colors.green[800]))),
                                )
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('Order ID: ${order['order_id']}', style: TextStyle(color: Colors.grey[700])),
                            if (order['description'] != null) ...[
                              SizedBox(height: 4),
                              Text('Details: ${order['description']}', style: TextStyle(color: Colors.grey[700])),
                            ],
                            if (order['status'] == 'Rejected') ...[
                              SizedBox(height: 16),
                              Text('This order was rejected by the boutique.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              if (order['reject_reason'] != null && order['reject_reason'].toString().isNotEmpty)
                                Text('Reason: ${order['reject_reason']}', style: TextStyle(color: Colors.red[800], fontStyle: FontStyle.italic)),
                            ] else ...[
                              SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: progressVal / 100,
                                backgroundColor: Colors.grey[200],
                                color: Colors.green,
                                minHeight: 8,
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            orderId: order['order_id'],
                                            senderEmail: CurrentState.email,
                                            receiverTitle: 'Boutique',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.chat, size: 16),
                                    label: Text('Chat', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                  if (order['boutique_email'] != null && order['boutique_email'].toString().isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BoutiqueDetailScreen(
                                              provider: {
                                                'email': order['boutique_email'],
                                                'username': order['boutique_name'] ?? 'Boutique',
                                                'user_type': 'Boutique',
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.star, color: Colors.amber, size: 16),
                                      label: Text('Rate & Review', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                  Text('${order['progress']} Completed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700], fontSize: 12)),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
