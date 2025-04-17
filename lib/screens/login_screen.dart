import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'username_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import '../widgets/google_auth_button.dart';
import 'onboarding/onboarding_welcome.dart';
import '../models/user_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // Check if user needs onboarding
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (!userDoc.exists) {
          // New user - navigate to onboarding
          Navigator.pushReplacementNamed(context, '/onboarding');
        } else {
          // Existing user - navigate to home
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in with Google. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _continueAsGuest(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFA3D749),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(flex: 3),
            Text(
              'katha',
              style: GoogleFonts.cormorantUnicase(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 0),
            Text(
              "Feel the story, see the magic.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500
              ),
            ),
            Spacer(flex: 4),
            SizedBox(
              width: double.infinity,
              child: GoogleAuthButton(
                onPressed: () => _signInWithGoogle(),
              ),
            ),
            SizedBox(height: 15),
            GestureDetector(
              onTap: () => _continueAsGuest(context),
              child: Text(
                'Continue as a guest',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}