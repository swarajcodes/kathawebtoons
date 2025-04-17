import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_preferences.dart';
import '../../main.dart';

class ReadingSchedule extends StatefulWidget {
  @override
  _ReadingScheduleState createState() => _ReadingScheduleState();
}

class _ReadingScheduleState extends State<ReadingSchedule> {
  final List<String> _selectedDays = [];
  TimeOfDay? _selectedTime;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveSchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await UserPreferences.loadLocally();
    
    if (prefs != null) {
      final updatedPrefs = UserPreferences(
        selectedGenres: prefs.selectedGenres,
        readingFormat: prefs.readingFormat,
        readingDays: _selectedDays,
        preferredReadingTime: _selectedTime,
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
                'When do you like to read?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(
                      day,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    backgroundColor: Colors.grey[900],
                    selectedColor: Color(0xFFA3D749),
                    checkmarkColor: Colors.black,
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text(
                  'Preferred Reading Time',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  _selectedTime != null
                      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                      : 'Not set',
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
                trailing: Icon(
                  Icons.access_time,
                  color: Colors.white,
                ),
                onTap: () => _selectTime(context),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveSchedule();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainNavigation()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text(
                    'Finish Setup',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA3D749),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 