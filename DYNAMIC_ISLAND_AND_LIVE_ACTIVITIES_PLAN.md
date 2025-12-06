# Dynamic Island & Live Activities Implementation Plan

## Overview

Implement Dynamic Island (iOS) and Live Activities (Android) to display real-time collection information when a collector is actively navigating to a drop or has an active collection.

---

## 1. What Information to Display

### Primary Information (Always Visible):
1. **Collection Timer** - Time elapsed since collection started (e.g., "12:34")
2. **Distance to Destination** - Current distance to drop (e.g., "1.2 km")
3. **Status Indicator** - Visual indicator (icon) showing collection is active

### Secondary Information (Expandable/Detailed):
4. **ETA** - Estimated time of arrival (e.g., "5 min")
5. **Transportation Mode** - Icon showing mode (walking, driving, cycling)
6. **Drop Address** - Shortened address or drop ID
7. **Earnings** - Current session earnings (if available)

### Status Updates:
- **Navigating** - Collector is on the way to drop
- **At Destination** - Collector has reached the drop location
- **Collecting** - Collection is in progress (timer running)
- **Completed** - Collection completed successfully

---

## 2. When to Show/Hide

### Show Dynamic Island/Live Activity:
- ✅ When collector enters navigation screen (`NavigationScreen` is active)
- ✅ When collection attempt is created and active
- ✅ When timer is running (collection in progress)
- ✅ When app goes to background during active collection

### Hide Dynamic Island/Live Activity:
- ❌ When collector exits navigation screen (not navigating)
- ❌ When collection is completed (successfully collected)
- ❌ When collection is cancelled
- ❌ When collection expires
- ❌ When app is closed/terminated
- ❌ When user logs out

---

## 3. iOS Implementation (Dynamic Island)

### 3.1 Requirements

**iOS Version:** iOS 16.1+ (Dynamic Island available)
**Device Support:** iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 series, iPhone 16 series
**Framework:** ActivityKit (iOS 16.1+)

### 3.2 Implementation Steps

#### Step 1: Add ActivityKit Framework
- Add `activity_kit` to `pubspec.yaml`
- Configure iOS entitlements for Live Activities

#### Step 2: Create Activity Attributes
- Define `CollectionActivityAttributes` class
- Include: timer, distance, ETA, status, drop info

#### Step 3: Start Activity
- When navigation screen is initialized
- When collection attempt is created
- Update activity with initial state

#### Step 4: Update Activity
- Update every 5-10 seconds with new data
- Update on significant events (distance changes, status changes)
- Use `ActivityKit.update()` to push updates

#### Step 5: End Activity
- When collection completes
- When collection is cancelled
- When navigation screen is closed
- Use `ActivityKit.end()` to dismiss

### 3.3 Dynamic Island Display Modes

#### Compact Mode (Always Visible):
```
┌─────────────────────┐
│  ⏱️ 12:34  📍 1.2km  │
└─────────────────────┘
```
- Timer and distance
- Minimal space

#### Expanded Mode (When Tapped):
```
┌─────────────────────────────┐
│  Collection in Progress     │
│  ⏱️ 12:34  📍 1.2km  🚗 5min │
│  Drop: 123 Main St...        │
│  Earnings: $2.50             │
└─────────────────────────────┘
```
- Full details
- ETA, address, earnings

### 3.4 Code Structure

```dart
// iOS Activity Service
class IOSActivityService {
  // Start Dynamic Island activity
  Future<void> startCollectionActivity({
    required String dropId,
    required String dropAddress,
    required Duration elapsedTime,
    required double distance,
    required String eta,
    required String transportMode,
  });
  
  // Update activity data
  Future<void> updateCollectionActivity({
    required Duration elapsedTime,
    required double distance,
    required String eta,
    required String status,
  });
  
  // End activity
  Future<void> endCollectionActivity();
}
```

---

## 4. Android Implementation (Live Activities)

### 4.1 Requirements

**Android Version:** Android 12+ (API 31+) for Live Activities
**Alternative:** Ongoing notifications with expanded layouts (Android 8.0+)
**Framework:** `flutter_local_notifications` (already installed)

### 4.2 Implementation Options

#### Option A: Live Activities (Android 12+)
- Use Android's Live Activities API
- Similar to iOS Dynamic Island
- Requires Android 12+ (API 31+)

#### Option B: Persistent Notification (Android 8.0+)
- Ongoing notification that can't be dismissed
- Expanded notification layout
- Shows timer, distance, ETA
- Works on older Android versions

**Recommendation:** Use Option B (Persistent Notification) for broader compatibility

### 4.3 Implementation Steps

