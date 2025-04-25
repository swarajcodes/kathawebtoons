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
  final bool isGuestUser;
  
  /// Reading format preference (webtoons, webnovels, or both)
  final String readingFormat;
  
  /// Selected reading days
  final List<String> readingDays;
  
  /// Preferred reading time
  final TimeOfDay? preferredReadingTime;

  UserPreferences({
    required this.username,
    required this.selectedGenres,
    required this.isGuestUser,
    required this.readingFormat,
    required this.readingDays,
    this.preferredReadingTime,
  });

  /// Create default preferences for a new user
  factory UserPreferences.defaults() {
    return UserPreferences(
      username: '',
      selectedGenres: [],
      isGuestUser: true,
      readingFormat: 'both',
      readingDays: [],
      preferredReadingTime: TimeOfDay(hour: 20, minute: 0),
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'selectedGenres': selectedGenres,
      'isGuestUser': isGuestUser,
      'readingFormat': readingFormat,
      'readingDays': readingDays,
      'preferredReadingTime': preferredReadingTime != null
          ? '${preferredReadingTime!.hour.toString().padLeft(2, '0')}:${preferredReadingTime!.minute.toString().padLeft(2, '0')}'
          : null,
    };
  }

  /// Create from Firestore JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return UserPreferences(
      username: json['username'] ?? '',
      selectedGenres: List<String>.from(json['selectedGenres'] ?? []),
      isGuestUser: json['isGuestUser'] ?? true,
      readingFormat: json['readingFormat'] ?? 'both',
      readingDays: List<String>.from(json['readingDays'] ?? []),
      preferredReadingTime: parseTime(json['preferredReadingTime']),
    );
  }

  /// Load preferences from shared preferences
  static Future<UserPreferences?> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      TimeOfDay? parseTime(String? timeStr) {
        if (timeStr == null) return null;
        final parts = timeStr.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }

      return UserPreferences(
        username: prefs.getString('username') ?? '',
        selectedGenres: prefs.getStringList('selectedGenres') ?? [],
        isGuestUser: prefs.getBool('isGuestUser') ?? true,
        readingFormat: prefs.getString('readingFormat') ?? 'both',
        readingDays: prefs.getStringList('readingDays') ?? [],
        preferredReadingTime: parseTime(prefs.getString('preferredReadingTime')),
      );
    } catch (e) {
      print('Error loading preferences: $e');
      return null;
    }
  }

  /// Save preferences to shared preferences
  Future<void> saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('username', username);
      await prefs.setStringList('selectedGenres', selectedGenres);
      await prefs.setBool('isGuestUser', isGuestUser);
      await prefs.setString('readingFormat', readingFormat);
      await prefs.setStringList('readingDays', readingDays);
      
      if (preferredReadingTime != null) {
        await prefs.setString(
          'preferredReadingTime',
          '${preferredReadingTime!.hour.toString().padLeft(2, '0')}:${preferredReadingTime!.minute.toString().padLeft(2, '0')}',
        );
      }
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }
} 