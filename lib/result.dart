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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Skin Cancer Detected!",
              style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Image.memory(
              base64Decode(base64Image),
              width: 150,
              height: 150,
            ),
            for (var entry in detectionResults.entries)
              Text(
                "${entry.key}: ${(entry.value * 100).toStringAsFixed(2)}%",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
