# Google OAuth Setup for SafeRemit Mobile

## Package Information
- **Package Name**: `finance.saferemit.saferemit_mobile`
- **Bundle ID (iOS)**: `finance.saferemit.saferemitMobile`

## Debug Keystore Fingerprints

### SHA-1 (for Google Cloud Console)
```
B5:C1:24:8F:5A:A8:77:D7:73:A8:6C:F8:B9:51:2C:8C:CD:75:32:D8
```

### SHA-256
```
36:A8:F5:F5:DF:8A:0E:9D:E3:70:E9:19:B4:B1:F3:B0:C8:66:86:D6:92:7E:EE:CF:E7:EF:2E:68:FE:EA:99:73
```

### Keystore Details
- **Location**: `~/.android/debug.keystore`
- **Alias**: `androiddebugkey`
- **Store Password**: `android`
- **Key Password**: `android`
- **Valid Until**: December 27, 2054

---

## Google Cloud Console Setup Steps

### 1. Create Android OAuth Client ID ✅ COMPLETED

**Android Client ID** (for app authentication):
```
400743682454-4vj7okp70dggf19vhojdpgo18ekp2g3m.apps.googleusercontent.com
```

This was created with:
- **Application type**: Android
- **Name**: SafeRemit Android (Debug)
- **Package name**: `finance.saferemit.saferemit_mobile`
- **SHA-1 certificate fingerprint**: `B5:C1:24:8F:5A:A8:77:D7:73:A8:6C:F8:B9:51:2C:8C:CD:75:32:D8`

### 2. Web Client ID (Already Configured) ✅

**Web Client ID** (for backend token verification):
```
400743682454-44mopbbkc524e8s45ps4tik0nj7qa0mk.apps.googleusercontent.com
```

This is already added to:
- Flutter app: `lib/services/auth_service.dart` (as `serverClientId`)
- Backend: `.env` file (as `GOOGLE_CLIENT_ID`)

**Important Notes**: 
- The **Android Client ID** allows the app to request Google Sign-In
- The **Web Client ID** is used by the backend to verify the ID tokens
- OAuth access is currently restricted to test users listed on your OAuth consent screen

---

## For Production Release

When you're ready to release the app to Google Play Store, you'll need to:

1. **Create a release keystore** (if you haven't already):
   ```bash
   keytool -genkey -v -keystore ~/saferemit-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias saferemit
   ```

2. **Get the release SHA-1**:
   ```bash
   keytool -keystore ~/saferemit-release-key.jks -list -v
   ```

3. **Create another Android OAuth Client ID** in Google Cloud Console with the release SHA-1

4. **Store the release keystore securely** and add credentials to GitHub Secrets for CI/CD

---

## Testing

After setup, test the Google Sign-In:
1. Build and run the app: `flutter run`
2. Click "Continue with Google" on the welcome screen
3. Select your Google account
4. Should authenticate and redirect to dashboard

---

## Troubleshooting

### Error: "Developer Error" or "Sign in failed"
- Double-check package name matches exactly: `finance.saferemit.saferemit_mobile`
- Verify SHA-1 fingerprint is correct in Google Cloud Console
- Make sure you created an **Android** OAuth client (not Web)

### Error: "API not enabled"
- Enable Google Sign-In API in Google Cloud Console
- Go to: https://console.cloud.google.com/apis/library

### Token verification fails on backend
- Make sure `serverClientId` in Flutter matches your Web Client ID
- Verify backend has `google-auth` package installed
- Check backend logs for specific error messages
