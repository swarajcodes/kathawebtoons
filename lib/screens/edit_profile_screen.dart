import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileScreen({Key? key, required this.userProfile}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  File? _profileImage;
  File? _bannerImage;
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.username);
    _usernameController = TextEditingController(text: widget.userProfile.handle);
    _bioController = TextEditingController(text: widget.userProfile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfile) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(image.path);
          } else {
            _bannerImage = File(image.path);
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Validate inputs
      if (_nameController.text.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }
      if (_usernameController.text.trim().isEmpty) {
        throw Exception('Username cannot be empty');
      }

      // Create updated profile
      var updatedProfile = UserProfile(
        uid: widget.userProfile.uid,
        email: widget.userProfile.email,
        username: _nameController.text.trim(),
        handle: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        profileImageUrl: widget.userProfile.profileImageUrl,
        bannerImageUrl: widget.userProfile.bannerImageUrl,
        createdAt: widget.userProfile.createdAt,
        stories: widget.userProfile.stories,
        followers: widget.userProfile.followers,
        following: widget.userProfile.following,
        followersList: widget.userProfile.followersList,
        followingList: widget.userProfile.followingList,
        storyIds: widget.userProfile.storyIds,
      );

      // Upload new profile image if selected
      if (_profileImage != null) {
        try {
          final profileImageUrl = await _userProfileService.uploadProfileImage(
            widget.userProfile.uid,
            _profileImage!,
          );
          updatedProfile = updatedProfile.copyWith(profileImageUrl: profileImageUrl);
        } catch (e) {
          print('Error uploading profile image: $e');
          throw Exception('Failed to upload profile image');
        }
      }

      // Upload new banner image if selected
      if (_bannerImage != null) {
        try {
          final bannerImageUrl = await _userProfileService.uploadBannerImage(
            widget.userProfile.uid,
            _bannerImage!,
          );
          updatedProfile = updatedProfile.copyWith(bannerImageUrl: bannerImageUrl);
        } catch (e) {
          print('Error uploading banner image: $e');
          throw Exception('Failed to upload banner image');
        }
      }

      // Save updated profile
      await _userProfileService.updateUserProfile(updatedProfile);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFFA3D749),
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      print('Error updating profile: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.katha.network/privacy-policy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open privacy policy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      
      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            style: TextStyle(
              color: readOnly ? Colors.grey[600] : Colors.white,
              fontSize: 16,
            ),
            maxLines: label == 'Bio:' ? 3 : 1,
            decoration: InputDecoration(
              hintText: label == 'Bio:' ? 'Write something about yourself...' : '',
              hintStyle: TextStyle(color: Colors.grey[600]),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: label == 'Bio:' ? 12 : 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey[600] : Color(0xFFA3D749),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Image Section
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      image: _bannerImage != null
                          ? DecorationImage(
                              image: FileImage(_bannerImage!),
                              fit: BoxFit.cover,
                            )
                          : widget.userProfile.bannerImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.userProfile.bannerImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white54,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -40),
                  child: Column(
                    children: [
                      // Profile Image
                      Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : widget.userProfile.profileImageUrl.isNotEmpty
                                          ? NetworkImage(widget.userProfile.profileImageUrl)
                                              as ImageProvider
                                          : null,
                                  child: _profileImage == null &&
                                          widget.userProfile.profileImageUrl.isEmpty
                                      ? Icon(Icons.person, size: 50, color: Colors.white54)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFA3D749),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      // Form Fields
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField('Name:', _nameController),
                            SizedBox(height: 20),
                            _buildTextField('Username:', _usernameController),
                            SizedBox(height: 20),
                            _buildTextField('Email:', TextEditingController(text: widget.userProfile.email), readOnly: true),
                            SizedBox(height: 20),
                            _buildTextField('Bio:', _bioController),
                            SizedBox(height: 16),
                            Text(
                              'Please note that email cannot be changed. Name and Username can only be changed once in 30 days.',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 32),
                            Divider(color: Colors.grey[900], thickness: 1),
                            SizedBox(height: 16),
                            // Privacy Policy
                            TextButton(
                              onPressed: _launchPrivacyPolicy,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFFA3D749),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Delete Account Button
                            TextButton(
                              onPressed: () {
                                // TODO: Show delete account confirmation
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                'Request Account Deletion',
                                style: TextStyle(
                                  color: Colors.red[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            // Logout Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleLogout,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFA3D749),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3D749)),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 