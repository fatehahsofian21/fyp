import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Import Geolocator
import 'home.dart'; // Import HomeScreen
import 'hospitals.dart'; // Import HospitalsScreen
import 'dart:ui'as ui; 

class ResultScreen extends StatelessWidget {
  final String base64Image;
  final Map<String, double> detectionResults;
  final VoidCallback onRetry;

  const ResultScreen({
    Key? key,
    required this.base64Image,
    required this.detectionResults,
    required this.onRetry,
  }) : super(key: key);

  // Function to save results and image to Firebase
  Future<void> _saveToFirebase(Map<String, dynamic> results) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String scanId = DateTime.now().millisecondsSinceEpoch.toString();
        await FirebaseFirestore.instance.collection('scan_results').add({
          'userId': user.uid,
          'scanId': scanId,
          'detectionResults': results,
          'image': results['image'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("Scan result saved to Firebase.");
      }
    } catch (e) {
      print("Error saving scan to Firebase: $e");
    }
  }

  // Function to get the current user's location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check if permission is granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return Future.error('Location permission denied');
      }
    }

    // Get the current position (latitude and longitude)
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // Function to fetch the nearest hospitals using Gemini API
Future<String> _fetchNearestHospitalFromGemini(double latitude, double longitude) async {
  try {
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyBagQghwNUOVdoRg7zwxXfaH-2MT61Pbvs';

    final Map<String, dynamic> generationConfig = {
      'temperature': 1,
      'top_p': 0.95,
      'top_k': 40,
      'max_output_tokens': 8192,
      'response_mime_type': 'text/plain',
    };

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Please provide a list of hospitals within a 20km radius of the following coordinates: latitude: $latitude, longitude: $longitude. List only 5 hospitals. Do not include any extra text or symbols."
            },
            {
              "inlineData": {
                "mimeType": "image/jpeg",
                "data": base64Image, // Send the base64 image here
              }
            }
          ]
        }
      ],
      "generationConfig": generationConfig,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final List<dynamic> parts = data['candidates'][0]['content']['parts'];
        final List<String> hospitals = [];

        // Get only hospital names (ignore extra text)
        for (var part in parts) {
          if (part['text'] != null) {
            final hospitalsText = part['text'].toString().split('\n');
            hospitals.addAll(hospitalsText);
            if (hospitals.length >= 5) break; // Limit to 5 hospitals
          }
        }

        return hospitals.join('\n'); // Return hospital names as a list
      } else {
        return "Error: No valid data returned from the API.";
      }
    } else {
      return "Error fetching nearest hospital data: ${response.statusCode}. ${response.body}";
    }
  } catch (e) {
    print(e);
    return "Error fetching nearest hospital data: $e";
  }
}

  // Function to handle the button click and fetch nearest hospital
  Future<void> _getLocationAndFetchHospital(BuildContext context) async {
    try {
      Position position = await _getCurrentLocation();
      String nearestHospital = await _fetchNearestHospitalFromGemini(position.latitude, position.longitude);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HospitalsScreen(nearestHospital: nearestHospital),
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
      // Handle location error (e.g., show a message)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        title: const Text(
          "Scan Result",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F4858),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Skin Cancer Detected!",
              style: TextStyle(
                color: Colors.green,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: MemoryImage(base64Decode(base64Image)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: detectionResults.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    "${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                SizedBox(
                  width: 160,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      onRetry();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Retry",
                        style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),

                // Nearest Hospitals Button
                SizedBox(
                  width: 160,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      _getLocationAndFetchHospital(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Nearest Hospitals",
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: 160,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveToFirebase({
                        'image': base64Image,
                        'Basal Cell Carcinoma':
                            detectionResults['Basal Cell Carcinoma'],
                        'Squamous Cell Carcinoma':
                            detectionResults['Squamous Cell Carcinoma'],
                      });

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Done",
                        style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
