import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import 'result.dart'; // Import the result page

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
  bool _hasScannedBefore = false; // Track if user has scanned before

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

        setState(() {
          _userName = firstName;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching user name: $e");
    }
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

  void _startScan() {
    if (_selectedImage != null && _base64Image != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            base64Image: _base64Image!,
            detectionResults: {
              "Basal Cell Carcinoma": 0.95,
              "Squamous Cell Carcinoma": 0.05,
            },
            onRetry: _resetImage, // Clear image when retrying
          ),
        ),
      ).then((_) {
        setState(() {
          _hasScannedBefore =
              true; // Set flag to show "RESCAN" button after returning
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image first!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetImage() {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });
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
                // Left section with logo and greeting
                Row(
                  children: [
                    Image.asset('assets/a.png', width: 50),
                    const SizedBox(width: 0),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Welcome back, $_userName!",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                  ],
                ),
                // Right section with premium and notification icons close to each other
                Row(
                  mainAxisSize:
                      MainAxisSize.min, // Use minimum space to prevent overflow
                  children: [
                    IconButton(
                      icon: const Icon(Icons.diamond_outlined,
                          color: Colors.white, size: 22), // Reduced size
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 24), // Reduced size
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
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.white),
                          SizedBox(height: 10),
                          Text(
                            "Click to upload photo",
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _hasScannedBefore
                      ? "RESCAN"
                      : "START SCAN", // **Dynamically change button text**
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
