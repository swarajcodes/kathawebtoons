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
  bool _isSaving = false;
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
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one genre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await UserPreferences.loadLocally();
      
      if (prefs != null) {
        final updatedPrefs = UserPreferences(
          username: prefs.username,
          selectedGenres: _selectedGenres,
          isGuestUser: user == null,
          readingFormat: prefs.readingFormat,
          readingDays: prefs.readingDays,
          preferredReadingTime: prefs.preferredReadingTime,
        );

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('preferences')
              .doc('reading')
              .set(updatedPrefs.toJson());
        }
        
        await updatedPrefs.saveLocally();
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingFormatPreference(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving preferences: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                  onPressed: _isSaving ? null : _savePreferences,
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
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
    );
  }
} 