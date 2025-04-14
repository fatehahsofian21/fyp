import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'result.dart'; // Import ResultScreen
import 'history.dart'; // Import HistoryScreen
import 'profile.dart'; // Import ProfileScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = "User"; // Default value for user's name
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

  // Fetch the user's name from Firebase
  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        String fullName = userDoc["name"] ?? "User"; // Get full name or default to "User"
        String firstName = fullName.split(" ")[0]; // Extract first name

        setState(() {
          _userName = firstName; // Set the first name
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print("No user logged in.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching user name: $e");
    }
  }

  // Pick image from gallery or camera
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
    }
  }

  // Show bottom sheet for image source selection
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

  // Start scan process
  void _startScan() {
    if (_selectedImage != null && _base64Image != null) {
      final detectionResults = {
        "Basal Cell Carcinoma": 0.95,
        "Squamous Cell Carcinoma": 0.05,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            base64Image: _base64Image!,
            detectionResults: detectionResults,
            onRetry: _resetImage,
          ),
        ),
      ).then((_) {
        setState(() {
          _hasScannedBefore = true;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image first!")),
      );
    }
  }

  // Reset the selected image
  void _resetImage() {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });
  }

  // Handle BottomNavigationBar taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to Profile screen when profile tab is tapped
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(), // Navigate to ProfileScreen
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: const Color(0xFF2F4858),
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0, top: 45),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/a.png', width: 50),
                    const SizedBox(width: 0),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Welcome back, $_userName!", // Display first name
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.diamond_outlined, color: Colors.white, size: 22),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text("Click to upload photo", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: 160,
              height: 40,
              child: ElevatedButton(
                onPressed: _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6C3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _hasScannedBefore ? "RESCAN" : "START SCAN",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white.withOpacity(0.2),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"), // Added Profile
        ],
      ),
    );
  }
}
