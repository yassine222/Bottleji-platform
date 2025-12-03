# Real-Time Collector Location Tracking - Implementation Plan V2

## Overview
Track collector location in real-time while they're navigating to collect a drop, allowing household users to see the collector's progress on a map. This plan is based on the **CollectionAttempt** schema (not CollectorInteraction).

---

## 1. Current State Analysis

### ✅ What We Already Have:
1. **CollectionAttempt Schema** (Active System)
   - `dropoffId`: Reference to the drop
   - `collectorId`: Reference to the collector
   - `status`: 'active' | 'completed'
   - `outcome`: 'expired' | 'cancelled' | 'collected' | null
   - `dropSnapshot.location`: Contains `{lat, lng}` - **This is the drop location**
   - `timeline`: Array of events with location data
   - `acceptedAt`: When collection started
   - `completedAt`: When collection ended

2. **Location Tracking (Frontend)**
   - `Geolocator` package already integrated
   - Location stream in `NavigationScreen` (`_locationSubscription`)
   - Updates every 5-10 seconds or 10-20 meters
   - High accuracy location available

3. **WebSocket Infrastructure**
   - Socket.IO already set up (`NotificationService`)
   - WebSocket gateway on backend (`NotificationsGateway`)
   - Real-time communication working for notifications

4. **Collection Lifecycle Management**
   - `createCollectionAttempt()`: Creates attempt when collector accepts
   - `completeCollectionAttempt()`: Completes attempt with outcome
   - Navigation screen handles cancellation and expiration

### ❌ What's Missing:
1. **Real-time collector location broadcasting** from collector to backend
2. **Collector location storage** on backend (separate from drop location)
3. **Location viewing** for household users
4. **Location cleanup** when collection ends (cancelled/expired/collected)

---

## 2. Schema Design

### 2.1 CollectionAttempt Schema Updates

**Option A: Add to CollectionAttempt (Recommended)**
```typescript
// Add to CollectionAttempt schema
@Prop({ type: Object, default: null })
currentCollectorLocation?: {
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp: Date;
  speed?: number; // m/s
  heading?: number; // degrees
};

@Prop({ type: [Object], default: [] })
locationHistory?: Array<{
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp: Date;
  speed?: number;
  heading?: number;
}>;
```

**Pros:**
- All data in one place
- Easy to query
- Location history preserved with attempt
- No additional queries needed

**Cons:**
- Document grows over time (but capped at ~100 points)
- Slightly slower updates (but acceptable)

**Option B: Separate Location Tracking Collection**
- More complex
- Requires joins
- Not recommended for MVP

**Decision: Use Option A** ✅

---

## 3. Scenarios & Edge Cases

### 3.1 Normal Flow

**Scenario: Collector accepts drop → Navigates → Collects**

1. **Collection Starts** (`createCollectionAttempt`)
   - CollectionAttempt created with `status: 'active'`
   - `currentCollectorLocation: null`
   - Household user sees: "Collector accepted - waiting for location"

2. **Collector Opens Navigation Screen**
   - Location tracking starts
   - First location broadcast: `collector_location_update`
   - Backend updates `currentCollectorLocation`
   - Backend broadcasts to household: `collector_location_received`
   - Household user sees: Live map with collector marker

3. **Collector Moves**
   - Location updates every 5-10 seconds or 10-20 meters
   - Backend updates `currentCollectorLocation`
   - Backend broadcasts to household
   - Household user sees: Marker moving on map

4. **Collection Completes** (`completeCollectionAttempt` with `outcome: 'collected'`)
   - Location tracking stops
   - `currentCollectorLocation` cleared (set to `null`)
   - Location history preserved in `locationHistory` array
   - Household user sees: "Collection completed" message
   - Tracking UI disappears

---

### 3.2 Cancellation Scenarios

#### Scenario A: Collector Cancels During Navigation

**Flow:**
1. Collector is navigating (location being tracked)
2. Collector clicks "Cancel" button
3. `_handleCancellation()` is called in NavigationScreen
4. `cancelAcceptedDrop()` is called
5. `completeCollectionAttempt()` is called with `outcome: 'cancelled'`
6. Navigation screen closes

