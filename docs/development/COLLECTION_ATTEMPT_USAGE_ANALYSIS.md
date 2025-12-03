# CollectionAttempt Usage Analysis - Schema Change Impact

## Overview
This document lists all places where `CollectionAttempt` is used in the codebase, so we can update them when adding new fields:
- `currentCollectorLocation` (optional)
- `locationHistory` (optional array)

**Important:** These are **optional fields**, so existing code should continue to work, but we need to ensure proper handling.

---

## 1. Backend (TypeScript/NestJS)

### 1.1 Schema Definition
**File:** `backend/src/modules/dropoffs/schemas/collection-attempt.schema.ts`

**Current Fields:**
- `dropoffId`, `collectorId`, `status`, `outcome`
- `timeline`, `acceptedAt`, `completedAt`, `durationMinutes`
- `dropSnapshot`, `attemptNumber`, `cancellationCount`, `earnings`

**Changes Needed:**
- ✅ Add `currentCollectorLocation` field (optional)
- ✅ Add `locationHistory` array (optional)

**Impact:** Low - Schema change only, no breaking changes

---

### 1.2 Service Methods
**File:** `backend/src/modules/dropoffs/dropoffs.service.ts`

#### `createCollectionAttempt()`
**Lines:** 1959-2058
**Current Usage:**
- Creates new CollectionAttempt
- Sets `status: 'active'`, `outcome: null`
- Initializes `dropSnapshot`, `timeline`

**Changes Needed:**
- ✅ Initialize `currentCollectorLocation: null`
- ✅ Initialize `locationHistory: []`

**Impact:** Low - Just initialization

---

#### `completeCollectionAttempt()`
**Lines:** 2060-2274
**Current Usage:**
- Updates attempt with outcome
- Adds timeline event
- Calculates earnings
- Updates status to 'completed'

**Changes Needed:**
- ✅ Clear `currentCollectorLocation` when outcome is set (cancelled/expired/collected)
- ✅ Optionally preserve `locationHistory` (keep last 100 points)

**Impact:** Medium - Need to add cleanup logic

---

### 1.3 Other Backend Services Using CollectionAttempt

#### `rewards.service.ts`
**Usage:** Likely queries CollectionAttempt for reward calculations
**Impact:** Low - Only reads existing fields

#### `earnings-session.service.ts`
**Usage:** Uses CollectionAttempt for earnings tracking
**Impact:** Low - Only reads `earnings` field

#### `admin.service.ts`
**Usage:** Admin queries for statistics
**Impact:** Low - Only reads existing fields

#### `support-tickets.service.ts`
**Usage:** Links tickets to CollectionAttempt
**Impact:** Low - Only references attempt ID

#### `drops-management.service.ts`
**Usage:** Admin drop management
**Impact:** Low - Only reads existing fields

---

## 2. Flutter App (Dart)

### 2.1 Model Definition
**File:** `botleji/lib/features/collection/data/models/collection_attempt.dart`

**Current Fields (lines 3-18):**
```dart
final String id;
final String dropoffId;
final String collectorId;
final String status;
final String? outcome;
final DateTime acceptedAt;
final DateTime? completedAt;
final int? durationMinutes;
final DropSnapshot dropSnapshot;
final List<TimelineEvent> timeline;
final int attemptNumber;
final int cancellationCount;
final double? earnings;
final DateTime createdAt;
final DateTime updatedAt;
```

**Changes Needed:**
- ✅ Add `currentCollectorLocation` field (optional)
- ✅ Add `locationHistory` array (optional)
- ✅ Update `fromJson()` to handle new fields (with null safety)
- ✅ Update `toJson()` to include new fields

**Impact:** Medium - Model changes required

**New Fields:**
```dart
final CollectorLocation? currentCollectorLocation;
final List<CollectorLocation> locationHistory;
```

**New Class:**
```dart
class CollectorLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final double? speed; // m/s
  final double? heading; // degrees

  CollectorLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  factory CollectorLocation.fromJson(Map<String, dynamic> json) {
    return CollectorLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp']),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    };
  }
}
```

---

### 2.2 API Client
**File:** `botleji/lib/features/collection/data/datasources/collection_attempt_api_client.dart`

**Current Methods:**
- `createCollectionAttempt()`
- `completeCollectionAttempt()`
- `getCollectorAttempts()`
- `getDailyCollectionAttempts()`

**Impact:** Low - These methods just pass data through, no changes needed

---

### 2.3 Providers/Controllers
**File:** `botleji/lib/features/collection/presentation/providers/collection_attempts_provider.dart`

**Current Usage:**
- Loads collection attempts
- Filters by outcome
- Provides data for charts

**Impact:** Low - Only reads existing fields, new fields are optional

---

### 2.4 Stats Screen
**File:** `botleji/lib/features/stats/presentation/screens/stats_screen.dart`

**Lines:** 1298-1674
**Current Usage:**
- Displays recent completed collections
- Shows `dropSnapshot`, `outcome`, `completedAt`, `durationMinutes`
- Uses `_buildRecentCollectionAttemptCard()`

**Impact:** Low - Only displays existing fields

---

### 2.5 Navigation Screen
**File:** `botleji/lib/features/navigation/presentation/screens/navigation_screen.dart`

**Lines:** 605-654
**Current Usage:**
- Gets active collection attempt
- Completes attempt as expired on timeout

