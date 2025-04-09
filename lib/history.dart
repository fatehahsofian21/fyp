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
  List<Map<String, double>> _history = [];

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
        _history = decodedData.map((item) => Map<String, double>.from(item)).toList();
      });
    }
  }

  // Save current result to history
  _saveToHistory(Map<String, double> result) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _history.add(result);
    String historyData = json.encode(_history);
    prefs.setString('history', historyData);
  }

  @override
  Widget build(BuildContext context) {
    // Save the current scan result when screen is built
    _saveToHistory(widget.detectionResults);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
      ),
      body: _history.isEmpty
          ? const Center(child: Text("No results saved yet."))
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                Map<String, double> scanResult = _history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  child: ListTile(
                    title: Text("Scan ${index + 1}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: scanResult.entries
                          .map((entry) => Text("${entry.key}: ${entry.value}"))
                          .toList(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _history.removeAt(index);
                          // Save the updated history list
                          _saveToHistory(Map<String, double>());
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