**What Should Happen:**
- ✅ **Collector Side:**
  - Stop location broadcasting immediately
  - Clear location tracking state
  - Navigate back to home

- ✅ **Backend Side:**
  - Receive cancellation request
  - Call `completeCollectionAttempt(attemptId, 'cancelled', {...})`
  - Clear `currentCollectorLocation` (set to `null`)
  - Stop accepting new location updates for this attempt
  - Broadcast cancellation event to household

- ✅ **Household Side:**
  - Receive cancellation event via WebSocket
  - Show "Collection cancelled" message
  - Remove collector marker from map
  - Stop location subscription
  - Update drop status to show it's available again

**Implementation:**
```typescript
// Backend: In completeCollectionAttempt()
if (outcome === 'cancelled' || outcome === 'expired' || outcome === 'collected') {
  // Clear current location
  attempt.currentCollectorLocation = null;
  // Preserve location history (optional)
  // attempt.locationHistory = [...]; // Keep last 100 points
}
```

```dart
// Frontend: In _handleCancellation()
void _handleCancellation(CancellationReason reason) async {
  // Stop location broadcasting
  _stopLocationBroadcasting();
  
  // Cancel collection
  await ref.read(dropsControllerProvider.notifier)
      .cancelAcceptedDrop(widget.dropId, reason.value, collectorId);
  
  // Clear state
  await ref.read(navigationControllerProvider.notifier).cancelCollection();
  
  // Navigate back
  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
}
```

---

#### Scenario B: Household Cancels Drop (While Collector is Navigating)

**Flow:**
1. Collector is navigating (location being tracked)
2. Household user cancels the drop from their side
3. Backend receives cancellation
4. Drop status changes to 'cancelled'
5. CollectionAttempt is completed with `outcome: 'cancelled'`

**What Should Happen:**
- ✅ **Backend Side:**
  - Complete collection attempt with `outcome: 'cancelled'`
  - Clear `currentCollectorLocation`
  - Broadcast cancellation to collector via WebSocket

- ✅ **Collector Side:**
  - Receive cancellation event via WebSocket
  - Show "Drop cancelled by household" notification
  - Stop location broadcasting
  - Navigate back to home (or show cancellation dialog)

- ✅ **Household Side:**
  - Drop status updated
  - Collector marker removed from map
  - Location subscription stopped

**Implementation:**
```typescript
// Backend: When household cancels drop
async cancelDrop(dropoffId: string, userId: string) {
  // Find active collection attempt
  const activeAttempt = await this.collectionAttemptModel.findOne({
    dropoffId,
    status: 'active'
  });
  
  if (activeAttempt) {
    // Complete attempt as cancelled
    await this.completeCollectionAttempt(
      activeAttempt._id.toString(),
      'cancelled',
      { reason: 'Cancelled by household user' }
    );
    
    // Notify collector
    this.notificationsGateway.notifyCollector(
      activeAttempt.collectorId.toString(),
      'drop_cancelled',
      { dropoffId, reason: 'Cancelled by household' }
    );
  }
}
```

---

### 3.3 Expiration Scenarios

#### Scenario A: Timer Expires (Collector Takes Too Long)

**Flow:**
1. Collector is navigating (location being tracked)
2. Timer reaches 0 in NavigationScreen
3. `_handleTimeout()` is called
4. `completeCollectionAttempt()` is called with `outcome: 'expired'`
5. Navigation screen shows timeout dialog

**What Should Happen:**
- ✅ **Collector Side:**
  - Stop location broadcasting immediately
  - Show timeout dialog
  - Clear location tracking state
  - Option to go back home

- ✅ **Backend Side:**
  - Receive expiration request
  - Call `completeCollectionAttempt(attemptId, 'expired', {...})`
  - Clear `currentCollectorLocation`
  - Stop accepting new location updates
  - Broadcast expiration event to household

- ✅ **Household Side:**
  - Receive expiration event via WebSocket
  - Show "Collection expired" message
  - Remove collector marker from map
  - Stop location subscription
  - Drop becomes available again (or marked as expired)

