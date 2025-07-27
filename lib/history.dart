import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';

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
      length: 3,
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

  Future<void> _saveAsPdf(
      BuildContext context,
      Map<String, dynamic> data,
      String cancerType,
      String confidenceStr,
      String day,
      String date,
      String time) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text('Skin Cancer Scan Report',
                  style: pw.TextStyle(
                      fontSize: 26, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text('Date: $day, $date', style: pw.TextStyle(fontSize: 14)),
            pw.Text('Time: $time', style: pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Text('Cancer Type: $cancerType',
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text('Confidence: $confidenceStr',
                style: pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 16),
            if (data['image'] != null)
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(
                    base64Decode(
                      data['image'].contains(',')
                          ? data['image'].split(',').last
                          : data['image'],
                    ),
                  ),
                  width: 180,
                  height: 180,
                ),
              ),
            pw.SizedBox(height: 16),
            pw.Text('Thank you for using our app!',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _shareResult(
      BuildContext context,
      Map<String, dynamic> data,
      String cancerType,
      String confidenceStr,
      String day,
      String date,
      String time) async {
    String text = 'Scan Result\n'
        'Date: $day, $date\n'
        'Time: $time\n'
        'Cancer Type: $cancerType\n'
        'Confidence: $confidenceStr\n';
    await Share.share(text);
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
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] == null) return false;
          final detections = data['detectionResults']?['detections'];
          final isNoDetection =
              detections == null || !(detections is List) || detections.isEmpty;

          if (filter == 'all') return true;
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
            final ts = data['createdAt'];
            DateTime dateTime;
            if (ts is Timestamp) {
              dateTime = ts.toDate();
            } else if (ts is DateTime) {
              dateTime = ts;
            } else {
              dateTime = DateTime.now();
            }
            final String day = DateFormat('EEEE').format(dateTime);
            final String date = DateFormat('dd MMM yyyy').format(dateTime);
            final String time = DateFormat('hh:mm a').format(dateTime);

            // Extract detection info
            String cancerType = "No Detection";
            String confidenceStr = "-";
            final detections = data['detectionResults']?['detections'];
            if (detections is List && detections.isNotEmpty) {
              final det = detections[0];
              final classId = det['class_id'] ?? -1;
              final rawConfidence = det['confidence'];
              final double confidence = (rawConfidence is int)
                  ? rawConfidence.toDouble()
                  : (rawConfidence is double ? rawConfidence : 0.0);

              cancerType = classId == 0
                  ? "Melanoma"
                  : classId == 1
                      ? "Vascular Lesion"
                      : "Unknown";
              confidenceStr = "${(confidence * 100).toStringAsFixed(2)}%";
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
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  title: Text(
                    "$day, $date",
                    style: const TextStyle(
                      color: Color(0xFF223A5E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xFF4C6D83),
                        fontSize: 12,
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: const Color(0xFFE3F0FF),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (data['image'] != null)
                                    Builder(
                                      builder: (context) {
                                        try {
                                          final imgStr = data['image'];
                                          final bytes = base64Decode(
                                            imgStr.contains(',')
                                                ? imgStr.split(',').last
                                                : imgStr,
                                          );
                                          return ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(
                                              bytes,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        } catch (e) {
                                          return const Text(
                                            "Image unavailable",
                                            style: TextStyle(color: Colors.red),
                                          );
                                        }
                                      },
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "$day, $date",
                                    style: const TextStyle(
                                      color: Color(0xFF223A5E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      color: Color(0xFF4C6D83),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Text(
                                    "Cancer Type: $cancerType",
                                    style: const TextStyle(
                                      color: Color(0xFF223A5E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "Confidence: $confidenceStr",
                                    style: const TextStyle(
                                      color: Color(0xFF4C6D83),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _saveAsPdf(
                                            context,
                                            data,
                                            cancerType,
                                            confidenceStr,
                                            day,
                                            date,
                                            time),
                                        icon: const Icon(Icons.picture_as_pdf,
                                            color: Color(0xFF223A5E)),
                                        label: const Text(
                                          "Save as PDF",
                                          style: TextStyle(
                                              color: Color(0xFF223A5E),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF8DC6A7),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _shareResult(
                                            context,
                                            data,
                                            cancerType,
                                            confidenceStr,
                                            day,
                                            date,
                                            time),
                                        icon: const Icon(Icons.share,
                                            color: Color(0xFF223A5E)),
                                        label: const Text(
                                          "Share",
                                          style: TextStyle(
                                              color: Color(0xFF223A5E),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF8DC6A7),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8DC6A7),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(
                                        color: Color(0xFF223A5E),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
