import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tailor_app/utility.dart';
import 'package:tailor_app/constants.dart';
import 'package:tailor_app/screens/boutique_detail_screen.dart';

class TailorSearchScreen extends StatefulWidget {
  @override
  _TailorSearchScreenState createState() => _TailorSearchScreenState();
}

class _TailorSearchScreenState extends State<TailorSearchScreen> {
  bool isTailorSelected = true;
  List<dynamic> tailorsList = [];
  List<dynamic> boutiquesList = [];
  bool isLoading = true;

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  bool _isMatchingLocation(String userLoc, String targetLoc) {
    if (userLoc.trim().isEmpty) return true;
    if (targetLoc.trim().isEmpty) return false;
    final u = userLoc.toLowerCase();
    final t = targetLoc.toLowerCase();

    if (t.contains(u) || u.contains(t)) return true;

    final ignoreWords = {'near', 'street', 'road', 'nagar', 'colony', 'main', '123', '456'};
    final userTokens = u.split(RegExp(r'[\s,]+')).where((w) => w.length > 2 && !ignoreWords.contains(w));
    final targetTokens = t.split(RegExp(r'[\s,]+')).where((w) => w.length > 2 && !ignoreWords.contains(w));

    for (var uToken in userTokens) {
      for (var tToken in targetTokens) {
        if (uToken == tToken || uToken.contains(tToken) || tToken.contains(uToken)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> fetchData() async {
    try {
      if (CurrentState.email.isNotEmpty) {
        try {
          final pRes = await http.post(
            Uri.parse('$apiUrl/profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': CurrentState.email}),
          );
          if (pRes.statusCode == 200) {
            final pData = jsonDecode(pRes.body);
            if (pData['address'] != null && pData['address'].toString().isNotEmpty) {
              CurrentState.address = pData['address'];
            }
          }
        } catch (_) {}
      }
      if (CurrentState.address.isEmpty && CurrentState.city.isEmpty) {
        await fetchLocationAndCity();
      }

      final tailorsResponse = await http.get(Uri.parse('$apiUrl/tailors'));
      final boutiquesResponse = await http.get(Uri.parse('$apiUrl/boutiques'));
      final String userLoc = CurrentState.userLocationOrCity;

      if (tailorsResponse.statusCode == 200) {
        final List<dynamic> rawTailors = jsonDecode(tailorsResponse.body);
        if (userLoc.isNotEmpty) {
          tailorsList = rawTailors.where((t) => _isMatchingLocation(userLoc, (t['address'] ?? '').toString())).toList();
        } else {
          tailorsList = rawTailors;
        }
      }

      if (boutiquesResponse.statusCode == 200) {
        final List<dynamic> rawBoutiques = jsonDecode(boutiquesResponse.body);
        if (userLoc.isNotEmpty) {
          boutiquesList = rawBoutiques.where((b) => _isMatchingLocation(userLoc, (b['address'] ?? '').toString())).toList();
        } else {
          boutiquesList = rawBoutiques;
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              isTailorSelected ? 'Search Tailors' : 'Search Boutiques',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Active Location Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      CurrentState.userLocationOrCity.isNotEmpty
                          ? "Showing results in: ${CurrentState.userLocationOrCity}"
                          : "Location: Showing all cities",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Toggle buttons for Tailor and Boutique
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isTailorSelected = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isTailorSelected ? Colors.black : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Tailor',
                          style: TextStyle(
                            color: isTailorSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isTailorSelected = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: !isTailorSelected ? Colors.black : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Boutique',
                          style: TextStyle(
                            color: !isTailorSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: isTailorSelected ? 'Search Tailors' : 'Search Boutiques',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Display either Tailor or Boutique based on selection
            Expanded(
              child: isTailorSelected ? buildTailorList() : buildBoutiqueList(),
            ),
          ],
        ),
      ),
    );
  }

  // Tailor List
  Widget buildTailorList() {
    if (isLoading) return Center(child: CircularProgressIndicator());
    final filtered = tailorsList.where((t) {
      if (_searchQuery.isEmpty) return true;
      final name = (t['username'] ?? '').toString().toLowerCase();
      final addr = (t['address'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || addr.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return Center(child: Text("No tailors found in your city"));
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final tailor = filtered[index];
        return buildProviderCard(provider: tailor, isBoutique: false);
      },
    );
  }

  // Boutique List
  Widget buildBoutiqueList() {
    if (isLoading) return Center(child: CircularProgressIndicator());
    final filtered = boutiquesList.where((b) {
      if (_searchQuery.isEmpty) return true;
      final name = (b['username'] ?? '').toString().toLowerCase();
      final addr = (b['address'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || addr.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) return Center(child: Text("No boutiques found in your city"));
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final boutique = filtered[index];
        return buildProviderCard(provider: boutique, isBoutique: true);
      },
    );
  }

  Widget buildProviderCard({required Map<String, dynamic> provider, required bool isBoutique}) {
    final String name = provider['username'] ?? provider['email']?.split('@')[0] ?? 'Provider';
    final String address = provider['address'] ?? 'Not provided';
    final String spec = provider['specialization'] ?? 'Custom Tailoring';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BoutiqueDetailScreen(provider: provider),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.red[50],
              child: Icon(isBoutique ? Icons.store : Icons.person, size: 36, color: Colors.red),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  if (!isBoutique) Text('Specialization: $spec', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  Text('Address: $address', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  SizedBox(height: 4),
                  Text('Tap to view profile & reviews >', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
