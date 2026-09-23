import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/services/token_storage.dart';
import 'package:tailor_app/screens/my_accepted_applications.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ApplicationsReceivedScreen extends StatefulWidget {
  @override
  _ApplicationsReceivedScreenState createState() => _ApplicationsReceivedScreenState();
}

class _ApplicationsReceivedScreenState extends State<ApplicationsReceivedScreen> {
  List<dynamic> applications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/applications'));
      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> applicationList = json.decode(response.body);
        setState(() {
          applications = applicationList.map((application) {
            return {
              'tailorName': application['name'] ?? '',
              'tailorAddress': application['address'] ?? '',
              'tailorContact': application['phone_number'] ?? '',
              'vacancyId': application['Vacancy_id']?.toString() ?? '',
              'email': application['email']?.toString() ?? '',
              'status': application['status'] ?? 'Pending',
              'completed_jobs': application['completed_jobs'],
              'rating': application['rating'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch applications: ${json.decode(response.body)['message']}')),
        );
        setState(() { isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching applications: $e')),
      );
      setState(() { isLoading = false; });
    }
  }

  Future<void> updateApplicationStatus(String vacancyId, String email, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/applications/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Vacancy_id': vacancyId, 'email': email, 'status': status}),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application status updated to $status'),
            backgroundColor: status == 'Accepted' ? Colors.black : Colors.red,
          ),
        );
        fetchApplications(); // Refresh the application list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update application: ${json.decode(response.body)['message']}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating application: $e')),
      );
    }
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
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) {
                    return MyAcceptedApplicationsScreen();
                  }));
                },
                icon: const Icon(Icons.people_outline, color: Colors.black),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () {
                  var result = TokenStorage.clearToken();
                  if (result != null) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Applicants',
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
                    'assets/images/intro2.jpeg',
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
                : applications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                "No applications yet.",
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
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          return buildApplicationItem(applications[index], context, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget buildApplicationItem(Map<String, dynamic> application, BuildContext context, int index) {
    bool isAccepted = application['status'] == 'Accepted';
    bool isRejected = application['status'] == 'Rejected';

    return GestureDetector(
      onTap: () => _showTailorProfile(application),
      child: Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black,
                  child: Text(
                    application['tailorName'].toString().isNotEmpty ? application['tailorName'][0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application['tailorName'] ?? 'Unknown Tailor',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'VACANCY ID: ${application['vacancyId']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.black54, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(application['tailorAddress'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, color: Colors.black54, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(application['tailorContact'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14))),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isAccepted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Text('ACCEPTED', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                  ),
                ] else if (isRejected) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: const Text('REJECTED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        updateApplicationStatus(application['vacancyId']!, application['email']!, 'Rejected');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black12),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('REJECT', style: TextStyle(fontSize: 12, letterSpacing: 1.5)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        updateApplicationStatus(application['vacancyId']!, application['email']!, 'Accepted');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text('ACCEPT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    ).animate().fade(duration: 500.ms, delay: (50 * index).ms).slideY(begin: 0.1);
  }

  void _showTailorProfile(Map<String, dynamic> application) {
    String tailorEmail = application['email'] ?? '';
    
    // Read the actual completed jobs and rating injected by the backend API
    int jobsDone = application['completed_jobs'] ?? 0;
    double rating = (application['rating'] ?? 0.0).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  child: Text(
                    application['tailorName'].toString().isNotEmpty ? application['tailorName'][0].toUpperCase() : 'T',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  application['tailorName'] ?? 'Unknown Tailor',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  application['email'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Rating', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Column(
                      children: [
                        const Text('Jobs Done', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.work_outline, color: Colors.black54, size: 20),
                            const SizedBox(width: 4),
                            Text('$jobsDone', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.black54, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(application['tailorAddress'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, color: Colors.black54, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(application['tailorContact'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: const Text('CLOSE PROFILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
