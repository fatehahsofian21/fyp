import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    // Show the button after 2 seconds (or adjust as needed)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showButton = true;
      });
    });
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5D8AA8), // Baby blue blur
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Only show ambulance animation (remove maps.json)
            Lottie.asset('assets/lottie/ambulance.json', width: 180),
            const SizedBox(height: 32),
            const Text(
              'SkinSight',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White for strong contrast
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Early detection can save lives',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFE3F0FF), // Lighter blue for subtitle
              ),
            ),
            const SizedBox(height: 32),
            if (!_showButton)
              const CircularProgressIndicator(color: Colors.white),
            if (_showButton)
              ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF223A5E), // Navy blue button
                  foregroundColor: Colors.white, // White text
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  elevation: 3,
                ),
                child: const Text('Get Started'),
              ),
          ],
        ),
      ),
    );
  }
}
