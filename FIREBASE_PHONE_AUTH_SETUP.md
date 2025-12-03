# Firebase Phone Authentication Setup for OTP Verification

This guide will help you configure Firebase Phone Authentication to send OTP codes for phone number verification (NOT for login - just verification).

## Current Status

✅ **Already Implemented:**
- Flutter `PhoneVerificationService` with Firebase Auth integration
- Backend `/auth/verify-phone` endpoint that accepts Firebase tokens
- Phone number formatting and validation

⚠️ **Currently in Debug Mode:**
- Flutter service has `_debugMode = true` (bypasses Firebase)
- Backend has hardcoded OTP system (`123456`)

---

## Step 1: Enable Phone Authentication in Firebase Console

### 1.1 Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**
3. Navigate to **Authentication** → **Sign-in method**

### 1.2 Enable Phone Provider

1. Find **"Phone"** in the sign-in providers list
2. Click on it
3. Toggle **"Enable"** to ON
4. Click **"Save"**

✅ **Phone Authentication is now enabled!**

---

## Step 2: Configure Android App Verification

### 2.1 Get SHA-1 and SHA-256 Fingerprints

Firebase needs your app's SHA fingerprints to verify it's your app sending requests.

#### Option A: Using Gradle (Recommended)

**For Debug Build:**
```bash
cd botleji/android
./gradlew signingReport
```

**For Release Build:**
```bash
cd botleji/android
./gradlew signingReport --variant=release
```

Look for output like:
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

#### Option B: Using Keytool (If you have a keystore)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 2.2 Add SHA Fingerprints to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**
3. Click **⚙️ Project settings**
4. Scroll down to **"Your apps"** section
5. Find your Android app (`com.example.botleji`)
6. Click **"Add fingerprint"**
7. Paste your **SHA-1** fingerprint
8. Click **"Add"**
9. Repeat for **SHA-256** fingerprint

✅ **Android app verification configured!**

---

## Step 3: Update Flutter Code (Disable Debug Mode)

### 3.1 Disable Debug Mode

**File:** `botleji/lib/core/services/phone_verification_service.dart`

**Current code:**
```dart
static const bool _debugMode = true; // Enable debug mode to bypass reCAPTCHA issues
```

**Change to:**
```dart
static const bool _debugMode = false; // Disabled - using Firebase Phone Auth
```

### 3.2 Verify Backend Endpoint

The backend already has a `/auth/verify-phone` endpoint that accepts Firebase tokens. Verify it exists:

**File:** `backend/src/modules/auth/auth.controller.ts`

Should have:
```typescript
@Post('verify-phone')
async verifyPhone(@Request() req, @Body() body: { phoneNumber: string; firebaseToken: string }) {
  return this.authService.verifyPhone(req.user.id, body.phoneNumber, body.firebaseToken);
}
```

✅ **Code is ready!**

---

## Step 4: Test Configuration

### 4.1 Build and Run App

```bash
cd botleji
flutter clean
flutter pub get
flutter run
```

### 4.2 Test Phone Verification Flow

1. Go to profile setup or phone verification screen
2. Enter a valid phone number (e.g., `+491234567890`)
3. Click "Send Verification Code"
4. Check logs for:
   ```
   🔍 PhoneVerificationService: SMS code sent successfully!
   🔍 PhoneVerificationService: VerificationId: [verification-id]
   ```

### 4.3 Receive SMS Code

- You should receive an SMS with a 6-digit code
- Enter the code in the app
- Check logs for:
   ```
   🔍 PhoneVerificationService: Firebase verification successful
   🔍 PhoneVerificationService: Backend verification successful
   ```

---

## Step 5: Handle reCAPTCHA (Android)

### 5.1 Automatic App Verification

Firebase will try to automatically verify your app using:
- **SafetyNet** (Android 6.0+)
- **Play Integrity API** (Android 8.0+)

If automatic verification fails, Firebase will show a reCAPTCHA challenge.

### 5.2 Testing reCAPTCHA

- **Debug builds:** May show reCAPTCHA more often
- **Release builds:** Usually auto-verifies without reCAPTCHA
- **Emulator:** Will always show reCAPTCHA (use physical device for testing)

### 5.3 If reCAPTCHA Appears

This is normal! The user will see a reCAPTCHA challenge that they need to complete before receiving the SMS code.

---

## Step 6: iOS Configuration (When Apple Developer Program is Approved)

### 6.1 Configure APNs

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**
3. Click **⚙️ Project settings**
4. Go to **"Cloud Messaging"** tab
5. Upload your APNs Authentication Key (`.p8` file)
   - See `FCM_SETUP_GUIDE.md` for detailed instructions

### 6.2 iOS App Verification

