import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

/// Service class for handling user authentication
/// Manages sign-in with Google, guest access, and user preferences
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;
  bool _initialized = false;

  /// Initialize shared preferences
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  /// Get the currently authenticated user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Sign in with Google account
  /// Returns the authenticated user or null if sign-in fails
  Future<User?> signInWithGoogle() async {
    try {
      // Ensure initialization
      await init();
      
      // Start Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign in was cancelled by user');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('Google authentication failed: Missing access token or ID token');
        return null;
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // New user - needs onboarding
          return user;
        }
        // Existing user - set guest flag to false
        await _prefs?.setBool('is_guest', false);
        return user;
      }
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      if (e is FirebaseAuthException) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      } else if (e is PlatformException) {
        print('Platform Error: ${e.code} - ${e.message}');
      }
      return null;
    }
  }

  /// Save username to Firestore
  Future<void> saveUsername(String uid, String username) async {
    await _firestore.collection('users').doc(uid).set({
      'email': _auth.currentUser!.email,
      'username': username,
    });
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Sign in as a guest user
  Future<void> signInAsGuest() async {
    await init();
    // Set guest flag
    await _prefs?.setBool('is_guest', true);
    
    // Set default guest preferences
    await _prefs?.setString('user_preferences', {
      'selectedGenres': ['Action', 'Adventure', 'Comedy'],
      'isGuest': true,
      'readingSchedule': {
        'notificationsEnabled': false,
        'notificationTime': '20:00',
        'daysOfWeek': [],
      },
      'readingFormat': {
        'fontSize': 16.0,
        'fontFamily': 'Roboto',
        'theme': 'dark',
        'lineHeight': 1.5,
      }
    }.toString());
  }

  /// Check if current user is a guest
  Future<bool> isGuestUser() async {
    await init();
    return _prefs?.getBool('is_guest') ?? false;
  }

  /// Save user preferences to shared preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    await init();
    await _prefs?.setString('user_preferences', preferences.toString());
  }

  /// Get user preferences from shared preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    await init();
    final preferencesString = _prefs?.getString('user_preferences');
    if (preferencesString == null) return null;
    
    try {
      return Map<String, dynamic>.from(preferencesString as Map);
    } catch (e) {
      print('Error parsing user preferences: $e');
      return null;
    }
  }

  /// Check if a username is available and valid
  Future<Map<String, dynamic>> validateUsername(String username) async {
    // Check username format
    if (username.length < 3 || username.length > 20) {
      return {
        'isValid': false,
        'message': 'Username must be between 3 and 20 characters'
      };
    }

    // Only allow letters, numbers, and underscores
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return {
        'isValid': false,
        'message': 'Username can only contain letters, numbers, and underscores'
      };
    }

    // Check if username is already taken
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return {
        'isValid': false,
        'message': 'Username is already taken'
      };
    }

    return {
      'isValid': true,
      'message': 'Username is available'
    };
  }

  /// Save username to Firestore with validation
  Future<Map<String, dynamic>> saveUsernameWithValidation(String uid, String username) async {
    final validation = await validateUsername(username);
    if (!validation['isValid']) {
      return validation;
    }

    await saveUsername(uid, username);
    return {
      'isValid': true,
      'message': 'Username saved successfully'
    };
  }
}