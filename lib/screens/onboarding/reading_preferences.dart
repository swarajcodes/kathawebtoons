import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_preferences.dart';
import 'reading_format_preference.dart';

class ReadingPreferences extends StatefulWidget {
  @override
  _ReadingPreferencesState createState() => _ReadingPreferencesState();
}

class _ReadingPreferencesState extends State<ReadingPreferences> {
  final List<String> _selectedGenres = [];
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

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    final preferences = UserPreferences(
      selectedGenres: _selectedGenres,
      readingFormat: 'both', // Default value, will be updated in next screen
      readingDays: [], // Will be updated in schedule screen
      isGuestUser: user == null,
    );

    if (user != null) {
      // Save to Firestore for authenticated users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('reading')
          .set(preferences.toJson());
    } else {
      // Save locally for guest users
      await UserPreferences.saveLocally(preferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'What do you like to read?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2,
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
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _savePreferences();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadingFormatPreference(),
                      ),
                    );
                  },
                  child: Text(
                    'Continue',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA3D749),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedGenres.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final prefs = UserPreferences(
                  selectedGenres: _selectedGenres,
                  readingFormat: '',
                  readingDays: [],
                  isGuestUser: true,
                );
                await UserPreferences.saveLocally(prefs);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadingFormatPreference(),
                  ),
                );
              },
              child: Icon(Icons.arrow_forward),
            )
          : null,
    );
  }
} 