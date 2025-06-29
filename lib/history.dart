import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.detectionResults = const {}});
  final Map<String, dynamic> detectionResults;

  Future<void> _resetAll(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset All History"),
        content: const Text(
            "Are you sure you want to delete all history? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text("Delete All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_results')
          .get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All history deleted.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Scan History"),
          backgroundColor: const Color(0xFFE3F0FF),
          foregroundColor: const Color(0xFF223A5E),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Color(0xFF223A5E)),
              tooltip: "Reset All",
              onPressed: () => _resetAll(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              // No color here, let it blend with wallpaper
              child: const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFF223A5E),
                labelColor: Color(0xFF223A5E),
                unselectedLabelColor: Color(0xFF4C6D83),
                tabs: [
                  Tab(text: "All"),
                  Tab(text: "Melanoma"),
                  Tab(text: "Vascular"),
                  Tab(text: "No Detection"),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFE3F0FF),
        body: const TabBarView(
          children: [
            _HistoryList(filter: 'all'),
            _HistoryList(filter: 'melanoma'),
            _HistoryList(filter: 'vascular'),
            _HistoryList(filter: 'no_detection'),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final String filter;
  const _HistoryList({required this.filter});

  Future<void> _deleteDoc(BuildContext context, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_results')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted successfully.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_results')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No results saved yet."));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] == null) return false;
          if (filter == 'all') return true;
          if (filter == 'no_detection') {
            final detections = data['detectionResults']?['detections'];
            return detections == null ||
                !(detections is List) ||
                detections.isEmpty;
          }
          final detections = data['detectionResults']?['detections'];
          if (detections is List && detections.isNotEmpty) {
            final classId = detections[0]['class_id'];
            if (filter == 'melanoma' && classId == 0) return true;
            if (filter == 'vascular' && classId == 1) return true;
          }
          return false;
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("No results for this filter."));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final Timestamp ts = data['createdAt'] ?? Timestamp.now();
            final DateTime dateTime = ts.toDate();
            final String day = DateFormat('EEEE').format(dateTime);
            final String date = DateFormat('dd MMM yyyy').format(dateTime);
            final String time = DateFormat('hh:mm a').format(dateTime);

            // Extract detection info
            String cancerType = "No Detection";
            String confidenceStr = "-";
            final detections = data['detectionResults']?['detections'];
            if (detections is List && detections.isNotEmpty) {
              final det = detections[0];
              final classId = det['class_id'];
              final confidence = det['confidence'];
              cancerType = classId == 0
                  ? "Melanoma"
                  : classId == 1
                      ? "Vascular Lesion"
                      : "Unknown";
              confidenceStr = (confidence is double || confidence is int)
                  ? "${(confidence * 100).toStringAsFixed(2)}%"
                  : confidence.toString();
            }

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: Colors.redAccent,
                child: const Icon(Icons.delete, color: Colors.white, size: 32),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Delete Confirmation"),
                    content: const Text(
                        "Are you sure you want to delete this record?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Delete",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) {
                _deleteDoc(context, doc.id);
              },
              child: Card(
                color: const Color(0xFFF5FAFF),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                  title: Text(
                    "$day, $date",
                    style: const TextStyle(
                      color: Color(0xFF223A5E),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF4C6D83),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing:
                      const Icon(Icons.chevron_right, color: Color(0xFF223A5E)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: const Color(0xFFE3F0FF),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (data['image'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        base64Decode(
                                          data['image'].contains(',')
                                              ? data['image'].split(',').last
                                              : data['image'],
                                        ),
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "$day, $date",
                                    style: const TextStyle(
                                      color: Color(0xFF223A5E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: Color(0xFF4C6D83),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    "Cancer Type: $cancerType",
                                    style: const TextStyle(
                                      color: Color(0xFF223A5E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    "Confidence: $confidenceStr",
                                    style: const TextStyle(
                                      color: Color(0xFF4C6D83),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8DC6A7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(
                                        color: Color(0xFF223A5E),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
