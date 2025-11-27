# Earnings Tracking System - Implementation Plan

## Overview
Track the amount earned by collectors for each completed collection and display earnings history in the app.

---

## 1. Backend Implementation

### 1.1 Database Schema Changes

#### User Model Updates
- Add `totalEarnings` field (Number, default: 0)
  - Type: `Double` or `Decimal` for precision
  - Tracks **lifetime cumulative earnings** across all sessions
  - Increments each time a collection is completed

#### Collection Attempt Model Updates
- Add `earnings` field (Number, default: 0)
  - Type: `Double` or `Decimal` for precision
  - Stores earnings for this specific collection attempt
  - Only populated when `outcome === 'collected'`
  - Formula: `(plasticBottleCount * 0.025) + (cansCount * 0.06)`

#### New Earnings Session Model (Required - for session tracking)
```typescript
{
  _id: ObjectId,
  userId: String (ref: User),
  date: Date, // Session date (YYYY-MM-DD, start of day)
  sessionEarnings: Number, // Total earnings for this session/day
  collectionCount: Number, // Number of collections in this session
  collectionAttemptIds: [String], // Array of CollectionAttempt IDs in this session
  startTime: Date, // When first collection of session started
  lastCollectionTime: Date, // When last collection of session completed
  isActive: Boolean, // Whether session is still active (last collection within 3 hours)
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `{ userId: 1, date: -1 }` - For quick lookup of user sessions
- `{ userId: 1, isActive: 1 }` - For finding active sessions

#### New Earnings History Model (Optional - for detailed tracking)
```typescript
{
  _id: ObjectId,
  userId: String (ref: User),
  collectionAttemptId: String (ref: CollectionAttempt),
  amount: Number, // Earnings amount
  dropId: String (ref: Dropoff),
  date: Date, // When collection was completed
  createdAt: Date,
  updatedAt: Date
}
```

### 1.2 Backend Service Updates

#### DropoffsService (`dropoffs.service.ts`)

**When completing a collection attempt:**
1. Calculate earnings when `outcome === 'collected'`
   ```typescript
   const earnings = (dropSnapshot.numberOfBottles * 0.025) + (dropSnapshot.numberOfCans * 0.06);
   ```

2. Update CollectionAttempt with earnings
   ```typescript
   await collectionAttemptModel.findByIdAndUpdate(attemptId, {
     earnings: earnings,
     // ... other fields
   });
   ```

3. Update User's **lifetime total earnings**
   ```typescript
   await userModel.findByIdAndUpdate(collectorId, {
     $inc: { totalEarnings: earnings }
   });
   ```

4. **Update or create Earnings Session**
   ```typescript
   const today = new Date();
   today.setHours(0, 0, 0, 0); // Start of day
   
   const session = await earningsSessionModel.findOneAndUpdate(
     {
       userId: collectorId,
       date: today
     },
     {
       $inc: {
         sessionEarnings: earnings,
         collectionCount: 1
       },
       $addToSet: { collectionAttemptIds: attemptId },
       $set: {
         lastCollectionTime: new Date(),
         isActive: true, // Will be updated by cleanup job
         updatedAt: new Date()
       },
       $setOnInsert: {
         startTime: new Date(),
         createdAt: new Date()
       }
     },
     {
       upsert: true,
       new: true
     }
   );
   ```

5. (Optional) Create EarningsHistory entry
   ```typescript
   await earningsHistoryModel.create({
     userId: collectorId,
     collectionAttemptId: attemptId,
     amount: earnings,
     dropId: dropoffId,
     date: new Date()
   });
   ```

#### New EarningsSessionService (`earnings-session.service.ts`)

**Methods:**
- `getActiveSession(userId)`: Get today's active session
- `getSessionByDate(userId, date)`: Get session for specific date
- `getSessionsByDateRange(userId, startDate, endDate)`: Get sessions in range
- `updateSessionActivity()`: Background job to update `isActive` flag (runs every hour)
  - Sets `isActive: false` if `lastCollectionTime` > 3 hours ago

**Session Activity Logic:**
```typescript
// Background job (runs hourly)
async updateSessionActivity() {
  const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
  
  await earningsSessionModel.updateMany(
    {
      isActive: true,
      lastCollectionTime: { $lt: threeHoursAgo }
    },
    {
      $set: { isActive: false }
    }
  );
}
```

#### New Earnings Endpoints

**GET `/api/users/:userId/earnings`**
- Returns user's lifetime total earnings and current session info
- Response:
  ```typescript
  {
    totalEarnings: number, // Lifetime total
    currentSession: {
      id: string,
      date: Date,
      sessionEarnings: number, // Today's total
      collectionCount: number,
      isActive: boolean,
      startTime: Date,
      lastCollectionTime: Date
    } | null
  }
  ```

**GET `/api/users/:userId/earnings/sessions`**
- Returns paginated earnings sessions
- Query params: `page`, `limit`, `startDate`, `endDate`
- Response:
  ```typescript
  {
    sessions: [
      {
        id: string,
        date: Date,
        sessionEarnings: number,
        collectionCount: number,
        isActive: boolean,
        startTime: Date,
        lastCollectionTime: Date
      }
    ],
    pagination: {
      page: number,
      limit: number,
      total: number,
      totalPages: number
    }
  }
  ```

**GET `/api/users/:userId/earnings/history`**
- Returns paginated individual collection earnings history
- Query params: `page`, `limit`, `startDate`, `endDate`
- Response:
  ```typescript
  {
    earnings: [
      {
        id: string,
        amount: number,
        date: Date,
        dropId: string,
        collectionAttemptId: string,
        dropSnapshot: {
          numberOfBottles: number,
          numberOfCans: number,
          location: { lat, lng }
        }
      }
    ],
    pagination: {
      page: number,
      limit: number,
      total: number,
      totalPages: number
    }
  }
  ```

### 1.3 API Integration Points

**Update existing endpoint:**
- `PATCH /api/dropoffs/:dropoffId/attempts/:attemptId/complete`
  - When `outcome === 'collected'`, calculate and save earnings
  - Update user's total earnings

---

## 2. Frontend Implementation

### 2.1 Data Models

#### Earnings Model (`lib/features/earnings/data/models/earnings.dart`)
```dart
class Earnings {
  final double totalEarnings; // Lifetime total
  final EarningsSession? currentSession; // Today's session
  