**Implementation:**
```dart
// Frontend: In _handleTimeout()
void _handleTimeout({bool forceShow = false}) async {
  // Stop location broadcasting
  _stopLocationBroadcasting();
  
  // Complete attempt as expired
  final activeCollection = ref.read(navigationControllerProvider.notifier).activeCollection;
  if (activeCollection != null) {
    // Get active attempt
    final attempts = await dio.get('.../attempts');
    final activeAttempt = attempts.data.firstWhere((a) => a['status'] == 'active');
    
    // Complete as expired
    await dio.patch('.../attempts/${activeAttempt['_id']}/complete', data: {
      'outcome': 'expired',
      'notes': 'Collection expired - timer timeout',
    });
  }
  
  // Show timeout dialog
  // ...
}
```

---

#### Scenario B: Drop Expires (Time Limit Reached)

**Flow:**
1. Collector is navigating (location being tracked)
2. Drop's expiration time is reached (backend cron job or check)
3. Backend automatically expires the drop
4. CollectionAttempt is completed with `outcome: 'expired'`

**What Should Happen:**
- ✅ **Backend Side:**
  - Cron job or check detects expired drop
  - Complete collection attempt with `outcome: 'expired'`
  - Clear `currentCollectorLocation`
  - Broadcast expiration to both collector and household

- ✅ **Collector Side:**
  - Receive expiration event via WebSocket
  - Show "Drop expired" notification
  - Stop location broadcasting
  - Navigate back to home

- ✅ **Household Side:**
  - Receive expiration event
  - Show "Drop expired" message
  - Remove collector marker
  - Stop location subscription

---

### 3.4 Edge Cases

#### Edge Case 1: Collector Closes App / Goes to Background

**What Should Happen:**
- ✅ **Collector Side:**
  - Location broadcasting stops (app in background)
  - Last known location is preserved in backend
  - When app resumes, location broadcasting resumes

- ✅ **Backend Side:**
  - Keep last known location in `currentCollectorLocation`
  - Mark location as stale if no updates for > 30 seconds
  - Broadcast stale status to household

- ✅ **Household Side:**
  - Show "Collector location may be outdated" indicator
  - Keep showing last known location
  - Update when new location arrives

**Implementation:**
```dart
// Frontend: In didChangeAppLifecycleState()
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
    // Stop location broadcasting
    _stopLocationBroadcasting();
    // Send "going offline" event
    _sendLocationUpdate(null, isOffline: true);
  } else if (state == AppLifecycleState.resumed) {
    // Resume location broadcasting
    _resumeLocationBroadcasting();
  }
}
```

---

#### Edge Case 2: WebSocket Disconnects

**What Should Happen:**
- ✅ **Collector Side:**
  - Detect WebSocket disconnection
  - Queue location updates locally
  - Attempt to reconnect
  - Send queued updates when reconnected

- ✅ **Backend Side:**
  - Keep last known location
  - Mark as stale if no updates for > 30 seconds
  - Accept updates when connection restored

- ✅ **Household Side:**
  - Show "Connection lost" indicator
  - Keep showing last known location
  - Resume updates when connection restored

**Implementation:**
```dart
// Frontend: Queue updates when disconnected
List<Map<String, dynamic>> _queuedLocationUpdates = [];

void _broadcastLocation(LatLng location) {
  if (_notificationService.isConnected) {
    // Send immediately
    _notificationService.sendLocationUpdate(...);
    // Send queued updates
    for (var queued in _queuedLocationUpdates) {
      _notificationService.sendLocationUpdate(...);
    }
    _queuedLocationUpdates.clear();
  } else {
    // Queue for later
    _queuedLocationUpdates.add({
      'location': location,
      'timestamp': DateTime.now(),
    });
  }
}
```

---

#### Edge Case 3: User Viewing on Different Devices

**What Should Happen:**
- ✅ **Backend Side:**
  - Broadcast location to the drop owner's user room: `user:${householdUserId}`
  - All devices where the user is logged in will receive updates automatically
  - No special handling needed - WebSocket rooms handle this

