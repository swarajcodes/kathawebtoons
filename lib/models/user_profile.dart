import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String username;
  final String handle;
  final String bio;
  final String profileImageUrl;
  final String bannerImageUrl;
  final Timestamp createdAt;
  final int stories;
  final int followers;
  final int following;
  final List<String> followersList;
  final List<String> followingList;
  final List<String> storyIds;

  UserProfile({
    required this.uid,
    required this.email,
    required this.username,
    required this.handle,
    required this.bio,
    required this.profileImageUrl,
    required this.bannerImageUrl,
    required this.createdAt,
    required this.stories,
    required this.followers,
    required this.following,
    required this.followersList,
    required this.followingList,
    required this.storyIds,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      handle: json['handle'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      bannerImageUrl: json['bannerImageUrl'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      stories: json['stories'] ?? 0,
      followers: json['followers'] ?? 0,
      following: json['following'] ?? 0,
      followersList: List<String>.from(json['followersList'] ?? []),
      followingList: List<String>.from(json['followingList'] ?? []),
      storyIds: List<String>.from(json['storyIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'handle': handle,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'createdAt': createdAt,
      'stories': stories,
      'followers': followers,
      'following': following,
      'followersList': followersList,
      'followingList': followingList,
      'storyIds': storyIds,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? username,
    String? handle,
    String? bio,
    String? profileImageUrl,
    String? bannerImageUrl,
    Timestamp? createdAt,
    int? stories,
    int? followers,
    int? following,
    List<String>? followersList,
    List<String>? followingList,
    List<String>? storyIds,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      createdAt: createdAt ?? this.createdAt,
      stories: stories ?? this.stories,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      followersList: followersList ?? this.followersList,
      followingList: followingList ?? this.followingList,
      storyIds: storyIds ?? this.storyIds,
    );
  }
} 