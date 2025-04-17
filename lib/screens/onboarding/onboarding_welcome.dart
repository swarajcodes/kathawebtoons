import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

/// Welcome screen for new users during onboarding
/// Allows users to set their username and select preferred genres
class OnboardingWelcome extends StatefulWidget {
  @override
  _OnboardingWelcomeState createState() => _OnboardingWelcomeState();
}

class _OnboardingWelcomeState extends State<OnboardingWelcome> {
  /// Controller for the username input field
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _usernameError;
  bool _isValidating = false;
  
  /// List of selected genres by the user
  final List<String> _selectedGenres = [];
  
  /// List of available genres with their icons
  final List<Map<String, dynamic>> _genres = [
    {'name': 'Action', 'icon': Icons.sports_martial_arts},
    {'name': 'Adventure', 'icon': Icons.travel_explore},
    {'name': 'Comedy', 'icon': Icons.sentiment_very_satisfied},
    {'name': 'Drama', 'icon': Icons.theater_comedy},
    {'name': 'Fantasy', 'icon': Icons.auto_awesome},
    {'name': 'Horror', 'icon': Icons.warning},
    {'name': 'Mystery', 'icon': Icons.psychology},
    {'name': 'Romance', 'icon': Icons.favorite},
    {'name': 'Sci-Fi', 'icon': Icons.rocket_launch},
    {'name': 'Slice of Life', 'icon': Icons.people},
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _validateUsername(String username) async {
    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _usernameError = null;
    });

    final validation = await _authService.validateUsername(username);
    
    setState(() {
      _isValidating = false;
      if (!validation['isValid']) {
        _usernameError = validation['message'];
      }
    });
  }

  void _onGetStarted() async {
    if (_usernameController.text.isEmpty || _selectedGenres.isEmpty) return;

    final validation = await _authService.saveUsernameWithValidation(
      FirebaseAuth.instance.currentUser!.uid,
      _usernameController.text
    );

    if (!validation['isValid']) {
      setState(() {
        _usernameError = validation['message'];
      });
      return;
    }

    // Save selected genres
    await _authService.saveUserPreferences({
      'selectedGenres': _selectedGenres.toList(),
    });

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    // Enable button only when username is entered and at least one genre is selected
    final bool isButtonEnabled = _usernameController.text.isNotEmpty && _selectedGenres.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      // App logo
                      Image.asset(
                        'assets/KathaLogo.png',
                        height: 30,
                      ),
                      SizedBox(height: 50),
                      // Username input field
                      TextField(
                        controller: _usernameController,
                        style: TextStyle(color: Colors.white),
                        onChanged: _validateUsername,
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          errorText: _usernameError,
                          suffixIcon: _isValidating 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                        ),
                      ),
                      SizedBox(height: 40),
                      // Genre selection title
                      Text(
                        'Select your favorite genres',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Genre selection grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _genres.length,
                        itemBuilder: (context, index) {
                          final genre = _genres[index];
                          final isSelected = _selectedGenres.contains(genre['name']);
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedGenres.remove(genre['name']);
                                } else {
                                  _selectedGenres.add(genre['name']);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFA3D749) : Colors.grey[900],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    genre['icon'],
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    genre['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20), // Add spacing before the button
                    ],
                  ),
                ),
              ),
            ),
            // Get Started button at the bottom
            Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? _onGetStarted : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled ? Color(0xFFA3D749) : Colors.grey[800],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      color: isButtonEnabled ? Colors.black : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 