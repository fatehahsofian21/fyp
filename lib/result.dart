import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http; // Add this line for HTTP requests
import 'home.dart'; // Import HomeScreen
import 'hospitals.dart'; // Import HospitalsScreen

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

  // Function to fetch the nearest hospital from Gemini API with generation config
  Future<String> _fetchNearestHospitalFromGemini() async {
    try {
      const String apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyBagQghwNUOVdoRg7zwxXfaH-2MT61Pbvs';

      // Generation config settings
      final Map<String, dynamic> generationConfig = {
        'temperature': 1,
        'top_p': 0.95,
        'top_k': 40,
        'max_output_tokens': 8192,
        'response_mime_type': 'text/plain',
      };

      final Map<String, dynamic> requestBody = {
        'messages': [
          {
            'role': 'user',
            'content': 'Please provide the nearest hospital to my location.'
          }
        ],
        'generation_config': generationConfig, // Add the generation config here
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
        print(data);
        return "Nearest Hospital: ${data['choices'][0]['message']['content']}";
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
    String nearestHospital = await _fetchNearestHospitalFromGemini();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalsScreen(nearestHospital: nearestHospital),
      ),
    );
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
