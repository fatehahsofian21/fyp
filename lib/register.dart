import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackbar("Passwords do not match!", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user details in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "createdAt": DateTime.now().toIso8601String(),
      });

      _showSnackbar("Registration Successful!", Colors.green);
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Navigate back to login after success
      });
    } catch (e) {
      _showSnackbar("Error: ${e.toString()}", Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F7091), // UCLA Blue
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/a.png',
                  width: 220,
                ),
                const SizedBox(height: 40),

                // Register Text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white, // White for contrast
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Welcome Message
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create an account to get started!",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD2E6FF), // Light blue for contrast
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field
                _buildTextField("Enter your name", controller: _nameController),
                const SizedBox(height: 15),

                // Email Field
                _buildTextField("Enter your email",
                    controller: _emailController),
                const SizedBox(height: 15),

                // Password Field
                _buildPasswordField(
                    "Enter your password", _passwordController, true),
                const SizedBox(height: 15),

                // Confirm Password Field
                _buildPasswordField(
                    "Confirm your password", _confirmPasswordController, false),
                const SizedBox(height: 20),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFB3D1F6), // Light blue button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF223A5E))
                        : const Text(
                            "REGISTER",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF223A5E), // Navy text on button
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 15),

                // Login Option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFD2E6FF),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom TextField Widget for Name & Email
  Widget _buildTextField(String hintText,
      {required TextEditingController controller}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white), // White text
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white24, // Same as password box
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }

  // Password Field with Eye Icon
  Widget _buildPasswordField(
      String hintText, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText:
          isPassword ? !_isPasswordVisible : !_isConfirmPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white24,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        suffixIcon: IconButton(
          icon: Icon(
            isPassword
                ? (_isPasswordVisible ? Icons.visibility : Icons.visibility_off)
                : (_isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off),
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              if (isPassword) {
                _isPasswordVisible = !_isPasswordVisible;
              } else {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              }
            });
          },
        ),
      ),
    );
  }
}
