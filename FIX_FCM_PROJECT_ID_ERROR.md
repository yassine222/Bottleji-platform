# Fix: FCM "Unable to detect a Project Id" Error

## Problem

Backend was throwing this error when trying to send FCM notifications:
```
Error: Unable to detect a Project Id in the current environment.
```

## Root Cause

The code was using `admin.messaging().send(message)` which uses the **default Firebase app**, but the default app doesn't have the project ID set. We need to use the **initialized Firebase app** (`this.firebaseApp`) instead.

## Solution

### 1. Use Initialized Firebase App

**Before:**
```typescript
const response = await admin.messaging().send(message);
```

**After:**
```typescript
const response = await this.firebaseApp.messaging().send(message);
```

### 2. Explicitly Set Project ID During Initialization

**Before:**
```typescript
this.firebaseApp = admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
```

**After:**
```typescript
this.firebaseApp = admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: serviceAccount.project_id, // Explicitly set project ID
});
```

### 3. Added Verification

Added a check to verify the Firebase app has a project ID before sending notifications:
```typescript
if (!this.firebaseApp.options.projectId) {
  this.logger.error('Firebase Admin SDK initialized but project ID is missing!');
  return false;
}
```

## Files Changed

- `backend/src/modules/notifications/fcm.service.ts`

## Testing

After the backend redeploys:

1. **Check backend logs** for:
   ```
   ✅ Firebase Admin SDK initialized successfully with service account
   ✅ Firebase Project ID: botleji
   ```

2. **Try sending a notification** (e.g., lock a user from admin dashboard)

3. **Check backend logs** for:
   ```
   ✅ FCM notification sent successfully to user [userId]
   ```

4. **Verify notification received** on the device

## Status

✅ **Fixed** - Changes committed and pushed to trigger Render redeploy.

---

**Next Steps:**
- Wait for Render deployment to complete
- Test notification sending
- Verify notifications are received on devices

