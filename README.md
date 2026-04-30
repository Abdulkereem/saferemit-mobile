# SafeRemit Mobile App

Flutter mobile application for SafeRemit - Send money globally and trade gift cards.

## Features

### ✅ Implemented
- **Splash Screen** - Custom splash screen with SafeRemit branding
- **Onboarding Slider** - 3-page onboarding with smooth animations
- **WebView Authentication** - Login and registration via web pages
- **Session Management** - Persistent login state
- **Native UI** - Beautiful native Flutter interface for onboarding
- **Hybrid Approach** - WebView for auth, native UI for app shell

### 🚧 Coming Soon
- Dashboard with native UI
- Push notifications
- Biometric authentication
- Offline mode
- Transaction history

## Architecture

```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── splash_screen.dart       # Splash screen with logo
│   ├── onboarding_screen.dart   # Native onboarding slider
│   ├── home_screen.dart         # Main home/welcome screen
│   └── webview_screen.dart      # WebView for auth pages
└── assets/
    └── images/
        └── splashscreen.jpg     # Splash screen image
```

## How It Works

1. **App Launch** → Shows splash screen for 2 seconds
2. **First Time User** → Shows onboarding slider (3 pages)
3. **Returning User** → Goes directly to home/dashboard
4. **Authentication** → Opens WebView to https://saferemit.finance/auth/login
5. **After Login** → Redirects to dashboard (can be native or WebView)

## WebView Integration

The app uses WebView for authentication pages:
- **Login**: `https://saferemit.finance/auth/login`
- **Register**: `https://saferemit.finance/auth/register`
- **Dashboard**: `https://saferemit.finance/dashboard`

When the WebView detects a redirect to `/dashboard`, it automatically:
1. Saves login state
2. Closes the WebView
3. Shows the native dashboard

## Running the App

### Prerequisites
- Flutter SDK 3.41.8+
- Xcode (for iOS)
- Android Studio (for Android)

### Install Dependencies
```bash
flutter pub get
```

### Run on iOS Simulator
```bash
flutter run
```

### Run on Android Emulator
```bash
flutter run
```

### Build for Production

**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

## Configuration

### Update API URLs
Edit `lib/screens/webview_screen.dart` and `lib/screens/home_screen.dart` to change the base URL:

```dart
const String baseUrl = 'https://saferemit.finance';
```

### Update App Icon
Replace the app icon in:
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Android: `android/app/src/main/res/mipmap-*/`

Or use `flutter_launcher_icons` package:
```bash
flutter pub add flutter_launcher_icons
```

### Update Splash Screen
Replace `assets/images/splashscreen.jpg` with your custom splash screen.

## Dependencies

- `webview_flutter` - WebView for authentication pages
- `smooth_page_indicator` - Onboarding page indicators
- `shared_preferences` - Local storage for user preferences
- `http` - HTTP requests
- `url_launcher` - Open external links

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Deployment

### iOS App Store
1. Update version in `pubspec.yaml`
2. Build release: `flutter build ios --release`
3. Open Xcode and archive
4. Upload to App Store Connect

### Google Play Store
1. Update version in `pubspec.yaml`
2. Build release: `flutter build appbundle --release`
3. Upload to Google Play Console

## Troubleshooting

### WebView not loading
- Check internet connection
- Verify the URL is correct
- Check CORS settings on the web server

### Splash screen not showing
- Run `flutter clean`
- Delete `assets/images/splashscreen.jpg` and re-add it
- Run `flutter pub get`

### iOS build fails
- Update CocoaPods: `cd ios && pod install`
- Clean build: `flutter clean && flutter pub get`

## License

Private - SafeRemit Finance

## Support

For issues or questions, contact: info@saferemit.finance
