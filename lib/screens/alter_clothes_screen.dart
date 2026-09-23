import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailor_app/screens/search_tailor_screen.dart';
import 'package:tailor_app/utility.dart';
import 'dart:convert';
import 'package:tailor_app/widgets/rounded_button.dart';
import 'package:tailor_app/constants.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AlterClothesScreen extends StatefulWidget {
  @override
  _AlterClothesScreenState createState() => _AlterClothesScreenState();
}

class _AlterClothesScreenState extends State<AlterClothesScreen> {
  String selectedCategory = 'Jeans';
  List<String> categories = ['Jeans', 'Top', 'Shirt', 'Western', 'Others'];
  late BuildContext curr;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _previousText = '';
  String? selectedBoutiqueEmail;
  List<dynamic> providers = [];

  @override
  void initState() {
    super.initState();
    fetchProviders();
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

  Future<void> fetchProviders() async {
    try {
      if (CurrentState.email.isNotEmpty && CurrentState.address.isEmpty) {
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

      final tRes = await http.get(Uri.parse('$apiUrl/tailors'));
      final bRes = await http.get(Uri.parse('$apiUrl/boutiques'));
      if (tRes.statusCode == 200 && bRes.statusCode == 200) {
        final List<dynamic> tList = jsonDecode(tRes.body);
        final List<dynamic> bList = jsonDecode(bRes.body);
        final String userLoc = CurrentState.userLocationOrCity;
        final all = [...tList, ...bList];
        final unique = [];
        final seen = <String>{};
        for (var p in all) {
          final e = p['email'];
          final addr = (p['address'] ?? '').toString();
          if (e != null && e.toString().isNotEmpty && !seen.contains(e)) {
            if (userLoc.isEmpty || _isMatchingLocation(userLoc, addr)) {
              seen.add(e);
              unique.add(p);
            }
          }
        }
        if (mounted) {
          setState(() {
            providers = unique;
          });
        }
      }
    } catch (e) {
      print('Error fetching providers: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _previousText = _messageController.text;
        });
        _speech.listen(
          onResult: (val) {
            if (mounted) {
              setState(() {
                String newText = _previousText;
                if (newText.isNotEmpty && !newText.endsWith(' ')) newText += ' ';
                newText += val.recognizedWords;
                _messageController.text = newText;
              });
            }
          },
        );
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _uploadAlterClothes() async {
    final uri = Uri.parse('$apiUrl/alter_clothes');
    final request = http.MultipartRequest('POST', uri)
      ..fields['email'] = CurrentState.email // Replace with actual email
      ..fields['category'] = selectedCategory
      ..fields['description'] = _messageController.text;

    if (selectedBoutiqueEmail != null) {
      request.fields['boutique_email'] = selectedBoutiqueEmail!;
    }

    if (_selectedImage != null) {
      final imageStream = http.ByteStream(_selectedImage!.openRead());
      final imageLength = await _selectedImage!.length();
      final imageFile = http.MultipartFile('image', imageStream, imageLength, filename: basename(_selectedImage!.path));
      request.files.add(imageFile);
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString(); // Get the response body as a string

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnackbarMessage(curr, 'Alter request successful!');
        Navigator.pop(curr);
      } else {
        showSnackbarMessage(curr, 'Failed to submit alteration request: ${responseBody}');
      }
    } catch (e) {
      showSnackbarMessage(curr, 'An error occurred: ${e.toString()}');
    }
  }



  @override
  Widget build(BuildContext context) {
    curr=context;
    return Scaffold(
      appBar: AppBar(title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Alter Clothes"),
          InkWell(onTap: (){
            Navigator.push(context, MaterialPageRoute(builder: (_){
              return TailorSearchScreen();
            }));
          },child: Icon(Icons.person_search_rounded),)
        ],
      )),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDropdown('Set category', selectedCategory, categories, (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    }),
                    SizedBox(height: 40),
                    buildImageUploadSection(),
                    SizedBox(height: 20),
                    buildMessageTextField(),
                    SizedBox(height: 20),
                    buildProviderDropdown(),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: RoundedButton(
              title: 'Alter It',
              onTap: () async {
                if (_selectedImage == null || _messageController.text.trim().isEmpty) {
                  // Show error message if no image or description is provided
                  showSnackbarMessage(context, "Please provide necessary details");
                } else {
                  // Post the data
                  await _uploadAlterClothes();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to show the scaffold messenger message
  void showSnackbarMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
      ),
    );
  }


  Widget buildDropdown(String title, String currentValue, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: currentValue,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24,
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            dropdownColor: Colors.white,
            underline: Container(height: 2, color: Colors.transparent),
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Attach your product image",
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _pickImage,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add, size: 30),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 150,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage == null
                      ? Center(child: Text("No image selected"))
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildMessageTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Write your message ...",
          suffixIcon: IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.grey),
            onPressed: _listen,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget buildProviderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Tailor / Boutique (Optional)", style: TextStyle(fontSize: 16)),
        SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedBoutiqueEmail,
            hint: Text("Open for everyone"),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            dropdownColor: Colors.white,
            underline: Container(height: 2, color: Colors.transparent),
            onChanged: (String? newValue) {
              setState(() {
                selectedBoutiqueEmail = newValue;
              });
            },
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text("Open for everyone"),
              ),
              ...providers.map<DropdownMenuItem<String>>((dynamic p) {
                final String name = p['username'] ?? 'Unknown';
                final String email = p['email'] ?? '';
                final String type = p['user_type'] ?? '';
                return DropdownMenuItem<String>(
                  value: email,
                  child: Text("$name ($type)"),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
