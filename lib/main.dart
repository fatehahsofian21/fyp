import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Import Firebase Auth
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // ✅ Import Geolocator
import 'login.dart'; // Import your login screen
import 'home.dart'; // Import HomeScreen instead of HistoryScreen
import 'history.dart'; // Import HistoryScreen
import 'splash.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready

  try {
    await Firebase.initializeApp(); // ✅ Initialize Firebase
    await _initGeolocator(); // ✅ Initialize Geolocator Permissions
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(
        errorMessage:
            e.toString())); // Show error if Firebase or Geolocator fails
  }
}

// ✅ Function to request location permissions
Future<void> _initGeolocator() async {
  bool serviceEnabled;
  LocationPermission permission;

  // ✅ Check if location service is enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error("Location services are disabled.");
  }

  // ✅ Check and request location permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error("Location permissions are denied.");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error("Location permissions are permanently denied.");
  }
}

// ✅ Main App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FYP App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const SplashScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}

// ✅ Error Screen if Firebase or Geolocator Fails
class ErrorApp extends StatelessWidget {
  final String errorMessage;
  const ErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.redAccent,
        body: Center(
          child: Text(
            "Error initializing app:\n$errorMessage",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
