import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/membership_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding/onboarding_welcome.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Main entry point of the application
/// Initializes Firebase and sets up system UI preferences
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Configure system UI
  // Prevent screenshots and screen recording for content protection
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  
  // Lock orientation to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Enable immersive mode for full-screen experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const MyApp());
}

/// Root widget of the application
/// Sets up the theme and initial routing based on authentication state
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Katha Webtoons',
      theme: AppTheme.darkTheme,
      // Use FutureBuilder to handle initial authentication state
      home: FutureBuilder(
        future: AuthService().getCurrentUser(),
        builder: (context, snapshot) {
          // Show splash screen while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          } else {
            // Navigate to main app if user is authenticated, otherwise show login
            if (snapshot.hasData && snapshot.data != null) {
              return MainNavigation();
            } else {
              return LoginScreen();
            }
          }
        },
      ),
      routes: {
        '/home': (context) => MainNavigation(),
        '/onboarding': (context) => OnboardingWelcome(),
        '/guest': (context) => MainNavigation(),
      },
    );
  }
}

/// Main navigation widget that handles bottom navigation and page routing
class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _needsOnboarding = false;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    await _authService.init();
    final user = await _authService.getCurrentUser();
    final isGuest = await _authService.isGuestUser();

    if (user != null && !isGuest) {
      // Check if user has completed onboarding
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      setState(() {
        _needsOnboarding = !userDoc.exists;
        _isLoading = false;
      });
    } else {
      setState(() {
        _needsOnboarding = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsOnboarding) {
      return OnboardingWelcome();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            HomeScreen(),
            MembershipScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.grey.shade800, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.card_membership_rounded, 'Membership', 1),
                _buildNavItem(Icons.person, 'Profile', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle navigation item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  /// Handle back button press
  /// Returns to home screen if not already there, otherwise exits app
  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      _pageController.jumpToPage(0);
      return false;
    }

    SystemNavigator.pop();
    return false;
  }

  /// Build individual navigation items with icon and label
  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _selectedIndex == index ? Colors.lightGreenAccent : Colors.white70,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _selectedIndex == index ? Colors.lightGreenAccent : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}