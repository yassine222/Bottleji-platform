# 🔍 Live Activity Update Investigation Report

## Executive Summary
Comprehensive investigation of why Live Activity updates are not being received. This report covers all aspects of the push notification flow from backend to iOS widget.

---

## 1. ✅ **Backend Configuration**

### 1.1 Firebase Admin SDK Initialization
**Status**: ✅ **CONFIGURED**
- Location: `backend/src/modules/notifications/fcm.service.ts`
- Initialization: Checks for `FIREBASE_SERVICE_ACCOUNT_KEY` environment variable
- Fallback: Tries `firebase-service-account.json` file
- **⚠️ ACTION REQUIRED**: Verify Firebase Admin SDK is initialized in production
  - Check backend logs for: `✅ Firebase Admin SDK initialized successfully`
  - If not initialized, Live Activity updates will fail silently

### 1.2 APNs Topic Configuration
**Status**: ✅ **VERIFIED - MATCHES**
- Location: `backend/src/modules/notifications/fcm.service.ts:312`
- Current code:
  ```typescript
  'apns-topic': process.env.APNS_TOPIC || 'com.example.botleji.LiveActivityWidgetExtension'
  ```
- **✅ VERIFIED**: Widget extension bundle ID is `com.example.botleji.LiveActivityWidgetExtension` (from `project.pbxproj`)
- **✅ MATCHES**: Default value matches actual bundle ID
- **⚠️ ACTION REQUIRED**: 
  1. **Set `APNS_TOPIC` environment variable** in backend to: `com.example.botleji.LiveActivityWidgetExtension`
  2. This ensures consistency even if default changes
  3. Restart backend after setting environment variable

### 1.3 Push Token Storage
**Status**: ✅ **IMPLEMENTED**
- Endpoint: `POST /dropoffs/:id/live-activity-token`
- Location: `backend/src/modules/dropoffs/dropoffs.controller.ts:66-72`
- Storage: MongoDB collection `LiveActivityToken`
- Fields stored:
  - `dropoffId`: Drop ID
  - `activityId`: ActivityKit UUID
  - `pushToken`: Hexadecimal push token
  - `userId`: User who owns the activity
  - `isActive`: Boolean flag (default: true)

### 1.4 Push Notification Sending
**Status**: ✅ **IMPLEMENTED**
- Method: `sendLiveActivityUpdate()` in `FCMService`
- Uses Firebase Admin SDK to send APNs push notifications
- Payload structure:
  ```typescript
  {
    aps: {
      timestamp: Unix timestamp,
      event: 'update' | 'end',
      'content-state': {
        activityType: 'dropTimeline',
        status: string,
        statusText: string,
        collectorName: string,
        timeAgo: string,
        distanceRemaining?: number
      }
    }
  }
  ```
- APNs headers:
  - `apns-priority`: '10' (high priority)
  - `apns-push-type`: 'liveactivity' ✅
  - `apns-topic`: From environment variable or default

### 1.5 When Updates Are Sent
**Status**: ✅ **IMPLEMENTED**
Updates are sent in these scenarios:
1. **Drop Accepted**: `assignCollector()` → sends update with status "accepted"
2. **Collector Location Update**: `broadcastLocationToHousehold()` → sends update with `distanceRemaining`
3. **Collection Confirmed**: `confirmCollection()` → sends "end" event
4. **Drop Cancelled**: `cancelAcceptedDrop()` → sends "end" event
5. **Drop Expired**: `cleanupExpiredAcceptedDrops()` → sends "end" event

---

## 2. ✅ **Flutter App Configuration**

### 2.1 Push Token Registration
**Status**: ✅ **IMPLEMENTED**
- Location: `botleji/lib/core/services/live_activities_package_service.dart:71-100`
- Flow:
  1. `live_activities` package creates activity
  2. Package emits `ActiveActivityUpdate` with push token
  3. App sends token to backend: `POST /dropoffs/:dropId/live-activity-token`
  4. Backend stores token in MongoDB

