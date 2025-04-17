import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Font Families
  static const String fontFamily = 'Plus Jakarta Sans';
  static const String webnovelFontFamily = 'Merriweather';
  static const String logoFontFamily = 'Cormorant Unicase';

  // Colors
  static const Color primaryColor = Color(0xFFA3D749);
  static const Color secondaryColor = Color(0xFF505050);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color lightText = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF81C784);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color newTagColor = Color(0xFF3C12B2);

  // Spacing
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultRadius = 8.0;

  // Reading Preferences
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
  static const double defaultFontSize = 16.0;
  static const double defaultLineHeight = 1.6;
  static const double defaultLetterSpacing = 0.3;

  /// Logo text style used across the app
  static TextStyle get logoStyle => GoogleFonts.cormorantUnicase(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 1.5,
  );

  /// Tagline text style used in login and splash screens
  static TextStyle get taglineStyle => GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.black54,
    fontWeight: FontWeight.w500,
  );

  /// Episode title style used in episode screens
  static TextStyle episodeTitleStyle(double fontSize) => TextStyle(
    color: darkText,
    fontSize: fontSize + 8,
    fontWeight: FontWeight.bold,
    fontFamily: webnovelFontFamily,
    height: 1.3,
  );

  /// Episode content style used in episode screens
  static TextStyle episodeContentStyle(double fontSize) => TextStyle(
    color: darkText.withOpacity(0.9),
    fontSize: fontSize,
    height: defaultLineHeight,
    fontFamily: webnovelFontFamily,
    letterSpacing: defaultLetterSpacing,
  );

  /// Builds a gradient overlay for top-to-bottom fade
  static BoxDecoration buildTopGradientOverlay() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          darkBackground.withOpacity(0.7),
          Colors.transparent,
        ],
      ),
    );
  }

  /// Builds a gradient overlay for bottom-to-top fade
  static BoxDecoration buildBottomGradientOverlay() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          darkBackground.withOpacity(0.7),
          Colors.transparent,
        ],
      ),
    );
  }

  /// Builds an episode chip used in episode screens
  static Widget buildEpisodeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds a time chip used in episode screens
  static Widget buildTimeChip(String time) {
    return Text(
      time,
      style: TextStyle(
        color: secondaryColor,
        fontSize: 12,
      ),
    );
  }

  /// Builds a progress indicator for episode reading
  static Widget buildReadingProgress(double progress) {
    return Column(
      children: [
        Container(
          height: 3,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: secondaryColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        Container(
          color: darkBackground,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                ),
              ),
              Text(
                "Scroll up to begin reading",
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                ),
              ),
              buildTimeChip("${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}"),
            ],
          ),
        ),
      ],
    );
  }

  // Text Styles
  static TextTheme get textTheme => const TextTheme(
    // Display styles
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: lightText,
    ),
    // Headline styles
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    // Title styles
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: lightText,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: lightText,
    ),
    // Body styles
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: darkText,
    ),
  );

  // Webnovel Text Styles using Google Fonts
  static TextTheme get webnovelTextTheme => TextTheme(
    displayLarge: GoogleFonts.merriweather(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: lightText,
      height: 1.3,
    ),
    displayMedium: GoogleFonts.merriweather(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: lightText,
      height: 1.3,
    ),
    displaySmall: GoogleFonts.merriweather(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: lightText,
      height: 1.3,
    ),
    bodyLarge: GoogleFonts.merriweather(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: darkText,
      height: 1.6,
      letterSpacing: 0.3,
    ),
    bodyMedium: GoogleFonts.merriweather(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: darkText,
      height: 1.6,
      letterSpacing: 0.3,
    ),
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: darkBackground,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    textStyle: textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor.withOpacity(0.3),
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    textStyle: textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  );

  // Card Styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: darkBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: secondaryColor.withOpacity(0.3),
      width: 1,
    ),
  );

  // Input Decoration
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: secondaryColor.withOpacity(0.1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: errorColor),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    hintStyle: textTheme.bodyMedium?.copyWith(
      color: secondaryColor,
    ),
  );

  // App Theme
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    textTheme: textTheme,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: lightText,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    inputDecorationTheme: inputDecorationTheme,
    cardTheme: CardTheme(
      color: darkBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: secondaryColor,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
    ),
  );

  // Reusable Widgets
  static Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: textTheme.titleLarge,
      ),
    );
  }

  static Widget buildChip(String label, {Color? backgroundColor, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: textTheme.titleSmall?.copyWith(
          color: textColor ?? primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  static Widget buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: errorColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(
              color: errorColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a genre chip with glassmorphism effect
  /// @param label The text to display in the chip
  static Widget buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Builds a NEW tag with sparkle emoji
  /// Used to highlight new content across the app
  static Widget buildNewTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
      decoration: BoxDecoration(
        color: newTagColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'NEW',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          SizedBox(width: 2),
          Text(
            '✨',
            style: TextStyle(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a gradient overlay for images
  /// Used in comic headers and hero sections
  static BoxDecoration buildGradientOverlay() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.black.withOpacity(0.7),
          Colors.transparent,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ),
    );
  }
} 