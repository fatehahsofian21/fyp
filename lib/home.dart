import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'result.dart';
import 'history.dart';
import 'profile.dart';
import 'premium.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "User";
  bool _isLoading = true;
  File? _selectedImage;
  String? _base64Image;
  bool _hasScannedBefore = false;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        String fullName = userDoc["name"] ?? "User";
        String firstName = fullName.split(" ")[0];

        if (mounted) {
          setState(() {
            _userName = firstName;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        print("No user logged in.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print("Error fetching user name: $e");
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Processing image..."),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      setState(() {
        _selectedImage = imageFile;
        _base64Image = base64Image;
      });

      _showLoadingDialog();
      await _startScan();
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Picture"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _startScan() async {
    if (_selectedImage != null && _base64Image != null) {
      try {
        final url = Uri.parse('http://10.62.55.210:5000/process-image');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'image': _base64Image}),
        );

        debugPrint('response: ${response.body}');

        if (mounted)
          Navigator.of(context).pop(); // <-- Tutup dialog loading DI SINI

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          final List<Map<String, dynamic>> detections =
              List<Map<String, dynamic>>.from(jsonResponse['detections']);

          if (detections.isNotEmpty) {
            detections.sort((a, b) => (b['confidence'] as double)
                .compareTo(a['confidence'] as double));
            final topDetection = detections.first;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(
                  base64Image: _base64Image!,
                  detectionResults: [topDetection],
                  onRetry: _resetImage,
                ),
              ),
            ).then((_) {
              setState(() {
                _hasScannedBefore = true;
              });
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(
                  base64Image: _base64Image!,
                  detectionResults: [],
                  onRetry: _resetImage,
                ),
              ),
            ).then((_) {
              setState(() {
                _hasScannedBefore = true;
              });
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error processing image!")),
            );
          }
          debugPrint('Error: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted)
          Navigator.of(context)
              .pop(); // Pastikan dialog ditutup juga saat error
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to connect to the server!")),
        );
      }
    } else {
      if (mounted)
        Navigator.of(context).pop(); // Pastikan dialog ditutup juga saat error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first!")),
      );
    }
  }

  void _resetImage() {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    }

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HistoryScreen(detectionResults: {}),
        ),
      );
    }

    // Add this for premium (assuming premium icon is index 3)
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a dark blue for text/icons to match baby blue background
    const Color mainTextColor = Color(0xFF223A5E); // Navy/dark blue
    const Color iconColor = Color(0xFF223A5E);

    return Scaffold(
      backgroundColor: const Color(0xFFE3F0FF), // baby blue background
      body: SafeArea(
        child: Column(
          children: [
            // Top: Logo, Welcome text, icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Image.asset(
                    'assets/a.png',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Welcome back, $_userName!",
                      style: const TextStyle(
                        color: mainTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  // Make the diamond icon tappable for premium
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PremiumScreen()),
                      );
                    },
                    child:
                        const Icon(Icons.diamond, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.notifications_none, color: iconColor, size: 26),
                ],
              ),
            ),
            // Center scan area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/home.png',
                          fit: BoxFit.cover,
                          width: 180,
                          height: 180,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        "Snap a photo of your skin to see if it might be skin cancer and get clinic suggestions nearby.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mainTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.upload, color: iconColor),
                          label: const Text(
                            "Upload image",
                            style: TextStyle(
                                color: mainTextColor,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2E6FF),
                            minimumSize: const Size(140, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 18),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: iconColor),
                          label: const Text(
                            "Take picture",
                            style: TextStyle(
                                color: mainTextColor,
                                fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB3D1F6),
                            minimumSize: const Size(140, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFFD2E6FF),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: mainTextColor,
            unselectedItemColor: mainTextColor.withOpacity(0.5),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home, color: iconColor), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history, color: iconColor),
                  label: "History"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person, color: iconColor), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}
