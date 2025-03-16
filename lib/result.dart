import 'package:flutter/material.dart';
import 'dart:convert';

class ResultScreen extends StatelessWidget {
  final String base64Image;
  final Map<String, double> detectionResults;

  const ResultScreen({
    Key? key,
    required this.base64Image,
    required this.detectionResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        title: const Text("Scan Result"),
        backgroundColor: const Color(0xFF2F4858),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // **Fully Centered**
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Skin Cancer Detected!",
              style: TextStyle(
                color: Colors.green,
                fontSize: 22, // **Larger Font**
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // **Bigger Image, Centered**
            Container(
              width: 220, // **Same as HomeScreen**
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // **Buttons, Centered & Same Size as HomeScreen**
            Column(
              children: [
                SizedBox(
                  width: 160, // **Same size as HomeScreen button**
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600], // Retry Button Color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Retry",
                        style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 160, // **Same size as HomeScreen button**
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Nearest Hospitals Feature
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blueAccent, // Hospital Button Color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Nearest Hospitals",
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 160, // **Same size as HomeScreen button**
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Done Button Color
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