  Earnings({
    required this.totalEarnings,
    this.currentSession,
  });
  
  factory Earnings.fromJson(Map<String, dynamic> json) { ... }
}

class EarningsSession {
  final String id;
  final DateTime date;
  final double sessionEarnings; // Total for this session/day
  final int collectionCount;
  final bool isActive;
  final DateTime startTime;
  final DateTime lastCollectionTime;
  
  EarningsSession({ ... });
  
  factory EarningsSession.fromJson(Map<String, dynamic> json) { ... }
}

class EarningsHistoryItem {
  final String id;
  final double amount;
  final DateTime date;
  final String dropId;
  final String collectionAttemptId;
  final DropSnapshot? dropSnapshot;
  
  EarningsHistoryItem({ ... });
  
  factory EarningsHistoryItem.fromJson(Map<String, dynamic> json) { ... }
}
```

### 2.2 API Client

#### Earnings API Client (`lib/features/earnings/data/datasources/earnings_api_client.dart`)
```dart
class EarningsApiClient {
  // Get lifetime total and current session
  Future<Earnings> getUserEarnings(String userId);
  
  // Get paginated earnings sessions (by day)
  Future<EarningsSessionsResponse> getEarningsSessions({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  // Get paginated individual collection earnings
  Future<EarningsHistoryResponse> getEarningsHistory({
    required String userId,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  });
}
```

### 2.3 Providers/Controllers

#### Earnings Provider (`lib/features/earnings/presentation/providers/earnings_provider.dart`)
```dart
// Lifetime total and current session
final earningsProvider = FutureProvider<Earnings>((ref) async {
  final apiClient = ref.watch(earningsApiClientProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.value?.id;
  if (userId == null) throw Exception('User not authenticated');
  return apiClient.getUserEarnings(userId);
});

// Earnings sessions (by day) - for history screen
final earningsSessionsProvider = FutureProvider.family<EarningsSessionsResponse, int>((ref, page) async {
  final apiClient = ref.watch(earningsApiClientProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.value?.id;
  if (userId == null) throw Exception('User not authenticated');
  return apiClient.getEarningsSessions(userId: userId, page: page);
});

// Individual collection earnings - for detailed history
final earningsHistoryProvider = FutureProvider.family<EarningsHistoryResponse, int>((ref, page) async {
  final apiClient = ref.watch(earningsApiClientProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.value?.id;
  if (userId == null) throw Exception('User not authenticated');
  return apiClient.getEarningsHistory(userId: userId, page: page);
});
```

### 2.4 History Screen Updates

#### Filter Chips Section
Add two filter chips in the history screen:
1. **"Collections"** chip (default)
   - Shows collection history (collected, cancelled, expired)
   - Uses existing `collectionAttemptsProvider`
   - Displays individual collection attempts

2. **"Earnings"** chip
   - Shows earnings sessions (grouped by day)
   - Uses new `earningsSessionsProvider`
   - Displays: date, session total earnings, collection count
   - Each session card can expand to show individual collections within that session

#### History Screen Structure (`lib/features/history/presentation/screens/history_screen.dart`)
```dart
enum HistoryFilter { collections, earnings }

class HistoryScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.collections;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(...),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          
          // Content based on selected filter
          Expanded(
            child: _selectedFilter == HistoryFilter.collections
                ? _buildCollectionsHistory()
                : _buildEarningsHistory(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips() {
    return Row(
      children: [
        FilterChip(
          label: Text('Collections'),
          selected: _selectedFilter == HistoryFilter.collections,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = HistoryFilter.collections;
            });
          },
        ),
        SizedBox(width: 8),
        FilterChip(
          label: Text('Earnings'),
          selected: _selectedFilter == HistoryFilter.earnings,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = HistoryFilter.earnings;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildCollectionsHistory() {
    // Existing collection history implementation
  }
  
  Widget _buildEarningsHistory() {
    // New earnings sessions implementation (grouped by day)
    final earningsAsync = ref.watch(earningsSessionsProvider(1));
    
    return earningsAsync.when(
      data: (earningsSessions) => ListView.builder(
        itemCount: earningsSessions.sessions.length,
        itemBuilder: (context, index) {
          final session = earningsSessions.sessions[index];
          return _buildEarningsSessionCard(session);
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
  
  Widget _buildEarningsSessionCard(EarningsSession session) {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.monetization_on, color: Color(0xFF00695C)),
        title: Text('${DropValueCalculator.formatEstimatedValue(session.sessionEarnings)}'),
        subtitle: Text(
          '${_formatDate(session.date)} • ${session.collectionCount} ${session.collectionCount == 1 ? 'collection' : 'collections'}'
        ),
        trailing: session.isActive
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              )
            : null,
        children: [
          // Show individual collections in this session
          // Can fetch detailed earnings history for this date
          Padding(
            padding: EdgeInsets.all(8),
            child: Text('Tap to view individual collections'),
          ),
        ],
      ),
    );
  }
}
```

### 2.5 Earnings Card Design

#### Earnings Session Card Components:
- **Icon**: Money/earnings icon (green color)
- **Session Total**: Formatted as "X.XX TND" (total for that day)
- **Date**: Formatted date of session
- **Collection Count**: Number of collections in that session
- **Active Badge**: Shows "Active" if session is still active (last collection within 3 hours)
- **Expandable**: Tap to expand and see individual collections within that session
- **Details**: Shows individual collection earnings when expanded

#### Session Value Card Updates
- Update `SessionValueCard` to use `earningsProvider` instead of calculating from attempts
- Display `currentSession.sessionEarnings` for "Today's Total"
- This ensures persistence across app restarts

---

## 3. Implementation Steps

### Phase 1: Backend
1. ✅ Update CollectionAttempt schema to include `earnings` field
2. ✅ Update User schema to include `totalEarnings` field
3. ✅ Modify `completeCollectionAttempt` to calculate and save earnings
4. ✅ Create earnings endpoints (GET user earnings, GET earnings history)
5. ✅ (Optional) Create EarningsHistory model for detailed tracking

### Phase 2: Frontend - Data Layer
1. ✅ Create Earnings and EarningsHistoryItem models
2. ✅ Create EarningsApiClient
3. ✅ Create earnings providers

### Phase 3: Frontend - UI Layer
1. ✅ Update HistoryScreen to include filter chips
2. ✅ Implement earnings history list view
3. ✅ Create earnings history card widget
4. ✅ Add localization for earnings-related text
5. ✅ Test filter switching and data loading

### Phase 4: Integration & Testing
1. ✅ Test earnings calculation accuracy
2. ✅ Test earnings persistence
3. ✅ Test earnings history display
4. ✅ Test filter switching performance
5. ✅ Verify earnings update after collection completion

---

## 4. Data Flow

### When Collection is Completed:
```
1. Collector completes collection (outcome: 'collected')
   ↓
2. Backend calculates earnings: (bottles * 0.025) + (cans * 0.06)
   ↓
3. Backend saves earnings to CollectionAttempt
   ↓
4. Backend updates User.totalEarnings (+= earnings) [Lifetime total]
   ↓
5. Backend updates or creates EarningsSession for today
   - If session exists: increment sessionEarnings and collectionCount
   - If new session: create with today's date
   - Update isActive flag and lastCollectionTime
   ↓
6. (Optional) Backend creates EarningsHistory entry
   ↓
7. Frontend refreshes earnings data
   ↓
8. SessionValueCard displays updated session earnings
   ↓
9. Earnings appear in history screen under "Earnings" filter
```

### When App Restarts:
```
1. User opens app
   ↓
2. Frontend calls GET /api/users/:userId/earnings
   ↓
3. Backend returns:
   - totalEarnings (lifetime)
   - currentSession (today's session from DB)
   ↓
4. SessionValueCard displays currentSession.sessionEarnings
   ↓
5. Session data persists across restarts
```

### When Viewing Earnings History:
```
1. User opens History screen
   ↓
2. User taps "Earnings" filter chip
   ↓
3. Frontend calls GET /api/users/:userId/earnings/sessions
   ↓
4. Backend returns paginated earnings sessions (grouped by day)
   ↓
5. Frontend displays earnings session cards in list
   ↓
6. User can expand session card to see individual collections
   ↓
7. Frontend calls GET /api/users/:userId/earnings/history?date=YYYY-MM-DD
   ↓
8. Backend returns individual collection earnings for that date
   ↓
9. Frontend displays detailed collection list
```

---

## 5. Considerations

### 5.1 Edge Cases
- **Cancelled collections**: No earnings (earnings = 0, not added to session)
- **Expired collections**: No earnings (earnings = 0, not added to session)
- **Historical data**: Existing collections won't have earnings (can backfill or leave as 0)
- **Deleted users**: Handle earnings data cleanup
- **Multiple sessions per day**: Only one session per user per day (upsert logic)
- **Session expiration**: Background job updates `isActive` flag (3-hour timeout)
- **App restart during active session**: Session data persists, continues from where it left off
- **Timezone changes**: Use UTC for date calculations to avoid session splitting

### 5.2 Performance
- Use pagination for earnings history
- Cache earnings data appropriately
- Consider lazy loading for earnings history

### 5.3 Localization
- Add keys for:
  - "Earnings"
  - "Total Earnings"
  - "Earnings History"
  - Date formatting

### 5.4 Future Enhancements
- Earnings charts/graphs
- Earnings by date range filtering
- Export earnings history
- Earnings goals/targets
- Earnings breakdown by item type

---

## 6. Files to Create/Modify

### Backend:
- `backend/src/modules/dropoffs/schemas/collection-attempt.schema.ts` (add earnings field)
- `backend/src/modules/users/schemas/user.schema.ts` (add totalEarnings field)
- `backend/src/modules/dropoffs/dropoffs.service.ts` (calculate and save earnings, update session)
- `backend/src/modules/earnings/schemas/earnings-session.schema.ts` (new - required)
- `backend/src/modules/earnings/earnings-session.service.ts` (new - required)
- `backend/src/modules/earnings/earnings.controller.ts` (new)
- `backend/src/modules/earnings/earnings.service.ts` (new)
- `backend/src/modules/earnings/earnings.module.ts` (new)
- `backend/src/modules/earnings/schemas/earnings-history.schema.ts` (optional, new)
- `backend/src/modules/earnings/cron/session-activity-updater.ts` (new - background job)

### Frontend:
- `botleji/lib/features/earnings/data/models/earnings.dart` (new - includes EarningsSession)
- `botleji/lib/features/earnings/data/datasources/earnings_api_client.dart` (new)
- `botleji/lib/features/earnings/presentation/providers/earnings_provider.dart` (new)
- `botleji/lib/features/stats/presentation/widgets/session_value_card.dart` (modify - use earningsProvider)
- `botleji/lib/features/history/presentation/screens/history_screen.dart` (modify - add filter chips)
- `botleji/l10n/app_*.arb` (add earnings localization keys)

---

## 7. Testing Checklist

- [ ] Earnings calculated correctly for collected drops
- [ ] Earnings not added for cancelled/expired collections
- [ ] User lifetime total earnings updates correctly
- [ ] Earnings session created/updated correctly
- [ ] Session earnings accumulate correctly within a day
- [ ] Session data persists after app restart
- [ ] SessionValueCard displays session earnings from backend
- [ ] Earnings sessions display correctly in history
- [ ] Filter chips switch between collections and earnings
- [ ] Pagination works for earnings sessions
- [ ] Earnings display correctly formatted (X.XX TND)
- [ ] Earnings sessions sorted by date (newest first)
- [ ] Active session badge shows correctly
- [ ] Session activity updates correctly (3-hour timeout)
- [ ] Background job updates isActive flag
- [ ] No earnings shown for historical collections (before implementation)

---

This plan provides a comprehensive roadmap for implementing earnings tracking. The system will track earnings per collection, update user totals, and display earnings history in the history screen with filter chips for easy navigation.

