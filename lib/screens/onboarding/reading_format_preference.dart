import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_preferences.dart';
import 'reading_schedule.dart';

class ReadingFormatPreference extends StatefulWidget {
  @override
  _ReadingFormatPreferenceState createState() => _ReadingFormatPreferenceState();
}

class _ReadingFormatPreferenceState extends State<ReadingFormatPreference> {
  String _selectedFormat = '';

  Future<void> _updateFormatPreference(String format) async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await UserPreferences.loadLocally();
    
    if (prefs != null) {
      final updatedPrefs = UserPreferences(
        selectedGenres: prefs.selectedGenres,
        readingFormat: format,
        readingDays: prefs.readingDays,
        isGuestUser: prefs.isGuestUser,
      );

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('preferences')
            .doc('reading')
            .set(updatedPrefs.toJson());
      } else {
        await UserPreferences.saveLocally(updatedPrefs);
      }
    }
  }

  Widget _buildFormatOption(BuildContext context, String title, String description, IconData icon, String format) {
    return InkWell(
      onTap: () async {
        await _updateFormatPreference(format);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReadingSchedule()),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How do you prefer to read?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              _buildFormatOption(
                context,
                'Webtoons',
                'Read comics with beautiful illustrations',
                Icons.image,
                'webtoons',
              ),
              _buildFormatOption(
                context,
                'Webnovels',
                'Read stories with rich text content',
                Icons.menu_book,
                'webnovels',
              ),
              _buildFormatOption(
                context,
                'Both',
                'Enjoy both webtoons and webnovels',
                Icons.library_books,
                'both',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 