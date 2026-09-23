import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/utility.dart';

class BoutiqueDetailScreen extends StatefulWidget {
  final Map<String, dynamic> provider;

  const BoutiqueDetailScreen({super.key, required this.provider});

  @override
  State<BoutiqueDetailScreen> createState() => _BoutiqueDetailScreenState();
}

class _BoutiqueDetailScreenState extends State<BoutiqueDetailScreen> {
  List<dynamic> reviews = [];
  double averageRating = 5.0;
  int totalReviews = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final email = widget.provider['email'] ?? '';
    try {
      final response = await http.get(Uri.parse('$apiUrl/reviews/$email'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            reviews = data['reviews'] ?? [];
            averageRating = (data['average_rating'] as num?)?.toDouble() ?? 5.0;
            totalReviews = data['total_reviews'] ?? 0;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate & Review', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('How was your experience with ${widget.provider['username'] ?? 'this provider'}?'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write your review here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (CurrentState.email.isEmpty) await getUserDetails();
                    try {
                      final response = await http.post(
                        Uri.parse('$apiUrl/reviews/add'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'boutique_email': widget.provider['email'],
                          'customer_email': CurrentState.email,
                          'rating': selectedRating,
                          'comment': commentController.text.trim(),
                        }),
                      );
                      Navigator.pop(context);
                      if (response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Review submitted successfully!'),
                          backgroundColor: Colors.green,
                        ));
                        fetchReviews();
                      } else {
                        final errData = jsonDecode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(errData['error'] ?? 'Failed to submit review'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    } catch (e) {
                      print('Error submitting review: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.provider['username'] ?? widget.provider['email']?.split('@')[0] ?? 'Boutique';
    final String userType = widget.provider['user_type'] ?? 'Boutique';
    final String address = widget.provider['address'] ?? 'Address not provided';
    final String phone = widget.provider['phone_number'] ?? 'Not provided';
    final String providerEmail = (widget.provider['email'] ?? '').toString().toLowerCase();
    final String currentEmail = CurrentState.email.toLowerCase();
    final bool isSelf = currentEmail.isNotEmpty && currentEmail == providerEmail;
    final bool isBoutiqueOrTailor = CurrentState.userType.toLowerCase() == 'boutique' || CurrentState.userType.toLowerCase() == 'tailor';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('$name Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Profile Card
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.red[100],
                    child: Icon(
                      userType == 'Boutique' ? Icons.store : Icons.person,
                      size: 50,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(userType, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 18),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          address,
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, color: Colors.grey[600], size: 18),
                      SizedBox(width: 4),
                      Text(phone, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Rating Summary Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < averageRating.floor() ? Icons.star : Icons.star_half,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      SizedBox(height: 4),
                      Text('$totalReviews reviews', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    child: (isSelf || isBoutiqueOrTailor)
                        ? Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Text(
                              isSelf ? 'Your Profile' : 'Reviews Summary',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _showAddReviewDialog,
                            icon: Icon(Icons.rate_review, size: 18),
                            label: Text('Write a Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Customer Reviews List Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 8),

            isLoading
                ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  )
                : reviews.isEmpty
                    ? Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text('No reviews yet. Be the first to review!')),
                      )
                    : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final rev = reviews[index];
                          final int r = int.tryParse(rev['rating'].toString()) ?? 5;
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rev['customer_name'] ?? 'Customer',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(rev['timestamp'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (starIdx) {
                                    return Icon(
                                      starIdx < r ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                SizedBox(height: 8),
                                Text(rev['comment'] ?? '', style: TextStyle(fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                          );
                        },
                      ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