**Impact:** Low - Only uses attempt ID and outcome

---

### 2.6 Drops Controller
**File:** `botleji/lib/features/drops/controllers/drops_controller.dart`

**Usage:** Likely queries attempts for drop details
**Impact:** Low - Only reads existing fields

---

### 2.7 Stats API Client
**File:** `botleji/lib/features/stats/data/datasources/stats_api_client.dart`

**Usage:** Fetches collection attempt statistics
**Impact:** Low - Only reads aggregated data

---

### 2.8 Other Files
- `botleji/lib/features/stats/presentation/widgets/stats_chart_carousel.dart` - Charts
- `botleji/lib/core/widgets/active_collection_indicator.dart` - UI indicator
- `botleji/lib/features/support/presentation/screens/support_item_selection_screen.dart` - Support
- `botleji/lib/features/stats/domain/utils/collection_session_calculator.dart` - Calculations

**Impact:** Low - All only read existing fields

---

## 3. Admin Dashboard (TypeScript/React)

### 3.1 Dashboard Page
**File:** `admin-dashboard/src/app/dashboard/page.tsx`

#### Drops Content Section
**Lines:** 3869-3904
**Current Usage:**
- Displays collection attempts for each drop
- Shows `attempt.collector.name`, `attempt.collector.email`
- Shows `attempt.acceptedAt`, `attempt.completedAt`
- Shows `attempt.outcome`, `attempt.durationMinutes`
- Shows `attempt.dropSnapshot` data

**Impact:** Low - Only displays existing fields, new fields are optional

#### Support Content Section
**Lines:** 7338-7453
**Current Usage:**
- Shows CollectionAttempt details in support tickets
- Displays `status`, `outcome`, `durationMinutes`
- Shows timeline events

**Impact:** Low - Only displays existing fields

---

## 4. Summary of Required Changes

### 4.1 Backend Changes

#### High Priority
1. **Schema Update** (`collection-attempt.schema.ts`)
   - Add `currentCollectorLocation` field
   - Add `locationHistory` array

2. **Service Updates** (`dropoffs.service.ts`)
   - Initialize new fields in `createCollectionAttempt()`
   - Clear `currentCollectorLocation` in `completeCollectionAttempt()`

#### Low Priority
- All other services - No changes needed (they only read existing fields)

---

### 4.2 Flutter App Changes

#### High Priority
1. **Model Update** (`collection_attempt.dart`)
   - Add `CollectorLocation` class
   - Add `currentCollectorLocation` field to `CollectionAttempt`
   - Add `locationHistory` field to `CollectionAttempt`
   - Update `fromJson()` with null-safe handling
   - Update `toJson()`

#### Low Priority
- All other files - No changes needed (they only read existing fields)
- New fields are optional, so existing code continues to work

---

### 4.3 Admin Dashboard Changes

#### Low Priority
- No changes needed
- New fields are optional, existing code continues to work
- Can optionally display location data in the future

---

## 5. Migration Strategy

### Phase 1: Backend Schema Update
1. Add new fields to schema (optional, default null/empty)
2. Update `createCollectionAttempt()` to initialize fields
3. Update `completeCollectionAttempt()` to clear location
4. Test that existing code still works

### Phase 2: Flutter Model Update
1. Add `CollectorLocation` class
2. Add fields to `CollectionAttempt` model
3. Update `fromJson()` with null-safe handling
4. Test that existing screens still work

### Phase 3: New Feature Implementation
1. Implement location tracking (collector side)
2. Implement location broadcasting (backend)
3. Implement location viewing (household side)

---

## 6. Testing Checklist

### Backend
- [ ] Schema migration works (existing attempts still readable)
- [ ] `createCollectionAttempt()` initializes new fields
- [ ] `completeCollectionAttempt()` clears location
- [ ] Existing queries still work
- [ ] API responses include new fields (optional)

### Flutter App
- [ ] Model `fromJson()` handles missing new fields (backward compatible)
- [ ] Existing screens still work (stats, navigation, etc.)
- [ ] No crashes when new fields are null
- [ ] New fields can be accessed when present

### Admin Dashboard
- [ ] Dashboard still loads
- [ ] Drop details still show
- [ ] Support tickets still work
- [ ] No errors when new fields are missing

---

## 7. Backward Compatibility

**Key Point:** New fields are **optional**, so:
- ✅ Existing CollectionAttempts (without new fields) still work
- ✅ Old API responses still parse correctly
- ✅ Flutter app handles missing fields gracefully
- ✅ Admin dashboard ignores unknown fields

**No breaking changes!** 🎉

---

## 8. Files That Need Updates

### Must Update (High Priority)
1. `backend/src/modules/dropoffs/schemas/collection-attempt.schema.ts`
2. `backend/src/modules/dropoffs/dropoffs.service.ts` (createCollectionAttempt, completeCollectionAttempt)
3. `botleji/lib/features/collection/data/models/collection_attempt.dart`

### Should Review (Medium Priority)
1. Any code that directly accesses CollectionAttempt fields
2. Any code that serializes/deserializes CollectionAttempt

### No Changes Needed (Low Priority)
- All other files (they only read existing fields)
- Admin dashboard (handles optional fields automatically)

---

## 9. Next Steps

1. ✅ Review this analysis
2. ✅ Update backend schema
3. ✅ Update Flutter model
4. ✅ Test backward compatibility
5. ✅ Implement new location tracking feature

