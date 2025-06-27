import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart'; // Correctly import your LoginScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "User";
  String _email = "";
  String _phone = "+60-123456789"; // Random phone number starting with +60
  String _gender = "Male"; // Default gender
  File? _selectedImage;

  bool _isLoading = true;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadStoredData(); // Load stored data
  }

  // Fetch user profile from Firebase (only email)
  Future<void> _fetchUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? "";
        _userName = _email
            .split('@')[0]; // Extract the first name from email (before @)
        _phone =
            "+60-${_generateRandomPhoneNumber()}"; // Generate random phone number
        _isLoading = false;
      });
    }
  }

  // Generate a random phone number starting with +60-
  String _generateRandomPhoneNumber() {
    Random random = Random();
    String randomDigits =
        List.generate(8, (index) => random.nextInt(10).toString()).join('');
    return randomDigits;
  }

  // Pick image logic (optional)
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Save the user information to SharedPreferences
  Future<void> _saveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('phone', _phone);
    prefs.setString('gender', _gender);
  }

  // Load the user information from SharedPreferences
  Future<void> _loadStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _phone = prefs.getString('phone') ??
          "+60-123456789"; // Default phone if none saved
      _gender =
          prefs.getString('gender') ?? "Male"; // Default gender if none saved
    });
  }

  // Logout function
  void _logout() {
    FirebaseAuth.instance.signOut(); // Sign out from Firebase
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => const LoginScreen()), // Navigate to LoginScreen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFFE3F0FF), // Match other pages
        foregroundColor: const Color(0xFF223A5E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFE3F0FF), // Match other pages
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color:
                          Colors.transparent, // No white, blend with wallpaper
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB6D0E2)
                              .withOpacity(0.25), // Soft blue shadow
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                            child: _selectedImage == null
                                ? const Icon(Icons.camera_alt, size: 40)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Name, Email, Phone, Gender (as before)
                        Text(
                          'Name: $_userName',
                          style: const TextStyle(
                              fontSize: 18, color: Color(0xFF223A5E)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Email: $_email',
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF223A5E)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Color(0xFF223A5E)),
                            const SizedBox(width: 8),
                            Text(
                              'Phone: $_phone',
                              style: const TextStyle(
                                  fontSize: 16, color: Color(0xFF223A5E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.transgender,
                                color: Color(0xFF223A5E)),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _gender,
                              dropdownColor: const Color(0xFFF5FAFF),
                              style: const TextStyle(color: Color(0xFF223A5E)),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _gender = newValue!;
                                });
                                _saveUserData();
                              },
                              items: <String>[
                                'Male',
                                'Female'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: const TextStyle(
                                          color: Color(0xFF223A5E))),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Logout Button (as before)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "LOGOUT",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
