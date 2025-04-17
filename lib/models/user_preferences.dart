import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model class for storing and managing user preferences
/// Handles both authenticated and guest user preferences
class UserPreferences {
  /// Username of the user
  final String username;
  
  /// List of selected genres
  final List<String> selectedGenres;
  
  /// Whether the user is a guest
  final bool isGuest;
  
  /// Reading schedule preferences
  final Map<String, dynamic> readingSchedule;
  
  /// Reading format preferences
  final Map<String, dynamic> readingFormat;

  UserPreferences({
    required this.username,
    required this.selectedGenres,
    required this.isGuest,
    required this.readingSchedule,
    required this.readingFormat,
  });

  /// Create default preferences for a new user
  factory UserPreferences.defaults() {
    return UserPreferences(
      username: '',
      selectedGenres: [],
      isGuest: true,
      readingSchedule: {
        'notificationsEnabled': false,
        'notificationTime': '20:00',
        'daysOfWeek': [],
      },
      readingFormat: {
        'fontSize': 16.0,
        'fontFamily': 'Roboto',
        'theme': 'dark',
        'lineHeight': 1.5,
      },
    );
  }

  /// Load preferences from shared preferences
  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    return UserPreferences(
      username: prefs.getString('username') ?? '',
      selectedGenres: prefs.getStringList('selectedGenres') ?? [],
      isGuest: prefs.getBool('isGuest') ?? true,
      readingSchedule: {
        'notificationsEnabled': prefs.getBool('notificationsEnabled') ?? false,
        'notificationTime': prefs.getString('notificationTime') ?? '20:00',
        'daysOfWeek': prefs.getStringList('daysOfWeek') ?? [],
      },
      readingFormat: {
        'fontSize': prefs.getDouble('fontSize') ?? 16.0,
        'fontFamily': prefs.getString('fontFamily') ?? 'Roboto',
        'theme': prefs.getString('theme') ?? 'dark',
        'lineHeight': prefs.getDouble('lineHeight') ?? 1.5,
      },
    );
  }

  /// Save preferences to shared preferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('username', username);
    await prefs.setStringList('selectedGenres', selectedGenres);
    await prefs.setBool('isGuest', isGuest);
    
    // Save reading schedule preferences
    await prefs.setBool('notificationsEnabled', readingSchedule['notificationsEnabled'] as bool);
    await prefs.setString('notificationTime', readingSchedule['notificationTime'] as String);
    // Convert daysOfWeek to List<String> before saving
    final daysOfWeek = (readingSchedule['daysOfWeek'] as List<dynamic>).map((e) => e.toString()).toList();
    await prefs.setStringList('daysOfWeek', daysOfWeek);
    
    // Save reading format preferences
    await prefs.setDouble('fontSize', readingFormat['fontSize'] as double);
    await prefs.setString('fontFamily', readingFormat['fontFamily'] as String);
    await prefs.setString('theme', readingFormat['theme'] as String);
    await prefs.setDouble('lineHeight', readingFormat['lineHeight'] as double);
  }

  /// Update username and save to preferences
  Future<void> updateUsername(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newUsername);
  }

  /// Update selected genres and save to preferences
  Future<void> updateGenres(List<String> newGenres) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedGenres', newGenres);
  }

  /// Update reading schedule preferences
  Future<void> updateReadingSchedule(Map<String, dynamic> newSchedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', newSchedule['notificationsEnabled'] as bool);
    await prefs.setString('notificationTime', newSchedule['notificationTime'] as String);
    await prefs.setStringList('daysOfWeek', newSchedule['daysOfWeek'] as List<String>);
  }

  /// Update reading format preferences
  Future<void> updateReadingFormat(Map<String, dynamic> newFormat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', newFormat['fontSize'] as double);
    await prefs.setString('fontFamily', newFormat['fontFamily'] as String);
    await prefs.setString('theme', newFormat['theme'] as String);
    await prefs.setDouble('lineHeight', newFormat['lineHeight'] as double);
  }
} 