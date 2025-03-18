import 'package:flutter/material.dart';
import 'dart:convert';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F4858),
      appBar: AppBar(
        title: const Text(
          "Scan Result",
          style: TextStyle(color: Colors.white), // **Title in White**
          textAlign: TextAlign.center, // **Centered Text**
        ),
        backgroundColor: const Color(0xFF2F4858),
        centerTitle: true, // **Centers Title in AppBar**
        iconTheme: const IconThemeData(color: Colors.white), // **Back Arrow in White**
      ),
      body: Center( // **Everything is Centered**
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // **Centered Between Top & Bottom**
          crossAxisAlignment: CrossAxisAlignment.center, // **Centered Left & Right**
          children: [
            const Text(
              "Skin Cancer Detected!",
              style: TextStyle(
                color: Colors.green,
                fontSize: 22, // **Slightly Bigger Font**
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center, // **Centered Text**
            ),
            const SizedBox(height: 20),

            // **Bigger Image, Fully Centered**
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

            // **Detection Results Fully Centered**
            Column(
              children: detectionResults.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    "${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center, // **Centered Text**
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // **Buttons, Centered & Same Size as HomeScreen**
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
                      backgroundColor: Colors.grey[600], // Retry Button Color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Retry",
                        style: TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12), // **Reduced Spacing**

                SizedBox(
                  width: 160,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Nearest Hospitals Feature
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Hospital Button Color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Nearest Hospitals",
                        style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12), // **Reduced Spacing**

                SizedBox(
                  width: 160,
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
