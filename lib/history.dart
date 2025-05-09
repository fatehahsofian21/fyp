import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  final Map<String, double> detectionResults;

  const HistoryScreen({super.key, required this.detectionResults});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Load previously saved history from SharedPreferences
  _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? historyData = prefs.getString('history');
    if (historyData != null) {
      List decodedData = json.decode(historyData);
      setState(() {
        _history = decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  // Save current result to history
  _saveToHistory(List<Map<String, dynamic>> history) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String historyData = json.encode(history);
    prefs.setString('history', historyData);
  }

  // Add current result to the history list
  _addToHistory(Map<String, dynamic> result) {
    setState(() {
      _history.add(result);
      // Save the updated history list to SharedPreferences
      _saveToHistory(_history);
    });
  }

  // Show confirmation dialog before deleting a history item
  _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete this scan result?'),
          content: const Text('Are you sure you want to delete this scan result?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _history.removeAt(index);
                  // Save the updated history list after deletion
                  _saveToHistory(_history);
                });
                Navigator.of(context).pop(); // Close the dialog after deletion
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Add the current scan result when the screen is built, but only once
    if (_history.isEmpty) {
      _addToHistory({
        'image': widget.detectionResults['image'],  // Assuming 'image' is part of detection results
        'Basal Cell Carcinoma': widget.detectionResults['Basal Cell Carcinoma'],
        'Squamous Cell Carcinoma': widget.detectionResults['Squamous Cell Carcinoma'],
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
        backgroundColor: const Color(0xFF2F4858), // Matching color to the app theme
      ),
      backgroundColor: const Color(0xFF2F4858), // Set background color to match header
      body: _history.isEmpty
          ? const Center(child: Text("No results saved yet."))
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> scanResult = _history[index];
                return Dismissible(
                  key: Key(index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _confirmDelete(index); // Show the confirmation dialog before deletion
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Show scan details when the card is tapped
                      showDialog(
                        context: context,
                        barrierDismissible: true,  // Allow dismissing by tapping outside
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Scan Result"),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Ensure image is not null and base64 decoding is valid
                                if (scanResult['image'] != null && scanResult['image'].isNotEmpty)
                                  Image.memory(
                                    base64Decode(scanResult['image']),
                                    width: 100,
                                    height: 100,
                                  ),
                                const SizedBox(height: 10),
                                // Display the result entries (e.g., Basal Cell Carcinoma)
                                ...scanResult.entries
                                    .map((entry) {
                                      double value = entry.value ?? 0.0; // Ensure value is not null
                                      return Text("${entry.key}: ${(value * 100).toStringAsFixed(2)}%");
                                    })
                                    ,
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();  // Close the dialog
                                },
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      color: const Color(0xFFD6C3B8), // Cream color card
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                      child: ListTile(
                        title: Text("Scan ${index + 1}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: scanResult.entries
                              .map((entry) {
                                double value = entry.value ?? 0.0; // Ensure value is not null
                                return Text("${entry.key}: ${(value * 100).toStringAsFixed(2)}%");
                              })
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