### 2.2 Activity Creation
**Status**: ✅ **IMPLEMENTED**
- Method: `startDropTimelineActivity()` in `LiveActivitiesPackageService`
- Creates activity with initial state
- Maps `dropId` → `activityId` for future updates

---

## 3. ⚠️ **iOS Widget Extension Configuration**

### 3.1 Bundle Identifier
**Status**: ⚠️ **NEEDS VERIFICATION**
- **CRITICAL**: The bundle ID must match the `APNS_TOPIC` in backend
- Check in Xcode:
  1. Open `botleji/ios/Runner.xcworkspace`
  2. Select `LiveActivityWidgetExtension` target
  3. Go to "Signing & Capabilities"
  4. Check "Bundle Identifier" (should be something like `com.yourcompany.botleji.LiveActivityWidgetExtension`)
  5. **This must match `APNS_TOPIC` environment variable in backend**

### 3.2 App Groups
**Status**: ✅ **CONFIGURED**
- App Group: `group.com.example.botleji`
- Used for sharing data between app and widget extension
- Configured in both `Runner.entitlements` and `LiveActivityWidgetExtensionExtension.entitlements`

### 3.3 Live Activities Entitlement
**Status**: ✅ **CONFIGURED**
- Required for Live Activities to work
- Should be enabled in Apple Developer Portal

---

## 4. 🔴 **POTENTIAL ISSUES IDENTIFIED**

### Issue #1: APNs Topic Mismatch ⚠️ **HIGH PRIORITY**
**Problem**: The `APNS_TOPIC` environment variable may not match the actual widget extension bundle ID.

**Impact**: Push notifications will be rejected by APNs if the topic doesn't match.

**Solution**:
1. Check actual bundle ID in Xcode
2. Set `APNS_TOPIC` environment variable in backend to match
3. Restart backend server

**How to Check**:
```bash
# In Xcode, check the bundle identifier for LiveActivityWidgetExtension target
# Then verify in backend environment:
echo $APNS_TOPIC
# Should output: com.yourcompany.botleji.LiveActivityWidgetExtension
```

### Issue #2: Firebase Admin SDK Not Initialized ⚠️ **MEDIUM PRIORITY**
**Problem**: If Firebase Admin SDK fails to initialize, `sendLiveActivityUpdate()` will return `false` silently.

**Impact**: No push notifications will be sent.

**How to Check**:
- Check backend logs on startup for:
  - `✅ Firebase Admin SDK initialized successfully` OR
  - `❌ Firebase Admin SDK not initialized`
- If not initialized, check:
  - `FIREBASE_SERVICE_ACCOUNT_KEY` environment variable is set
  - Service account JSON is valid
  - Firebase project has APNs configured

### Issue #3: Push Tokens Not Being Stored ⚠️ **MEDIUM PRIORITY**
**Problem**: If push tokens aren't being sent from Flutter app to backend, updates can't be sent.

**How to Check**:
1. Check Flutter logs for:
   - `📤 Sending Live Activity push token to backend`
   - `✅ Live Activity push token sent to backend successfully`
2. Check backend logs for:
   - `✅ Live Activity push token stored: dropoffId=..., activityId=...`
3. Check MongoDB:
   ```javascript
   db.liveactivitytokens.find().pretty()
   ```
   Should show stored tokens with `isActive: true`

### Issue #4: Push Notifications Being Sent But Not Received ⚠️ **MEDIUM PRIORITY**
**Problem**: Backend sends push notifications, but widget doesn't receive them.

**Possible Causes**:
1. **APNs Certificate/Key Not Configured in Firebase**
   - Firebase project needs APNs authentication key (.p8 file) or certificate
   - Check Firebase Console → Project Settings → Cloud Messaging → Apple app configuration
2. **Wrong Environment (Sandbox vs Production)**
   - Development builds use Sandbox APNs
   - Production builds use Production APNs
   - Firebase must be configured for the correct environment
3. **Widget Extension Not Receiving Push**
   - Check Xcode Console for widget extension logs
   - Look for: `✅ ContentState decoded: ...` when push arrives
   - If no logs, widget isn't receiving push