- ✅ **Household Side:**
  - User can view collector location on any device they're logged into
  - Each device independently shows the collector marker
  - Updates are real-time on all devices

**Implementation:**
```typescript
// Backend: Broadcast to drop owner (works for all their devices)
async broadcastLocationToHousehold(dropoffId: string, location: Location) {
  // Get drop owner
  const drop = await this.dropoffModel.findById(dropoffId);
  const householdUserId = drop.userId;
  
  // Broadcast to household user's room (all their devices receive it)
  this.notificationsGateway.server
    .to(`user:${householdUserId}`)
    .emit('collector_location_received', {
      dropoffId,
      location,
    });
}
```

**Note:** This is not a special edge case - it's the normal behavior. When a user is logged in on any device, they can see the collector location for their accepted drops. The WebSocket room system automatically handles multiple devices.

---

#### Edge Case 4: Collector Re-accepts Same Drop (After Cancellation)

**Flow:**
1. Collector cancels collection (attempt 1 completed)
2. Drop becomes available again
3. Collector accepts same drop again
4. New CollectionAttempt created (attempt 2)

**What Should Happen:**
- ✅ **Backend Side:**
  - New CollectionAttempt created with `attemptNumber: 2`
  - `currentCollectorLocation` starts fresh (null)
  - Old attempt's location history preserved

- ✅ **Household Side:**
  - New location tracking starts
  - Old location data not shown (new attempt)

---

#### Edge Case 5: Collection Completed While Household is Viewing

**Flow:**
1. Household user is viewing collector location
2. Collector arrives and confirms collection
3. CollectionAttempt completed with `outcome: 'collected'`

**What Should Happen:**
- ✅ **Collector Side:**
  - Stop location broadcasting
  - Show success screen

- ✅ **Backend Side:**
  - Complete attempt
  - Clear `currentCollectorLocation`
  - Broadcast completion to household

- ✅ **Household Side:**
  - Receive completion event
  - Show "Collection completed" message
  - Remove collector marker
  - Stop location subscription
  - Update drop status

---

## 4. Implementation Plan

### Phase 1: Backend Foundation

#### 1.1 Update CollectionAttempt Schema
- [ ] Add `currentCollectorLocation` field
- [ ] Add `locationHistory` array (optional, for history)
- [ ] Add indexes for performance

#### 1.2 Create Location Tracking Service
- [ ] `updateCollectorLocation(attemptId, location)` - Update current location
- [ ] `getCollectorLocation(attemptId)` - Get current location
- [ ] `clearCollectorLocation(attemptId)` - Clear location (on completion/cancellation)
- [ ] `addLocationToHistory(attemptId, location)` - Add to history (optional)

#### 1.3 WebSocket Events
- [ ] `collector_location_update` - Collector sends location
- [ ] `collector_location_received` - Household receives location
- [ ] `collector_location_stopped` - Location tracking stopped (cancelled/expired/collected)
- [ ] `subscribe_to_collector_location` - Household subscribes to location

#### 1.4 Update completeCollectionAttempt()
- [ ] Clear `currentCollectorLocation` when outcome is set
- [ ] Preserve `locationHistory` (optional)
- [ ] Broadcast stop event to household

#### 1.5 Update createCollectionAttempt()
- [ ] Initialize `currentCollectorLocation: null`
- [ ] Initialize `locationHistory: []`

---

### Phase 2: Collector Side (Navigation Screen)

#### 2.1 Location Broadcasting
- [ ] Add `_broadcastLocation()` method
- [ ] Call in location stream listener
- [ ] Implement smart update frequency (5-10 seconds or 10-20 meters)
- [ ] Add battery optimization

#### 2.2 Lifecycle Management
- [ ] Start broadcasting when navigation starts
- [ ] Stop broadcasting on cancellation (`_handleCancellation`)
- [ ] Stop broadcasting on expiration (`_handleTimeout`)
- [ ] Stop broadcasting on completion (`_confirmCollection`)
- [ ] Handle app background/foreground

