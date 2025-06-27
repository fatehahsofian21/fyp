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
  final List<Map<String, dynamic>> detectionResults;
  final VoidCallback onRetry;

  const ResultScreen({
    super.key,
    required this.base64Image,
    required this.detectionResults,
    required this.onRetry,
  });

  final String googleApiKey = 'AIzaSyDvOiL5Yc2riuilz2KtovXeaqSzLWGk7CE';

  Future<void> _saveToFirebase(Map<String, dynamic> results) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String scanId = DateTime.now().millisecondsSinceEpoch.toString();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scan_results')
            .add({
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
    // Color palette
    const Color backgroundColor = Color(0xFFE3F0FF); // baby blue
    const Color mainTextColor = Color(0xFF223A5E); // navy/dark blue
    const Color cardBlue = Color(0xFFD2E6FF); // light blue for bottom card
    const Color buttonBlue = Color(0xFFB3D1F6); // soft blue
    const Color buttonGreen = Color(0xFF8DC6A7); // soft green
    const Color buttonGrey = Color(0xFFB0B8C1); // soft grey

    final bool hasDetection = detectionResults.isNotEmpty;
    final imageBytes = base64Decode(base64Image);

    // Prepare cancer type and confidence
    List<Widget> cancerWidgets = [];
    if (hasDetection) {
      final Map<int, Map<String, dynamic>> bestByType = {};
      for (var det in detectionResults) {
        final int classId = det['class_id'];
        if (!bestByType.containsKey(classId) ||
            (det['confidence'] as double) >
                (bestByType[classId]!['confidence'] as double)) {
          bestByType[classId] = det;
        }
      }
      final sorted = bestByType.values.toList()
        ..sort((a, b) =>
            (b['confidence'] as double).compareTo(a['confidence'] as double));
      for (var det in sorted) {
        final classId = det['class_id'];
        final confidence = det['confidence'];
        String cancerType;
        if (classId == 0) {
          cancerType = "Melanoma";
        } else if (classId == 1) {
          cancerType = "Vascular Lesion";
        } else {
          cancerType = "Unknown";
        }
        cancerWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              "$cancerType\nConfidence: ${(confidence * 100).toStringAsFixed(2)}%",
              style: const TextStyle(
                color: mainTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and cancer analysis label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: mainTextColor),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (_) => false,
                      );
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F0FF), // baby blue
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(
                              0.10), // subtle blue shadow for "timbul" effect
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Cancer analysis",
                      style: TextStyle(
                        color: mainTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // To balance the row
                ],
              ),
            ),
            // Large image, no blue background, fills the space
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1, // Ensures a square area
                  child: FractionallySizedBox(
                    widthFactor:
                        1.0, // Make the image area as big as possible (100% of available width)
                    heightFactor:
                        1.0, // Make the image area as big as possible (100% of available height)
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final imgW = constraints.maxWidth;
                        final imgH = constraints.maxHeight;
                        return Stack(
                          children: [
                            Image.memory(
                              imageBytes,
                              width: imgW,
                              height: imgH,
                              fit: BoxFit.cover,
                            ),
                            ...detectionResults.map((det) {
                              List? boundingBox = det['bounding_box'];
                              if (boundingBox == null ||
                                  boundingBox.length != 4) {
                                return const SizedBox.shrink();
                              }
                              double left = boundingBox[0].toDouble();
                              double top = boundingBox[1].toDouble();
                              double width = boundingBox[2].toDouble();
                              double height = boundingBox[3].toDouble();

                              double origW = 640; // Your real image width
                              double origH = 640; // Your real image height

                              double scaleX = imgW / origW;
                              double scaleY = imgH / origH;

                              return Positioned(
                                left: left * scaleX,
                                top: top * scaleY,
                                width: width * scaleX,
                                height: height * scaleY,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Card with result info at the bottom, blue background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: const BoxDecoration(
                color: cardBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Detection status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasDetection
                          ? Colors.red.withOpacity(0.13)
                          : Colors.green.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hasDetection ? "Skin cancer detected" : "No detection",
                      style: TextStyle(
                        color: hasDetection ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Cancer type and confidence
                  if (hasDetection && cancerWidgets.isNotEmpty)
                    Builder(
                      builder: (_) {
                        final text =
                            (cancerWidgets.first as Padding).child as Text;
                        final lines = text.data?.split('\n');
                        final cancerType =
                            lines != null && lines.isNotEmpty ? lines[0] : '';
                        final confidence =
                            lines != null && lines.length > 1 ? lines[1] : '';
                        return Column(
                          children: [
                            Text(
                              "Cancer type: $cancerType",
                              style: const TextStyle(
                                color: mainTextColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (confidence.isNotEmpty)
                              Text(
                                confidence,
                                style: const TextStyle(
                                  color: mainTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            onRetry();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Retry",
                            style:
                                TextStyle(fontSize: 15, color: mainTextColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _getLocationAndFetchHospital(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Nearest Hospitals",
                            style:
                                TextStyle(fontSize: 14, color: mainTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _saveToFirebase({
                          'image': base64Image,
                          'detections': detectionResults,
                        });
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(fontSize: 15, color: mainTextColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