### Issue #5: Payload Structure Mismatch ⚠️ **LOW PRIORITY**
**Problem**: The payload structure might not match what the widget expects.

**Current Payload**:
```json
{
  "aps": {
    "timestamp": 1234567890,
    "event": "update",
    "content-state": {
      "activityType": "dropTimeline",
      "status": "accepted",
      "statusText": "Accepted",
      "collectorName": "John Doe",
      "timeAgo": "Just now",
      "distanceRemaining": 290.88
    }
  }
}
```

**Verification**: Check if `live_activities` package expects this exact structure.

---

## 5. 📋 **DEBUGGING CHECKLIST**

### Step 1: Verify Push Token Storage
- [ ] Create a drop and start Live Activity
- [ ] Check Flutter logs: `📤 Sending Live Activity push token to backend`
- [ ] Check backend logs: `✅ Live Activity push token stored`
- [ ] Verify in MongoDB: Token exists with `isActive: true`

### Step 2: Verify APNs Topic
- [ ] Check widget extension bundle ID in Xcode
- [ ] Check `APNS_TOPIC` environment variable in backend
- [ ] Ensure they match exactly

### Step 3: Verify Firebase Admin SDK
- [ ] Check backend startup logs for Firebase initialization
- [ ] Verify `FIREBASE_SERVICE_ACCOUNT_KEY` is set
- [ ] Check Firebase Console → APNs configuration

### Step 4: Verify Push Notification Sending
- [ ] Accept a drop (should trigger update)
- [ ] Check backend logs: `📤 Sending Live Activity update to X token(s)`
- [ ] Check backend logs: `✅ Live Activity update sent successfully`
- [ ] If error, check: `❌ Error sending Live Activity update`

### Step 5: Verify Widget Receiving Push
- [ ] Open Xcode Console (View → Debug Area → Activate Console)
- [ ] Filter by "LiveActivityWidgetExtension"
- [ ] Look for: `✅ ContentState decoded: ...` when update should arrive
- [ ] If no logs, widget isn't receiving push

### Step 6: Verify Payload Structure
- [ ] Check backend logs for actual payload being sent
- [ ] Compare with `live_activities` package documentation
- [ ] Ensure all required fields are present

---

## 6. 🛠️ **RECOMMENDED ACTIONS**

### Immediate Actions:
1. **Verify APNs Topic**: Check bundle ID and set `APNS_TOPIC` environment variable
2. **Check Backend Logs**: Verify Firebase Admin SDK is initialized
3. **Check Push Token Storage**: Verify tokens are being stored in MongoDB

### Debugging Actions:
1. **Add More Logging**: Add detailed logs in `sendLiveActivityUpdate()` to see exact payload
2. **Test Push Manually**: Create a test endpoint to send push notification manually
3. **Check Firebase Console**: Verify APNs authentication is configured

### Long-term Actions:
1. **Add Error Monitoring**: Track push notification failures
2. **Add Metrics**: Track push notification success rate
3. **Add Retry Logic**: Retry failed push notifications

---

## 7. 📊 **TESTING PROCEDURE**

### Test 1: Push Token Registration
1. Create a drop
2. Start Live Activity
3. Verify token is stored in backend
4. Check MongoDB for token

### Test 2: Push Notification Sending
1. Accept a drop (triggers update)
2. Check backend logs for push notification attempt
3. Verify no errors in logs
4. Check Firebase Console for delivery status

### Test 3: Widget Receiving Push
1. Accept a drop
2. Watch Xcode Console for widget logs
3. Verify `ContentState decoded` appears
4. Check if widget UI updates

---

## 8. 📝 **NEXT STEPS**

Based on this investigation, I recommend:

1. **First**: Verify `APNS_TOPIC` matches widget extension bundle ID
2. **Second**: Check backend logs to confirm Firebase Admin SDK is initialized
3. **Third**: Verify push tokens are being stored in MongoDB
4. **Fourth**: Add detailed logging to trace the entire flow
5. **Fifth**: Test with a manual push notification endpoint

Please review this report and let me know which areas you'd like me to investigate further or fix.

