import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kathawebtoons/screens/reading_progress_screen.dart';
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

  // Disable persistence by default to prevent data leakage between accounts
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: false,
  );

  // TEMP: Run Firestore migration for user documents
  // await migrateUserDocuments();

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
        '/reading-progress': (context) => ReadingProgressScreen(),
      },
    );
  }
}

/// Main navigation widget that handles bottom navigation and page routing
class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _needsOnboarding = false;
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    try {
      await _authService.init();
      final user = await _authService.getCurrentUser();
      final isGuest = await _authService.isGuestUser();

      if (user != null && !isGuest) {
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
        );
        // Check if user has completed onboarding
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (!userDoc.exists) {
          // User hasn't completed onboarding - sign them out and redirect to login
          print('Incomplete onboarding detected. Signing user out and redirecting to login.');
          await _authService.signOut();
          
          setState(() {
            _isLoading = false;
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
            );
          });
          return;
        }
        
        setState(() {
          _needsOnboarding = false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _needsOnboarding = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking auth state: $e');
      setState(() {
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
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.grey.shade800, width: 0.5),
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    _buildNavButton(Icons.home, 'Home', 0),
                    _buildNavButton(Icons.card_membership_rounded, 'Membership', 1),
                    _buildNavButton(Icons.person, 'Profile', 2),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final itemWidth = screenWidth / 3;
                      return Transform.translate(
                        offset: Offset(
                          _animation.value * itemWidth,
                          0,
                        ),
                        child: Container(
                          width: itemWidth,
                          height: 2,
                          color: Colors.lightGreenAccent,
                        ),
                      );
                    },
                  ),
                ),
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
    _animation = Tween<double>(
      begin: _animation.value,
      end: index.toDouble(),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward(from: 0);
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
  Widget _buildNavButton(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: Container(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.lightGreenAccent : Colors.white70,
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.lightGreenAccent : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}