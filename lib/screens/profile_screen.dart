import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kathawebtoons/services/user_profile_service.dart';
import 'package:kathawebtoons/models/user_profile.dart';
import 'package:kathawebtoons/screens/reading_progress_screen.dart';
import '../models/reading_progress_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:kathawebtoons/services/reading_progress_service.dart';
import '../models/comic_model.dart';
import '../screens/comic_detail_screen.dart';
import '../screens/edit_profile_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  const ProfileScreen({Key? key, this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutomaticKeepAliveClientMixin {
  File? _profileImage;
  final picker = ImagePicker();
  final AuthService _authService = AuthService();
  final UserProfileService _userProfileService = UserProfileService();
  final ReadingProgressService _progressService = ReadingProgressService();

  // Cache for profile data
  UserProfile? _cachedProfile;
  bool _profileLoading = false;

  // Cache for reading progress
  List<Map<String, dynamic>> _cachedProgress = [];
  bool _progressLoading = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
    });
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Pick Image"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text("Remove Image"),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.grey[900]!.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'No',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Yes',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await _authService.signOut();
        if (!mounted) return;

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
  }

  void _showSettingsMenu(BuildContext context, UserProfile profile) {
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    final Offset offset = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 110,
        offset.dy + size.height + 5,
        offset.dx + size.width - 10,
        offset.dy + size.height + 5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[900],
      elevation: 8,
      constraints: BoxConstraints(
        minWidth: 150,
        maxWidth: 150,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          height: 40,
          child: Row(
            children: [
              Text(
                '✏️',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 8),
              Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          height: 40,
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red[400],
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(
              userProfile: profile,
            ),
          ),
        );
      } else if (value == 'logout') {
        _handleLogout(context);
      }
    });
  }

  Future<void> _loadProfileData(String profileUid) async {
    if (_cachedProfile != null && !_profileLoading) return;

    setState(() => _profileLoading = true);
    try {
      final profile = await _userProfileService.getUserProfile(profileUid);
      setState(() {
        _cachedProfile = profile;
        _profileLoading = false;
      });
    } catch (e) {
      setState(() => _profileLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String? profileUid = widget.uid ?? currentUser?.uid;

    if (profileUid == null) {
      return _buildGuestProfile();
    }

    // Load profile data if not already cached
    if (_cachedProfile == null) {
      _loadProfileData(profileUid);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: _cachedProfile == null
          ? Center(child: CircularProgressIndicator())
          : _buildProfileContent(_cachedProfile!, currentUser),
    );
  }

  Widget _buildProfileContent(UserProfile profile, User? currentUser) {
    final isOwnProfile = currentUser != null && profile.uid == currentUser.uid;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: Colors.black,
          flexibleSpace: Stack(
            clipBehavior: Clip.none,
            children: [
              FlexibleSpaceBar(
                background: profile.bannerImageUrl.isNotEmpty
                    ? Image.network(
                  profile.bannerImageUrl,
                  fit: BoxFit.cover,
                )
                    : Container(color: Colors.grey[900]),
              ),
              Positioned(
                left: 24,
                bottom: -35,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: isOwnProfile ? _showImageOptions : null,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!) as ImageProvider
                          : (profile.profileImageUrl.isNotEmpty
                          ? NetworkImage(profile.profileImageUrl)
                          : AssetImage("assets/default_profile.png")) as ImageProvider,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(height: 35),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.username,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '@${profile.handle}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOwnProfile)
                          Builder(
                            builder: (BuildContext context) => IconButton(
                              icon: Icon(Icons.settings, color: Colors.white, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => _showSettingsMenu(context, profile),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.yellow[700], size: 14),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            profile.bio.isNotEmpty ? profile.bio : 'No bio added',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    StreamBuilder<int>(
                      stream: _getStoriesCount(profile.uid),
                      builder: (context, snapshot) {
                        final storiesCount = snapshot.data ?? 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildStat(storiesCount, 'Stories'),
                            SizedBox(width: 24),
                            _buildStat(profile.followers, 'Followers'),
                            SizedBox(width: 24),
                            _buildStat(profile.following, 'Following'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Divider(color: Colors.grey[900]),
              _ProfileStoriesSection(
                userId: profile.uid,
                isOwnProfile: isOwnProfile,
                cachedProgress: _cachedProgress,
                onProgressLoaded: (progress) {
                  setState(() {
                    _cachedProgress = progress;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(int value, String label) {
    String displayValue = value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toString();
    return Column(
      children: [
        Text(
          displayValue,
          style: TextStyle(
            color: Color(0xFFA3D749),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              "You are browsing as a guest",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Log in or sign up to access your profile and save your progress.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA3D749),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Log In / Sign Up',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
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

class _ProfileStoriesSection extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;
  final List<Map<String, dynamic>> cachedProgress;
  final Function(List<Map<String, dynamic>>) onProgressLoaded;

  const _ProfileStoriesSection({
    required this.userId,
    required this.isOwnProfile,
    required this.cachedProgress,
    required this.onProgressLoaded,
  });

  @override
  State<_ProfileStoriesSection> createState() => _ProfileStoriesSectionState();
}

class _ProfileStoriesSectionState extends State<_ProfileStoriesSection> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReadingProgressService _progressService = ReadingProgressService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _inProgressComics = [];

  @override
  void initState() {
    super.initState();
    if (widget.cachedProgress.isEmpty) {
      _loadReadingProgress();
    } else {
      _inProgressComics = widget.cachedProgress;
    }
  }

  Future<void> _loadReadingProgress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final progressSnapshot = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('readingProgress')
          .get();

      final Map<String, List<DocumentSnapshot>> progressByComic = {};
      final List<Map<String, dynamic>> inProgressComics = [];

      for (final doc in progressSnapshot.docs) {
        final data = doc.data();
        final comicId = data['comicId'] as String?;

        if (comicId != null) {
          if (!progressByComic.containsKey(comicId)) {
            progressByComic[comicId] = [];
          }
          progressByComic[comicId]!.add(doc);
        }
      }

      for (final comicId in progressByComic.keys) {
        try {
          final comicDoc = await _firestore
              .collection('comics')
              .doc(comicId)
              .get();

          if (comicDoc.exists) {
            final comic = Comic.fromFirestore(comicDoc);
            await comic.loadEpisodes();

            final progress = await _progressService.getComicProgress(
              comicId,
              comic.episodes.length,
            );

            DateTime latestTimestamp = DateTime(2000);
            for (final doc in progressByComic[comicId]!) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('completedAt')) {
                final timestamp = (data['completedAt'] as Timestamp).toDate();
                if (timestamp.isAfter(latestTimestamp)) {
                  latestTimestamp = timestamp;
                }
              }
            }

            inProgressComics.add({
              'comic': comic,
              'progress': progress,
              'lastReadAt': latestTimestamp,
            });
          }
        } catch (e) {
          print('Error fetching comic $comicId: $e');
        }
      }

      inProgressComics.sort((a, b) =>
          (b['lastReadAt'] as DateTime).compareTo(a['lastReadAt'] as DateTime));

      widget.onProgressLoaded(inProgressComics);

      setState(() {
        _inProgressComics = inProgressComics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reading progress: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[900]!,
          highlightColor: Colors.grey[850]!,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 95,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 20,
                          width: 150,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 14,
                          width: 100,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Container(
                          height: 14,
                          width: 80,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 12,
                              width: 70,
                              color: Colors.white,
                            ),
                            Container(
                              height: 12,
                              width: 90,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 3,
                          color: Colors.white,
                        ),
                        Spacer(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            height: 14,
                            width: 120,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _inProgressComics.isEmpty) {
      return _buildShimmerLoading();
    }
    if (_inProgressComics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            'No stories/comics in progress.',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _inProgressComics.length,
      itemBuilder: (context, index) {
        final item = _inProgressComics[index];
        final comic = item['comic'] as Comic;
        final progress = item['progress'] as double;
        final lastReadAt = item['lastReadAt'] as DateTime;
        final showContinue = widget.isOwnProfile;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Image.network(
                  comic.coverImage,
                  height: 140,
                  width: 95,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        comic.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        comic.author,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded, color: Color(0xFFA3D749), size: 14),
                          SizedBox(width: 4),
                          Text(
                            '${comic.episodes.length} Episodes',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${progress.toInt()}% Completed',
                            style: TextStyle(
                              color: Color(0xFFA3D749),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Last Read: ${_formatDate(lastReadAt)}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey[900],
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA3D749)),
                          minHeight: 3,
                        ),
                      ),
                      if (showContinue) ...[
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ComicDetailScreen(
                                      comic: comic,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                backgroundColor: Colors.transparent,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Continue Reading',
                                    style: TextStyle(
                                      color: Color(0xFFA3D749),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Color(0xFFA3D749),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Stream<int> _getStoriesCount(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('readingProgress')
      .snapshots()
      .map((snapshot) {
    final comicIds = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final comicId = data['comicId'] as String?;
      if (comicId != null) {
        comicIds.add(comicId);
      }
    }
    return comicIds.length;
  });
}