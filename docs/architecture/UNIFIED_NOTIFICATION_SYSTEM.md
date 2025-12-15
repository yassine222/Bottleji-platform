# Unified Notification System Architecture

## Problem Statement

Previously, the system sent **both** push notifications (FCM) and Live Activity updates for the same event. This caused:
- **Delayed Live Activity updates** - Both compete for delivery resources
- **System throttling** - Duplicate content triggers throttling mechanisms
- **Blocked Dynamic Island expansion** - Notification interference prevents expansion
- **Poor user experience** - Users see duplicate notifications

## Solution: Single Source of Truth

The backend now makes unified routing decisions:
- **Devices WITH Live Activity support** → Send Live Activity update ONLY (no FCM notification)
- **Devices WITHOUT Live Activity support** → Send FCM notification ONLY (no Live Activity update)
- **Terminal events** (completed, error) → Send notification after ending Live Activity

## Architecture Components

### 1. Device Capabilities Detection

#### iOS Client (`DeviceCapabilitiesDetector.swift`)
```swift
- liveActivitySupported: Checks ActivityAuthorizationInfo().areActivitiesEnabled
- dynamicIslandSupported: Checks hardware (iPhone 14 Pro+)
- iosVersion: UIDevice.current.systemVersion
```

#### Android Client (Planned)
```dart
- supportsOngoingNotification: Android 8.0+
- supportsForegroundService: Android 8.0+
- androidVersion: Device info
```

#### Flutter Service (`device_capabilities_service.dart`)
- Detects platform capabilities at app launch
- Reports to backend via `/device-capabilities` endpoint
- Called when:
  - App launches (after login)
  - Capabilities change (user enables/disables features)
  - FCM token is updated

### 2. Backend Storage

#### DeviceCapabilities Schema
```typescript
{
  userId: ObjectId,
  fcmToken: string,  // Used as device identifier
  platform: 'ios' | 'android',
  
  // iOS capabilities
  liveActivitySupported: boolean,
  dynamicIslandSupported: boolean,
  iosVersion: string,
  
  // Android capabilities
  supportsOngoingNotification: boolean,
  supportsForegroundService: boolean,
  androidVersion: string,
  
  appVersion: string,
  isActive: boolean,
  lastUpdatedAt: Date
}
```

**Indexes:**
- `{ userId: 1, fcmToken: 1 }` (unique compound index)
- `{ userId: 1, isActive: 1 }` (for active device lookups)

### 3. Unified Notification Service

#### Decision Logic (`unified-notification.service.ts`)

```typescript
IF terminal_event:
  → Send notification (Live Activity ends first)
  
ELSE IF iOS AND liveActivitySupported:
  → Send Live Activity update ONLY
  → DO NOT send FCM notification
  
ELSE:
  → Send FCM notification ONLY
  → DO NOT send Live Activity update
```

#### Key Methods

**`sendDropStatusUpdate()`**
- Checks device capabilities via FCM token
- Routes to appropriate delivery method
- Returns decision: `'live_activity' | 'notification' | 'none'`

**`shouldUseLiveActivity()`**
- Helper for quick capability checks
- Used by DropoffsService for conditional logic

### 4. Integration with DropoffsService

#### Before (Problematic)
```typescript
// Sends BOTH - causes delays
await notificationsGateway.sendNotificationToUser(...)  // FCM
await sendLiveActivityUpdate(...)  // Live Activity
```

#### After (Unified)
```typescript
// Check capabilities first
const hasLiveActivity = await unifiedNotificationService.shouldUseLiveActivity(userId, fcmToken);

if (hasLiveActivity) {
  // Send Live Activity ONLY
  await sendLiveActivityUpdate(...)
  // No FCM notification sent
} else {
  // Send FCM notification ONLY
  await notificationsGateway.sendNotificationToUser(...)
  // No Live Activity update sent
}
```

## API Endpoints

### POST `/device-capabilities`
**Authentication:** Required (JWT)

**Request Body:**
```json
{
  "fcmToken": "device_fcm_token",
  "platform": "ios" | "android",
  "liveActivitySupported": true,  // iOS only
  "dynamicIslandSupported": true,  // iOS only
  "iosVersion": "17.0",  // iOS only
  "supportsOngoingNotification": true,  // Android only
  "supportsForegroundService": true,  // Android only
  "androidVersion": "13",  // Android only
  "appVersion": "1.0.0"
}
```

**Response:**
```json
{
  "_id": "...",
  "userId": "...",
  "fcmToken": "...",
  "platform": "ios",
  "liveActivitySupported": true,
  ...
}
```

## Client Integration

### iOS Flutter Code
```dart
// After login, detect and report capabilities
final capabilitiesService = DeviceCapabilitiesService();
final fcmService = FCMService();

// Check Live Activity support (from native)
final liveActivitySupported = await LiveActivityNativeService().areActivitiesEnabled();

// Report to backend
await capabilitiesService.reportCapabilities(
  fcmToken: fcmService.fcmToken!,
  liveActivitySupported: liveActivitySupported,
  dynamicIslandSupported: false,  // TODO: Detect from native
);
```

### Android Flutter Code (Planned)
```dart
await capabilitiesService.reportCapabilities(
  fcmToken: fcmService.fcmToken!,
  supportsOngoingNotification: true,  // Detect Android version
  supportsForegroundService: true,
);
```

## Flow Diagrams

### Ongoing Event (e.g., "drop accepted")

```
1. DropoffService.assignCollector()
   ↓
2. Get user's FCM token
   ↓
3. Check capabilities: unifiedNotificationService.shouldUseLiveActivity(userId, fcmToken)
   ↓
4a. IF has Live Activity:
     → sendLiveActivityUpdate() ONLY
     → No FCM notification
   
4b. ELSE:
     → sendNotificationToUser() (FCM) ONLY
     → No Live Activity update
```

### Terminal Event (e.g., "drop collected")

```
1. DropoffService.confirmCollection()
   ↓
2. End Live Activity (if exists)
   ↓
3. Send notification (informs user of completion)
   ↓
4. Live Activity already ended, notification is the final message
```

## Benefits

1. **No Duplication** - Only one delivery method per event
2. **Faster Updates** - No competition between FCM and Live Activity
3. **Dynamic Island Works** - No notification interference
4. **Better UX** - Users see appropriate notification type for their device
5. **Scalable** - Easy to add new capability types

## Migration Notes

### Breaking Changes
- None - System is backward compatible
- Old devices without capabilities reported will default to FCM notifications

### Rollout Strategy
1. Deploy backend changes
2. Deploy client capability detection (can be gradual)
3. Monitor logs to see routing decisions
4. Verify no duplicate notifications

## Future Enhancements

1. **Android Ongoing Notifications** - Implement Android foreground service support
2. **Capability Refresh** - Allow users to manually refresh capabilities
3. **Multi-Device Support** - Handle users with multiple devices with different capabilities
4. **Analytics** - Track which delivery method is used per user/device