#### Step 1: Create Notification Channel
- Create a high-priority notification channel for "Active Collection"
- Cannot be dismissed by user
- Shows in notification shade

#### Step 2: Build Notification Layout
- Use `BigTextStyle` or custom layout
- Display: timer, distance, ETA, status
- Update notification every 5-10 seconds

#### Step 3: Show Notification
- When navigation screen is active
- Set as ongoing (can't be dismissed)
- High priority (stays visible)

#### Step 4: Update Notification
- Update every 5-10 seconds
- Update on significant events
- Use `flutter_local_notifications.update()`

#### Step 5: Dismiss Notification
- When collection completes
- When collection is cancelled
- When navigation screen closes
- Use `flutter_local_notifications.cancel()`

### 4.4 Notification Display

#### Collapsed View:
```
┌─────────────────────────────┐
│ Bottleji                    │
│ ⏱️ 12:34  📍 1.2km  🚗 5min │
└─────────────────────────────┘
```

#### Expanded View:
```
┌─────────────────────────────┐
│ Collection in Progress      │
│ ⏱️ Timer: 12:34             │
│ 📍 Distance: 1.2 km         │
│ 🚗 ETA: 5 minutes           │
│ 📍 Drop: 123 Main St...     │
│ 💰 Earnings: $2.50          │
└─────────────────────────────┘
```

### 4.5 Code Structure

```dart
// Android Notification Service
class AndroidLiveActivityService {
  static const int COLLECTION_NOTIFICATION_ID = 1001;
  
  // Show persistent notification
  Future<void> showCollectionActivity({
    required String dropId,
    required String dropAddress,
    required Duration elapsedTime,
    required double distance,
    required String eta,
    required String transportMode,
  });
  
  // Update notification
  Future<void> updateCollectionActivity({
    required Duration elapsedTime,
    required double distance,
    required String eta,
    required String status,
  });
  
  // Dismiss notification
  Future<void> dismissCollectionActivity();
}
```

---

## 5. Unified Service (Platform-Agnostic)

### 5.1 Service Interface

```dart
// Unified Live Activity Service
class LiveActivityService {
  // Start live activity
  Future<void> startCollectionActivity({
    required String dropId,
    required String dropAddress,
    required Duration elapsedTime,
    required double distance,
    required String eta,
    required String transportMode,
  });
  
  // Update activity
  Future<void> updateCollectionActivity({
    required Duration elapsedTime,
    required double distance,
    required String eta,
    required String status,
    String? earnings,
  });
  
  // End activity
  Future<void> endCollectionActivity();
  
  // Check if supported
  bool isSupported();
}
```

### 5.2 Platform Detection

```dart
// Check platform and version
bool get isIOSDynamicIslandSupported {
  if (!Platform.isIOS) return false;
  // Check iOS version >= 16.1
  // Check device model (iPhone 14 Pro+)
}

bool get isAndroidLiveActivitySupported {
  if (!Platform.isAndroid) return false;
  // Check Android version >= 12 (API 31)
  // Or use persistent notifications (Android 8.0+)
}
```

---

## 6. Integration Points

### 6.1 Navigation Screen Integration

**File:** `botleji/lib/features/navigation/presentation/screens/navigation_screen.dart`

**Integration Points:**
1. **`initState()`**: Start live activity when navigation begins
2. **`_startLocationMonitoring()`**: Update activity with location data
3. **`_updateDistanceToDestination()`**: Update activity with distance
4. **`_updateTimer()`**: Update activity with timer
5. **`_confirmCollection()`**: End activity on completion
6. **`_handleCancellation()`**: End activity on cancellation
7. **`dispose()`**: End activity when screen is closed

### 6.2 Update Frequency

- **Timer Updates**: Every 1 second (for accurate timer display)
- **Distance Updates**: Every 5-10 seconds (or when distance changes significantly)
- **Location Updates**: Every 5-10 seconds (when location changes)
- **Status Updates**: Immediately (on status changes)

### 6.3 Data Flow

```
Navigation Screen
    ↓
Live Activity Service
    ↓
Platform-Specific Implementation
    ↓
iOS: ActivityKit / Android: Notification Service
    ↓
Dynamic Island / Notification
```

---

## 7. User Experience Flow

### Scenario 1: Starting Collection

1. Collector taps "Start Collection" on a drop
2. Navigation screen opens
3. **Live Activity starts** (Dynamic Island appears / Notification shows)
4. Shows: Timer (00:00), Distance, ETA
5. Updates in real-time as collector moves

### Scenario 2: During Navigation

1. Collector is navigating to drop
2. **Live Activity updates** every 5-10 seconds
3. Timer increments: 00:01 → 00:02 → 00:03...
4. Distance decreases: 1.5 km → 1.2 km → 0.9 km...
5. ETA updates based on speed

### Scenario 3: App Goes to Background

1. Collector switches to another app
2. **Live Activity continues** (Dynamic Island / Notification stays visible)
3. Updates continue in background
4. Collector can see progress without opening app

### Scenario 4: Reaching Destination

1. Collector reaches drop location
2. **Live Activity updates** status to "At Destination"
3. Timer continues running
4. Shows "Confirm Collection" prompt (if possible)

### Scenario 5: Completing Collection

1. Collector confirms collection
2. **Live Activity ends** (Dynamic Island / Notification dismisses)
3. Shows completion message briefly (optional)
4. Returns to normal state

### Scenario 6: Cancelling Collection

1. Collector cancels collection
2. **Live Activity ends** immediately
3. No completion message
4. Returns to normal state

---

## 8. Technical Requirements

### 8.1 Dependencies

**iOS:**
- `activity_kit` (Flutter plugin for ActivityKit)
- Or native Swift code with platform channels

**Android:**
- `flutter_local_notifications` (already installed)
- Android 8.0+ for expanded notifications
- Android 12+ for Live Activities (optional)

### 8.2 Permissions

**iOS:**
- No additional permissions needed
- ActivityKit is built-in

**Android:**
- Notification permission (already handled)
- No additional permissions needed

### 8.3 Platform Channels

If using native code:
- iOS: Swift/Objective-C code for ActivityKit
- Android: Kotlin/Java code for notifications
- Flutter: Platform channels to communicate

---

## 9. Edge Cases & Error Handling

### 9.1 App Lifecycle

- **App goes to background**: Activity continues
- **App is killed**: Activity ends (iOS) / Notification persists (Android)
- **App is restarted**: Check for active collection, restart activity if needed

### 9.2 Network Issues

- **No internet**: Activity continues with cached data
- **Location unavailable**: Show last known distance, disable ETA

### 9.3 Multiple Collections

- **Only one active collection**: Show current collection
- **Multiple collections**: Show most recent/active one

### 9.4 Device Support

- **iOS < 16.1**: Fallback to notification (if possible)
- **Android < 8.0**: Fallback to basic notification
- **Unsupported devices**: Gracefully degrade (no live activity)

---

## 10. Implementation Phases

### Phase 1: iOS Dynamic Island (Basic)
- ✅ Add ActivityKit support
- ✅ Create activity attributes
- ✅ Start/stop activity
- ✅ Display timer and distance

### Phase 2: iOS Dynamic Island (Advanced)
- ✅ Add expanded view
- ✅ Show ETA and earnings
- ✅ Status updates

### Phase 3: Android Persistent Notification
- ✅ Create notification channel
- ✅ Build notification layout
- ✅ Start/stop notification
- ✅ Update notification

### Phase 4: Unified Service
- ✅ Create platform-agnostic service
- ✅ Integrate with navigation screen
- ✅ Handle lifecycle events

### Phase 5: Testing & Refinement
- ✅ Test on iOS devices (iPhone 14 Pro+)
- ✅ Test on Android devices (various versions)
- ✅ Test edge cases
- ✅ Performance optimization

---

## 11. Code Structure

### 11.1 File Organization

```
botleji/lib/core/services/
  ├── live_activity_service.dart          # Unified service interface
  ├── ios_activity_service.dart            # iOS implementation
  └── android_live_activity_service.dart   # Android implementation

botleji/lib/features/navigation/
  └── presentation/screens/
      └── navigation_screen.dart           # Integration point
```

### 11.2 Service Methods

```dart
// Unified Service
abstract class LiveActivityService {
  Future<void> startCollectionActivity(CollectionActivityData data);
  Future<void> updateCollectionActivity(CollectionActivityData data);
  Future<void> endCollectionActivity();
  bool isSupported();
}

// Data Model
class CollectionActivityData {
  final String dropId;
  final String dropAddress;
  final Duration elapsedTime;
  final double distanceToDestination; // in meters
  final String? eta; // "5 min" or null
  final String transportMode; // "walking", "driving", "bicycling"
  final String status; // "navigating", "at_destination", "collecting"
  final double? earnings; // optional
}
```

---

## 12. Testing Plan

### 12.1 iOS Testing
- ✅ Test on iPhone 14 Pro (Dynamic Island)
- ✅ Test on iPhone 13 (fallback behavior)
- ✅ Test background updates
- ✅ Test app lifecycle events

### 12.2 Android Testing
- ✅ Test on Android 12+ (Live Activities if available)
- ✅ Test on Android 8.0+ (Persistent notifications)
- ✅ Test on Android 7.0 (basic notifications)
- ✅ Test background updates
- ✅ Test notification dismissal

### 12.3 Integration Testing
- ✅ Start collection → Activity appears
- ✅ Navigate → Activity updates
- ✅ Complete collection → Activity ends
- ✅ Cancel collection → Activity ends
- ✅ Background app → Activity continues
- ✅ Kill app → Activity behavior

---

## 13. User Benefits

### For Collectors:
- ✅ See collection progress without opening app
- ✅ Quick access to timer and distance
- ✅ Better multitasking (use other apps while collecting)
- ✅ Professional experience (similar to Uber/Bolt)

### For App:
- ✅ Modern, native experience
- ✅ Better user engagement
- ✅ Competitive feature
- ✅ Reduced app switching

---

## 14. Limitations & Considerations

### 14.1 iOS Limitations
- Only available on iPhone 14 Pro and later
- Requires iOS 16.1+
- Limited customization options
- Battery impact (minimal)

### 14.2 Android Limitations
- Notification may be dismissed by user (can be prevented)
- Less prominent than Dynamic Island
- Battery impact (minimal)
- May conflict with other notifications

### 14.3 General Considerations
- **Battery Usage**: Minimal (updates every 5-10 seconds)
- **Data Usage**: Minimal (only location updates)
- **Performance**: Should not impact app performance
- **Privacy**: No additional data collection

---

## 15. Alternative Approaches

### Option 1: Native Implementation (Recommended)
- Use platform-specific code (Swift/Kotlin)
- Maximum control and performance
- Requires platform channels

### Option 2: Flutter Plugin
- Use existing plugins if available
- Easier integration
- May have limitations

### Option 3: Hybrid Approach
- Flutter plugin for basic functionality
- Native code for advanced features
- Best of both worlds

---

## 16. Success Metrics

### Metrics to Track:
1. **Adoption Rate**: % of collectors using live activities
2. **Engagement**: Time spent with live activity visible
3. **Completion Rate**: Collections completed with live activity vs without
4. **User Feedback**: Satisfaction with feature

### Goals:
- 80%+ of collectors use live activities
- Positive user feedback
- No performance degradation
- No significant battery drain

---

## 17. Timeline Estimate

### Phase 1: iOS Basic (2-3 days)
- Setup ActivityKit
- Basic timer and distance display

### Phase 2: iOS Advanced (1-2 days)
- Expanded view
- ETA and earnings

### Phase 3: Android (2-3 days)
- Persistent notifications
- Update mechanism

### Phase 4: Integration (2-3 days)
- Unified service
- Navigation screen integration

### Phase 5: Testing (2-3 days)
- Device testing
- Edge case handling

**Total Estimate: 9-14 days**

---

## 18. Dependencies & Prerequisites

### Required:
- ✅ iOS 16.1+ device for testing (iPhone 14 Pro+)
- ✅ Android 8.0+ device for testing
- ✅ ActivityKit framework access (iOS)
- ✅ Notification permissions (already handled)

### Optional:
- ActivityKit Flutter plugin (if available)
- Native iOS/Android development knowledge

---

## 19. Risk Assessment

### Low Risk:
- ✅ Notification implementation (well-documented)
- ✅ Basic timer/distance display

### Medium Risk:
- ⚠️ ActivityKit integration (newer API)
- ⚠️ Background updates
- ⚠️ Platform-specific code

### Mitigation:
- Start with Android (simpler)
- Test thoroughly on real devices
- Have fallback options

---

## 20. Next Steps (After Approval)

1. **Research**: Check for existing Flutter plugins
2. **Setup**: Add dependencies and permissions
3. **Prototype**: Create basic iOS Dynamic Island
4. **Prototype**: Create basic Android notification
5. **Integrate**: Connect to navigation screen
6. **Test**: Test on real devices
7. **Refine**: Improve UI and performance
8. **Deploy**: Release to users

---

## Summary

### What We're Building:
- **iOS**: Dynamic Island display for active collections
- **Android**: Persistent notification with live updates
- **Both**: Real-time timer, distance, ETA, status

### Key Features:
- ✅ Real-time updates (every 5-10 seconds)
- ✅ Works in background
- ✅ Platform-native experience
- ✅ Automatic start/stop

### Benefits:
- ✅ Better user experience
- ✅ Modern, competitive feature
- ✅ Reduced app switching
- ✅ Professional appearance

---

**Ready for Review!** Please confirm if this plan meets your requirements, and I'll proceed with implementation.

