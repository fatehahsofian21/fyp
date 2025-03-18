import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  List<String> _hospitalList = [];
  bool _isLoading = true;
  bool _noHospitalsFound = false;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    try {
      Position position = await _determinePosition();

      const String googleApiKey = "AIzaSyBuzJjbg-b6_zsmXYX7RzQ09UEDXHirhi4";
      final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${position.latitude},${position.longitude}"
          "&radius=5000"
          "&type=hospital"
          "&keyword=Malaysia Hospital"
          "&key=$googleApiKey");

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        List<String> hospitals = data["results"]
            .where((item) => item["vicinity"].toString().contains("Malaysia")) // Ensure it's in Malaysia
            .map<String>((item) => item["name"].toString())
            .toList();

        setState(() {
          _hospitalList = hospitals;
          _isLoading = false;
          _noHospitalsFound = hospitals.isEmpty;
        });
      } else {
        setState(() {
          _hospitalList = [];
          _isLoading = false;
          _noHospitalsFound = true;
        });
      }
    } catch (e) {
      setState(() {
        _hospitalList = [];
        _isLoading = false;
        _noHospitalsFound = true;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are permanently denied, we cannot request permissions.");
    }

    return await Geolocator.getCurrentPosition();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _noHospitalsFound
              ? const Center(
                  child: Text(
                    "No hospitals found in your area.",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _hospitalList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _hospitalList[index],
                          style:
                              const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
