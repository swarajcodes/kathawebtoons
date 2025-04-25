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

  @override
  void initState() {
    super.initState();
    // Prevent going back to previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Prevent multiple sign-in attempts
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Add timeout to prevent infinite loading
      final user = await _authService.signInWithGoogle().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Sign in timed out. Please try again.';
          });
          return null;
        },
      );

      if (user != null) {
        // Check if user needs onboarding
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (!userDoc.exists) {
          // New user - navigate to onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingWelcome()),
          );
        } else {
          // Existing user - navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigation()),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Sign in error: $e');
      String errorMessage = 'Failed to sign in with Google. Please try again.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = 'An account already exists with the same email address but different sign-in credentials.';
            break;
          case 'invalid-credential':
            errorMessage = 'The credential received is malformed or has expired.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Google Sign-In is not enabled. Please contact support.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-verification-code':
            errorMessage = 'The verification code is invalid.';
            break;
          case 'invalid-verification-id':
            errorMessage = 'The verification ID is invalid.';
            break;
        }
      }
      
      setState(() {
        _errorMessage = errorMessage;
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
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: GoogleAuthButton(
                  onPressed: _isLoading ? () {} : _signInWithGoogle,
                  isLoading: _isLoading,
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
      ),
    );
  }
}