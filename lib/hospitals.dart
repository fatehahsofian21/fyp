import 'package:flutter/material.dart';

class HospitalsScreen extends StatelessWidget {
  final List<String> nearestHospitals; // Accept a list of hospitals

  const HospitalsScreen({super.key, required this.nearestHospitals});

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
      body: nearestHospitals.isEmpty
          ? const Center(child: Text("No hospitals found"))
          : ListView.builder(
              itemCount: nearestHospitals.length,
              itemBuilder: (context, index) {
                return Text(
                  nearestHospitals[index], // Display hospital name directly
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                );
              },
            ),
    );
  }
}
