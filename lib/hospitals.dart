import 'package:flutter/material.dart';

class HospitalsScreen extends StatelessWidget {
  final String nearestHospital; // Add a field to receive nearest hospital data

  // Update constructor to accept nearestHospital
  const HospitalsScreen({super.key, required this.nearestHospital});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        title: const Text(
          "Nearest Hospitals",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2F4858),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              nearestHospital, // Display the nearest hospital passed from ResultScreen
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