#### 2.3 Error Handling
- [ ] Queue updates when WebSocket disconnected
- [ ] Retry logic for failed broadcasts
- [ ] Handle connection loss gracefully

---

### Phase 3: Household Side (Drop Details Modal)

#### 3.1 Location Subscription
- [ ] Subscribe to location updates when drop is accepted
- [ ] Unsubscribe when drop is cancelled/expired/collected
- [ ] Handle WebSocket disconnection

#### 3.2 Map Display
- [ ] Load collector marker icon from `assets/icons/collector-pin.png`
- [ ] Show collector marker on map (using custom icon)
- [ ] Show drop location marker (using existing `drop-pin.png`)
- [ ] Show route from collector to drop (optional)
- [ ] Update marker position smoothly
- [ ] Show ETA and distance

**Collector Marker Icon:**
```dart
// Load collector marker icon
Future<void> _loadCollectorMarker() async {
  try {
    final BitmapDescriptor collectorIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration.empty,
      'assets/icons/collector-pin.png',
    );
    setState(() {
      _collectorMarkerIcon = collectorIcon;
    });
  } catch (e) {
    // Fallback to default marker
    _collectorMarkerIcon = BitmapDescriptor.defaultMarker;
  }
}
```

#### 3.3 Status Display
- [ ] "Collector is on the way" status
- [ ] "Collector location may be outdated" (if stale)
- [ ] "Collection cancelled" message
- [ ] "Collection expired" message
- [ ] "Collection completed" message

#### 3.4 Cleanup
- [ ] Remove marker when collection ends
- [ ] Stop subscription when modal closes
- [ ] Handle navigation away from modal

---

### Phase 4: Testing & Edge Cases

#### 4.1 Test Scenarios
- [ ] Normal flow (accept → navigate → collect)
- [ ] Collector cancels during navigation
- [ ] Household cancels drop
- [ ] Timer expires
- [ ] Drop expires (backend)
- [ ] App goes to background
- [ ] WebSocket disconnects
- [ ] User viewing on different devices (phone/tablet)
- [ ] Collector re-accepts same drop

#### 4.2 Performance Testing
- [ ] Battery impact
- [ ] Network usage
- [ ] Server load
- [ ] Location update frequency

#### 4.3 Privacy & Security
- [ ] Only track during active collection
- [ ] Clear location on completion
- [ ] Verify collector owns the attempt
- [ ] Verify household owns the drop

---

## 5. Data Flow Diagrams

### 5.1 Normal Flow
```
Collector App
  ↓ (Every 5-10s or 10-20m)
  ↓ Location: {lat, lng, accuracy, timestamp}
  ↓ WebSocket: 'collector_location_update'
  ↓
Backend
  ↓ Update CollectionAttempt.currentCollectorLocation
  ↓ Store in locationHistory (optional)
  ↓ WebSocket: 'collector_location_received'
  ↓
Household App
  ↓ Update map marker
  ↓ Show ETA, distance
```

### 5.2 Cancellation Flow
```
Collector App
  ↓ User clicks "Cancel"
  ↓ Stop location broadcasting
  ↓ API: completeCollectionAttempt(outcome: 'cancelled')
  ↓
Backend
  ↓ Clear currentCollectorLocation
  ↓ Complete attempt
  ↓ WebSocket: 'collector_location_stopped'
  ↓
Household App
  ↓ Remove collector marker
  ↓ Show "Collection cancelled" message
  ↓ Stop location subscription
```

### 5.4 User Viewing on Any Device

**How it works:**
- User logs in on Device A (phone) → Can see collector location
- User logs in on Device B (tablet) → Can also see collector location
- Backend broadcasts to `user:${userId}` room
- All devices where user is logged in receive updates automatically
- No special handling needed - WebSocket rooms handle this

---

### 5.5 Expiration Flow
```
Collector App (Timer expires)
  ↓ Timer reaches 0
  ↓ Stop location broadcasting
  ↓ API: completeCollectionAttempt(outcome: 'expired')
  ↓
Backend
  ↓ Clear currentCollectorLocation
  ↓ Complete attempt
  ↓ WebSocket: 'collector_location_stopped'
  ↓
Household App
  ↓ Remove collector marker
  ↓ Show "Collection expired" message
  ↓ Stop location subscription
```

