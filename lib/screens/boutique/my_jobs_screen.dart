import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/screens/chat_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MyJobsScreen extends StatefulWidget {
  @override
  _MyJobsScreenState createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  List<dynamic> myJobs = [];
  bool isLoading = true;
  final List<String> progressOptions = ['0%', '10%', '20%', '30%', '40%', '50%', '60%', '70%', '80%', '90%', '100%'];

  @override
  void initState() {
    super.initState();
    fetchMyJobs();
  }

  Future<void> fetchMyJobs() async {
    try {
      if (CurrentState.email.isEmpty) await getUserDetails();
      final response = await http.get(Uri.parse('$apiUrl/orders/boutique/${CurrentState.email}'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            myJobs = jsonDecode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { isLoading = false; });
      }
    } catch (e) {
      print('Error fetching jobs: $e');
      if (mounted) setState(() { isLoading = false; });
    }
  }

  Future<void> updateProgress(String orderId, String newProgress) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/orders/progress'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'progress': newProgress})
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Progress Updated!")));
        fetchMyJobs(); // Refresh
      }
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  Future<void> acceptJob(String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/orders/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId, 'boutique_email': CurrentState.email})
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Accepted!")));
        fetchMyJobs();
      }
    } catch (e) {
      print('Error accepting job: $e');
    }
  }

  void showRejectDialog(String orderId) {
    TextEditingController _reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text("Reject Job", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to reject this job?"),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Job Rejected!")));
                  fetchMyJobs();
                }
              } catch (e) {
                print('Error rejecting job: $e');
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
    final receivedJobs = myJobs.where((j) => j['status'] == 'Pending').toList();
    final ongoingJobs = myJobs.where((j) => j['status'] == 'Accepted' && (j['progress'] ?? '0%') != '100%').toList();
    final completedJobs = myJobs.where((j) => j['status'] == 'Completed' || (j['status'] == 'Accepted' && (j['progress'] ?? '') == '100%')).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(bottom: 70),
                  title: const Text(
                    'My Stitching Jobs',
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
                        'assets/images/fabric_cotton.jpg',
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
                bottom: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                  isScrollable: true,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('NEW'),
                          if (receivedJobs.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text('(${receivedJobs.length})', style: const TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('DOING'),
                          if (ongoingJobs.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text('(${ongoingJobs.length})', style: const TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('DONE'),
                          if (completedJobs.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text('(${completedJobs.length})', style: const TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : TabBarView(
                  children: [
                    buildJobList(receivedJobs, 'No new received job requests.', Icons.inbox_outlined),
                    buildJobList(ongoingJobs, 'No ongoing stitching jobs.', Icons.handyman_outlined),
                    buildJobList(completedJobs, 'No completed jobs yet.', Icons.task_alt),
                  ],
                ),
        ),
      ),
    );
  }

  Widget buildJobList(List<dynamic> jobs, String emptyMessage, IconData emptyIcon) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 1.1),
              ),
            ],
          ).animate().fade(duration: 600.ms).slideY(begin: 0.1),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: fetchMyJobs,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 100),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          final String progressStr = job['progress'] ?? '0%';
          final int progressVal = int.tryParse(progressStr.replaceAll('%', '')) ?? 0;

          bool isPending = job['status'] == 'Pending';
          bool isCompleted = job['status'] == 'Completed' || progressVal == 100;
          
          Color statusColor = isPending ? Colors.orange : (isCompleted ? Colors.green : Colors.blue);
          String statusText = isPending ? 'PENDING' : (isCompleted ? 'COMPLETED' : 'ONGOING');

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
                // Thumbnail header for visual flair
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    image: const DecorationImage(
                      image: AssetImage('assets/images/fabric_denim.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${job['type']} - ${job['category']}'.toUpperCase(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.numbers, size: 16, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text('Order ID: ${job['order_id']}', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text('${job['customer_email']}', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        ],
                      ),
                      if (job['description'] != null && job['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          '${job['description']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5, fontStyle: FontStyle.italic),
                        ),
                      ],

                      // Action views based on status
                      if (isPending) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.black12),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () => showRejectDialog(job['order_id']),
                                child: const Text("REJECT", style: TextStyle(letterSpacing: 1.5)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () => acceptJob(job['order_id']),
                                child: const Text("ACCEPT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ] else if (job['status'] == 'Accepted' || isCompleted) ...[
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: progressVal / 100,
                          backgroundColor: Colors.grey[200],
                          color: isCompleted ? Colors.green : Colors.black,
                          minHeight: 4,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!isCompleted)
                              Row(
                                children: [
                                  const Text('PROGRESS: ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                                  DropdownButton<String>(
                                    value: progressOptions.contains(progressStr) ? progressStr : '0%',
                                    underline: Container(),
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    items: progressOptions.map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        updateProgress(job['order_id'], newValue);
                                      }
                                    },
                                  ),
                                ],
                              )
                            else
                              Text('FINISHED', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      orderId: job['order_id'],
                                      senderEmail: CurrentState.email,
                                      receiverTitle: job['customer_email'] ?? 'Customer',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('CHAT', style: TextStyle(fontSize: 12, letterSpacing: 1)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 500.ms, delay: (50 * index).ms).slideY(begin: 0.1);
        },
      ),
    );
  }
}