iOS uses APNs for verification, so no SHA fingerprints needed. Just ensure:
- APNs is configured in Firebase Console
- App is running on a physical device (simulator won't work)

---

## Troubleshooting

### Issue: "reCAPTCHA verification failed"

**Possible causes:**
1. SHA fingerprints not added to Firebase
2. App not properly signed
3. Network issues

**Solutions:**
- Verify SHA fingerprints are added in Firebase Console
- Ensure you're using the correct keystore
- Try on a physical device instead of emulator
- Check internet connection

### Issue: "Invalid phone number format"

**Possible causes:**
1. Phone number not in international format
2. Missing country code

**Solutions:**
- Ensure phone number starts with `+` (e.g., `+491234567890`)
- The service auto-formats, but verify the input

### Issue: "SMS not received"

**Possible causes:**
1. Phone number incorrect
2. Firebase quota exceeded
3. Carrier blocking SMS

**Solutions:**
- Verify phone number format
- Check Firebase Console for quota limits
- Try a different phone number
- Check spam folder (some carriers filter verification SMS)

### Issue: "Verification failed - Invalid code"

**Possible causes:**
1. Code expired (5 minutes)
2. Wrong code entered
3. Verification ID expired

**Solutions:**
- Request a new code if expired
- Double-check the code entered
- Request new verification if ID expired

### Issue: "Too many SMS requests"

**Possible causes:**
1. Firebase rate limiting
2. Too many attempts

**Solutions:**
- Wait a few minutes before retrying
- Check Firebase Console for quota limits
- Use test phone numbers for development

---

## Firebase Phone Auth Quotas

### Free Tier Limits:
- **SMS per day:** 50 SMS/day per project
- **SMS per month:** 10,000 SMS/month per project

### Upgrade Options:
- **Blaze Plan:** Pay-as-you-go pricing
- **Contact Firebase Support:** For higher limits

### Test Phone Numbers:
Firebase provides test phone numbers that don't count against quota:
- See Firebase Console → Authentication → Phone → Test phone numbers

---

## Security Considerations

### 1. Backend Token Verification

The backend should verify Firebase tokens using Firebase Admin SDK:

**File:** `backend/src/modules/auth/auth.service.ts`

**Current implementation:**
```typescript
async verifyPhone(userId: string, phoneNumber: string, firebaseToken: string) {
  // TODO: Verify Firebase token with Admin SDK
  // For now, just trust the token
}
```

**Recommended:**
```typescript
import * as admin from 'firebase-admin';

async verifyPhone(userId: string, phoneNumber: string, firebaseToken: string) {
  try {
    // Verify the Firebase token
    const decodedToken = await admin.auth().verifyIdToken(firebaseToken);
    
    // Verify phone number matches
    if (decodedToken.phone_number !== phoneNumber) {
      throw new BadRequestException('Phone number mismatch');
    }
    
    // Update user
    await this.usersService.update(userId, {
      phoneNumber: phoneNumber,
      isPhoneVerified: true,
      phoneVerificationId: firebaseToken,
    });
    
    return { message: 'Phone verified', isPhoneVerified: true };
  } catch (error) {
    throw new BadRequestException('Invalid Firebase token');
  }
}
```

### 2. Rate Limiting

Consider adding rate limiting to prevent abuse:
- Limit OTP requests per phone number
- Limit verification attempts
- Implement cooldown periods

---

## Quick Reference

### Important Files
- **Flutter Service:** `botleji/lib/core/services/phone_verification_service.dart`
- **Backend Service:** `backend/src/modules/auth/auth.service.ts`
- **Backend Controller:** `backend/src/modules/auth/auth.controller.ts`

### Firebase Console Links
- **Authentication:** https://console.firebase.google.com/project/botleji/authentication/providers
- **Project Settings:** https://console.firebase.google.com/project/botleji/settings/general
- **Phone Auth Settings:** https://console.firebase.google.com/project/botleji/authentication/providers

### Test Commands
```bash
# Get SHA fingerprints
cd botleji/android
./gradlew signingReport

# Clean and rebuild
cd botleji
flutter clean
flutter pub get
flutter run
```

---

## Next Steps

1. ✅ Enable Phone Auth in Firebase Console
2. ✅ Add SHA fingerprints to Firebase
3. ✅ Disable debug mode in Flutter
4. ✅ Test on Android device
5. ⏳ Configure iOS when Apple Developer Program is approved
6. ⏳ Implement Firebase Admin SDK token verification in backend

---

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Verify SHA fingerprints are correct
3. Test on physical device (not emulator)
4. Check Firebase quotas
5. Review Firebase Phone Auth documentation: https://firebase.google.com/docs/auth/android/phone-auth



