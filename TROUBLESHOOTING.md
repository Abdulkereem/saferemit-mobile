# Troubleshooting Guide

## Google Sign-In Issues

### Error: `PlatformException(sign_in_failed, 00.b: 10:, null)`

This error code 10 means "Developer Error" - the app configuration is incorrect.

#### Solution:

1. **Verify SHA-1 is added to Google Cloud Console**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Find your Android OAuth Client ID
   - Make sure SHA-1 `B5:C1:24:8F:5A:A8:77:D7:73:A8:6C:F8:B9:51:2C:8C:CD:75:32:D8` is added

2. **Check Package Name matches exactly**
   - In Google Cloud Console, package name should be: `finance.saferemit.saferemit_mobile`
   - Check `android/app/build.gradle.kts` - `applicationId` should match

3. **Verify Google Sign-In API is enabled**
   - Go to: https://console.cloud.google.com/apis/library
   - Search for "Google Sign-In API"
   - Make sure it's enabled for your project

4. **Clean and rebuild the app**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Check if you're using the correct Google account**
   - If OAuth consent screen is in "Testing" mode, only test users can sign in
   - Add your test email in: https://console.cloud.google.com/apis/credentials/consent
   - Or publish the app to allow all users

### Error: "Failed to get ID token"

This means the Google Sign-In succeeded but didn't return an ID token.

#### Solution:

1. Make sure you created an **Android** OAuth Client ID (not just Web)
2. The Android client should have the correct SHA-1 fingerprint
3. Try signing out and signing in again

---

## WebView Login Issues

### Issue: Login page freezes / doesn't redirect after successful login

The WebView waits for a redirect to `/dashboard` or other authenticated pages to know login succeeded.

#### Possible causes:

1. **Login failed but no error message shown**
   - Check browser console for errors
   - Verify email/password are correct
   - Check if OTP verification is required

2. **Page redirects to a different URL**
   - WebView looks for: `/dashboard`, `/home`, `/wallet`, `/transactions`
   - If your app redirects elsewhere, update `webview_screen.dart`

3. **JavaScript errors preventing redirect**
   - Open the web app in a browser and check console
   - Make sure there are no JavaScript errors

#### Debug steps:

1. **Test login in a regular browser first**
   - Go to https://saferemit.finance/auth/login
   - Try logging in with the same credentials
   - See where it redirects after success

2. **Enable WebView debugging** (Android only)
   - In `webview_screen.dart`, change:
     ```dart
     AndroidWebViewController.enableDebugging(false);
     ```
     to:
     ```dart
     AndroidWebViewController.enableDebugging(true);
     ```
   - Connect phone to computer
   - Open Chrome and go to: `chrome://inspect`
   - You can see WebView console logs

3. **Check for OTP requirement**
   - If 2FA is enabled, the login might be waiting for OTP
   - The WebView should show the OTP modal
   - If it's stuck, there might be a JavaScript error

---

## Build Issues

### Error: Font Awesome version conflicts

If you see errors about `withValues` or `Color.a`:

```bash
flutter pub upgrade font_awesome_flutter
```

Or downgrade to a compatible version:
```bash
flutter pub add font_awesome_flutter:10.5.0
```

### Error: NDK version mismatch

Add to `android/app/build.gradle.kts`:
```kotlin
android {
    ndkVersion = "27.0.12077973"
}
```

---

## Network Issues

### WebView shows "Connection Error"

1. **Check internet connection**
2. **Verify permissions in AndroidManifest.xml**:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```
3. **Check if server is accessible**:
   ```bash
   curl https://saferemit.finance
   ```

---

## Testing Checklist

Before reporting an issue, please verify:

- [ ] Internet connection is working
- [ ] App has latest code (`git pull`)
- [ ] Dependencies are up to date (`flutter pub get`)
- [ ] App was rebuilt after changes (`flutter clean && flutter run`)
- [ ] Google Cloud Console configuration is correct
- [ ] Test user is added (if OAuth is in Testing mode)
- [ ] Web app login works in a browser
- [ ] No JavaScript errors in web app console

---

## Getting Help

If issues persist:

1. **Check logs**:
   ```bash
   flutter run --verbose
   ```

2. **Enable WebView debugging** (see above)

3. **Test on different device/emulator**

4. **Provide error details**:
   - Full error message
   - Steps to reproduce
   - Device/OS version
   - Screenshots if applicable
