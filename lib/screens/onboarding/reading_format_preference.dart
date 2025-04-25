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
  bool _isSaving = false;

  Future<void> _updateFormatPreference(String format) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await UserPreferences.loadLocally();
      
      if (prefs != null) {
        final updatedPrefs = UserPreferences(
          username: prefs.username,
          selectedGenres: prefs.selectedGenres,
          isGuestUser: user == null,
          readingFormat: format,
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
          MaterialPageRoute(builder: (context) => ReadingSchedule()),
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

  Widget _buildFormatOption(BuildContext context, String title, String description, IconData icon, String format) {
    final isSelected = _selectedFormat == format;
    final isDisabled = _isSaving;

    return InkWell(
      onTap: isDisabled ? null : () async {
        setState(() {
          _selectedFormat = format;
        });
        await _updateFormatPreference(format);
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFA3D749) : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (_isSaving && isSelected)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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