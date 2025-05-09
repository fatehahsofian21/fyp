import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import 'home.dart';
import 'hospitals.dart';

class ResultScreen extends StatelessWidget {
  final String base64Image;
  final List<Map<String, dynamic>> detectionResults; // Updated type
  final VoidCallback onRetry;

  const ResultScreen({
    super.key,
    required this.base64Image,
    required this.detectionResults, // Updated type
    required this.onRetry,
  });

  final String googleApiKey = 'AIzaSyDvOiL5Yc2riuilz2KtovXeaqSzLWGk7CE';

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
      }
    } catch (e) {
      print("Error saving to Firebase: $e");
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error('Location permission denied');
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  Future<List<Map<String, dynamic>>> _fetchNearbyHospitals(
      double lat, double lon) async {
    final radiusInMeters = 20000;
    final String nearbyUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lon'
        '&radius=$radiusInMeters'
        '&type=hospital'
        '&key=$googleApiKey';

    final response = await http.get(Uri.parse(nearbyUrl));
    if (response.statusCode != 200) {
      return [
        {"name": "Error fetching hospitals."}
      ];
    }

    final data = json.decode(response.body);
    if (data['results'] == null || data['results'].isEmpty) {
      return [
        {"name": "No hospitals found within 20km."}
      ];
    }

    List<Map<String, dynamic>> results = [];

    for (var hospital in data['results']) {
      final name = hospital['name'].toString().toLowerCase();
      final lat2 = hospital['geometry']['location']['lat'];
      final lon2 = hospital['geometry']['location']['lng'];
      final distance = _calculateDistance(lat, lon, lat2, lon2);

      bool isAcceptable = (name.contains('hospital') ||
              name.contains('clinic') ||
              name.contains('klinik') ||
              name.contains('medical center') ||
              name.contains('pharmacy')) &&
          !(name.contains('spa') ||
              name.contains('esthetic') ||
              name.contains('facial') ||
              name.contains('beauty') ||
              name.contains('salon'));

      if (distance <= 20 && isAcceptable) {
        results.add({
          'name': hospital['name'],
          'distance': distance,
          'place_id': hospital['place_id'],
        });
      }
    }

    results.sort((a, b) => a['distance'].compareTo(b['distance']));

    return results.take(3).toList();
  }

  Future<String> _fetchPhoneNumber(String placeId) async {
    final String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_phone_number&key=$googleApiKey';

    final response = await http.get(Uri.parse(detailsUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null &&
          data['result']['formatted_phone_number'] != null) {
        return data['result']['formatted_phone_number'];
      }
    }
    return "Phone number not available.";
  }

  Future<void> _getLocationAndFetchHospital(BuildContext context) async {
    try {
      final pos = await _getCurrentLocation();
      final hospitals =
          await _fetchNearbyHospitals(pos.latitude, pos.longitude);

      // Loading screen while fetching phone numbers asynchronously
      showDialog(
        context: context,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Fetch phone numbers for each hospital asynchronously
      for (var hospital in hospitals) {
        final phoneNumber = await _fetchPhoneNumber(hospital['place_id']);
        hospital['phone'] = phoneNumber;
      }

      Navigator.pop(context); // Remove loading dialog

      // Navigate to hospitals screen with updated hospital data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HospitalsScreen(nearestHospitals: hospitals),
        ),
      );
    } catch (e) {
      print("Location or fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        title: const Text("Scan Result", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2F4858),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
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
                  color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Image.memory(base64Decode(base64Image), width: 200, height: 200),
            const SizedBox(height: 20),
            detectionResults.isNotEmpty
                ? Column(
                    children: detectionResults.map((result) {
                      final boundingBox = result['bounding_box'];
                      final classId = result['class_id'];
                      final confidence = result['confidence'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          "Class ID: $classId\n"
                          "Confidence: ${(confidence * 100).toStringAsFixed(2)}%\n"
                          "Bounding Box: [${boundingBox[0]}, ${boundingBox[1]}, ${boundingBox[2]}, ${boundingBox[3]}]",
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  )
                : const Text(
                    "No detections found.",
                    style: TextStyle(color: Colors.white),
                  ),
            const SizedBox(height: 30),
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
            SizedBox(
              width: 160,
              height: 40,
              child: ElevatedButton(
                onPressed: () => _getLocationAndFetchHospital(context),
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
                    'detections':
                        detectionResults, // Save the entire list of detections
                  });
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
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
      ),
    );
  }
}
