import 'package:flutter/material.dart';
import 'premium.dart'; // Import premium.dart to navigate

class HospitalsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> nearestHospitals;

  const HospitalsScreen({super.key, required this.nearestHospitals});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F4858),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text("", style: TextStyle(color: Colors.white)), // Empty title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Nearest Medical Center to You",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (nearestHospitals.isNotEmpty) _buildHospitalCard(context, nearestHospitals[0], isTop: true),
            const SizedBox(height: 16),
            if (nearestHospitals.length > 1) _buildHospitalCard(context, nearestHospitals[1]),
            const SizedBox(height: 12),
            if (nearestHospitals.length > 2) _buildHospitalCard(context, nearestHospitals[2]),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard(BuildContext context, Map<String, dynamic> hospital, {bool isTop = false}) {
    return InkWell(
      onTap: () {
        _showHospitalDetails(context, hospital);
      },
      child: Card(
        color: const Color(0xFFCAD8E2),
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
                      hospital['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${hospital['distance']?.toStringAsFixed(2)} km",
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        hospital['name'] ?? '',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${hospital['distance']?.toStringAsFixed(2)} km",
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showHospitalDetails(BuildContext context, Map<String, dynamic> hospital) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hospital['name'] ?? 'Hospital Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Distance: ${hospital['distance']?.toStringAsFixed(2)} km"),
              const SizedBox(height: 10),
              Text("Phone: ${hospital['phone'] ?? 'Phone not available'}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              child: const Text('Navigate Me'),
            ),
          ],
        );
      },
    );
  }
}
