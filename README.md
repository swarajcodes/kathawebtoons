# Katha Webtoons

A modern webtoon and webnovel reading platform built with Flutter.

## Features

- Beautiful dark theme optimized for reading
- Support for both webtoons and webnovels
- Customizable reading experience
- Offline reading support
- Firebase integration for content management
- Responsive design for all screen sizes

## Design System

The app uses a consistent design system defined in `lib/theme/app_theme.dart`:

### Colors
- Primary: Light Green Accent (`0xFFA3D749`)
- Background: Dark (`0xFF000000`)
- New Tag: Purple (`0xFF3C12B2`)
- Text: Light (`0xFFF5F5F5`) and Dark (`0xFFE0E0E0`)

### Typography
- Main Font: Plus Jakarta Sans
- Webnovel Font: Merriweather
- Logo Font: Cormorant Unicase

### Components
The app includes reusable themed components:
- Genre chips with glassmorphism effect
- NEW tags for fresh content
- Episode chips for navigation
- Reading progress indicators
- Gradient overlays for images
- Custom buttons and input fields

### Reading Experience
- Adjustable font size (12-24px)
- Comfortable line height (1.6)
- Optimized letter spacing (0.3)
- Dark theme for reduced eye strain

## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase account and configuration
- iOS/Android development environment

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/kathawebtoons.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
   - Add your Firebase configuration files
   - Enable Authentication and Firestore

4. Run the app
```bash
flutter run
```

## Project Structure

- `lib/screens/onboarding/` - Onboarding flow screens
  - `onboarding_welcome.dart` - Welcome screen
  - `reading_preferences.dart` - Genre selection
  - `reading_format_preference.dart` - Format preference
  - `reading_schedule.dart` - Reading schedule setup

- `lib/models/` - Data models
  - `user_preferences.dart` - User preferences model

## Dependencies

- Flutter SDK
- Firebase Core
- Cloud Firestore
- Google Fonts
- Cached Network Image
- Archive (for DOCX processing)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
