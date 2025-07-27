import 'package:flutter/material.dart';
import 'premium.dart'; // Navigate to premium screen

class HospitalsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> nearestHospitals;

  const HospitalsScreen({super.key, required this.nearestHospitals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F0FF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text("", style: TextStyle(color: Colors.black87)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: nearestHospitals.isEmpty
            ? const Center(
                child: Text(
                  "No hospitals found nearby.",
                  style: TextStyle(fontSize: 16, color: Color(0xFF223A5E)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Nearest Medical Center to You",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223A5E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (nearestHospitals.isNotEmpty)
                    _buildHospitalCard(context, nearestHospitals[0],
                        isTop: true),
                  const SizedBox(height: 16),
                  if (nearestHospitals.length > 1)
                    _buildHospitalCard(context, nearestHospitals[1]),
                  const SizedBox(height: 12),
                  if (nearestHospitals.length > 2)
                    _buildHospitalCard(context, nearestHospitals[2]),
                ],
              ),
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, Map<String, dynamic> hospital,
      {bool isTop = false}) {
    String name = hospital['name'] ?? 'Unknown Hospital';
    String distance = (hospital['distance'] is double)
        ? "${hospital['distance'].toStringAsFixed(2)} km"
        : "0.00 km";

    return InkWell(
      onTap: () {
        _showHospitalDetails(context, hospital);
      },
      child: Card(
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: isTop
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF223A5E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      distance,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF8DC6A7)),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16, color: Color(0xFF223A5E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      distance,
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF8DC6A7)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showHospitalDetails(
      BuildContext context, Map<String, dynamic> hospital) {
    String name = hospital['name'] ?? 'Hospital Details';
    String distance = (hospital['distance'] is double)
        ? "${hospital['distance'].toStringAsFixed(2)} km"
        : "0.00 km";
    String phone = hospital['phone'] ?? 'Phone number not available.';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFE3F0FF),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF223A5E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Distance: $distance",
                style: const TextStyle(
                  color: Color(0xFF223A5E),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Phone: $phone",
                style: const TextStyle(
                  color: Color(0xFF223A5E),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close',
                  style: TextStyle(color: Color(0xFF223A5E))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DC6A7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              ),
              child: const Text(
                'Navigate Me',
                style: TextStyle(color: Color(0xFF223A5E)),
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<String> _fetchPhoneNumber(String placeId) async {
  try {
    await Future.delayed(const Duration(seconds: 1));
    return "+1 234 567 8900";
  } catch (_) {
    return "Phone number not available.";
  }
}

Future<void> fetchAndSetHospitalsPhoneNumbers(
    List<Map<String, dynamic>> hospitals) async {
  // Filter out hospitals with null or non-string place_id
  hospitals.removeWhere((h) =>
      h['place_id'] == null ||
      h['place_id'] is! String ||
      (h['place_id'] as String).isEmpty);

  for (var hospital in hospitals) {
    final placeId = hospital['place_id'];
    final phoneNumber = await _fetchPhoneNumber(placeId);
    hospital['phone'] = phoneNumber;
  }
}