---

## 6. Security & Privacy

### 6.1 Authentication
- ✅ Verify collector owns the CollectionAttempt
- ✅ Verify household user owns the drop
- ✅ Rate limit location updates (prevent spam)

### 6.2 Privacy
- ✅ Only track during active collection (`status: 'active'`)
- ✅ Clear location when collection ends
- ✅ Location history optional (user consent)
- ✅ Clear location data after 24 hours (optional)

### 6.3 Data Validation
- ✅ Validate location coordinates (reasonable bounds)
- ✅ Validate accuracy (not too low)
- ✅ Filter out obviously wrong locations
- ✅ Rate limit updates (max 1 per second)

---

## 7. Performance Considerations

### 7.1 Update Frequency
- **Moving fast (> 5 m/s)**: Every 5 seconds
- **Moving slow (1-5 m/s)**: Every 10 seconds
- **Stopped (< 1 m/s)**: Every 30 seconds
- **Distance-based**: Every 10-20 meters

### 7.2 Battery Optimization
- Reduce frequency when battery is low
- Stop updates when app is backgrounded (optional)
- Use lower accuracy when moving fast

### 7.3 Server Load
- Store latest location in CollectionAttempt (fast access)
- Limit locationHistory to 100 points (prevent document bloat)
- Use indexes for queries

---

## 8. API Endpoints

### 8.1 New Endpoints (Optional)
```typescript
// Get current collector location for a drop
GET /dropoffs/:dropoffId/collector-location
Response: {
  location: { lat, lng, accuracy, timestamp } | null,
  isStale: boolean,
  lastUpdate: Date | null
}
```

### 8.2 WebSocket Events
```typescript
// Collector sends location
'collector_location_update': {
  attemptId: string,
  location: {
    latitude: number,
    longitude: number,
    accuracy: number,
    timestamp: Date,
    speed?: number,
    heading?: number
  }
}

// Household receives location
'collector_location_received': {
  dropoffId: string,
  attemptId: string,
  location: {
    latitude: number,
    longitude: number,
    accuracy: number,
    timestamp: Date,
    estimatedArrival?: number, // seconds
    distanceRemaining?: number // meters
  }
}

// Location tracking stopped
'collector_location_stopped': {
  dropoffId: string,
  attemptId: string,
  reason: 'cancelled' | 'expired' | 'collected'
}

// Subscribe to location updates
'subscribe_to_collector_location': {
  dropoffId: string
}
```

---

## 9. Success Criteria

### 9.1 Technical Metrics
- ✅ Location update latency: < 5 seconds
- ✅ Battery impact: < 5% per hour of tracking
- ✅ WebSocket uptime: > 99%
- ✅ Location accuracy: Within 20 meters

### 9.2 User Experience
- ✅ Household users can see collector location in real-time
- ✅ Smooth marker movement on map
- ✅ Accurate ETA and distance
- ✅ Clear status messages (cancelled/expired/completed)
- ✅ No location leaks (privacy)

---

## 10. Next Steps

1. **Review this plan** with team
2. **Decide on locationHistory** (keep history or just latest?)
3. **Start with Phase 1** (backend foundation)
4. **Test each phase** before moving to next
5. **Iterate based on feedback**

---

## Summary

This plan covers:
- ✅ All cancellation scenarios (collector cancels, household cancels)
- ✅ All expiration scenarios (timer expires, drop expires)
- ✅ Edge cases (app background, WebSocket disconnect, etc.)
- ✅ Privacy and security considerations
- ✅ Performance optimization
- ✅ Clean data flow and cleanup

**Key Points:**
- Use **CollectionAttempt** schema (not CollectorInteraction)
- Store location in `currentCollectorLocation` field
- Clear location when collection ends (cancelled/expired/collected)
- Broadcast via WebSocket for real-time updates
- Handle all edge cases gracefully

