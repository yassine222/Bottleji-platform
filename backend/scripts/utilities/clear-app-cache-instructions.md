# 🔧 Clear App Cache Instructions

## Problem
The user `testuser2@gmail.com` has a complete profile in the database, but the app is showing "Edit Profile" instead of the correct status, and navigation is causing a dark screen.

## Root Cause
This is a **frontend caching issue** where the app has old cached data in SharedPreferences that doesn't match the current database state.

## Solution Steps

### Option 1: Clear App Data (Recommended)
1. **Close the Flutter app completely**
2. **Clear app data/cache:**
   - **iOS:** Settings → General → iPhone Storage → Find your app → Offload App
   - **Android:** Settings → Apps → Find your app → Storage → Clear Data
3. **Restart the app**
4. **Login again with:** `testuser2@gmail.com`
5. **The app should now show the correct profile status**

### Option 2: Force Logout via App
1. **In the app, go to Settings/Profile**
2. **Find the logout button**
3. **Logout completely**
4. **Login again with:** `testuser2@gmail.com`

### Option 3: Debug Mode (For Developers)
If you have access to the Flutter app code, you can add a temporary debug button to clear SharedPreferences:

```dart
// Add this to any screen temporarily
ElevatedButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('SharedPreferences cleared');
  },
  child: Text('Clear Cache (Debug)'),
)
```

## Expected Result
After clearing the cache and re-logging in:
- ✅ App should show correct profile status
- ✅ No more dark screen navigation issues
- ✅ Profile should show as complete since user has:
  - Phone number: `4917744955874`
  - Phone verified: `true`
  - Profile complete: `true`
  - Name: `yassine romd`
  - Address: `Sounine, Tunisia`

## Database Status
The user session has been invalidated on the backend, so the next login will fetch fresh data from the server.

## If Problem Persists
If the issue continues after clearing cache:
1. Check if there are multiple users with similar emails
2. Verify the user is logging in with the correct email
3. Check the backend logs for any authentication errors
